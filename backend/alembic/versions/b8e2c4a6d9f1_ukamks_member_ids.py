"""renumber member ids to UKAMKS-N format

One-time migration for the KAM-YYYY-NNNN -> UKAMKS-N change:

- creates the single-row member_id_sequence counter (seeded to the highest
  renumbered value, so the next approval gets UKAMKS-N+1),
- renumbers every existing member id to UKAMKS-1..N in original approval
  order (reviewed_at, falling back to created_at, then id),
- rewrites member_credentials usernames (lowercased member id) so login by
  member id keeps working,
- rewrites old ids appearing in audit_logs detail strings,
- records every old->new pair in member_id_migrations for support lookups.

Idempotence: a member whose id already matches ^UKAMKS-\d+$ is left alone.

Revision ID: b8e2c4a6d9f1
Revises: e7a9c1d3f5b2
Create Date: 2026-09-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import re


# revision identifiers, used by Alembic.
revision: str = 'b8e2c4a6d9f1'
down_revision: Union[str, None] = 'e7a9c1d3f5b2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

UKAMKS_PATTERN = re.compile(r"^UKAMKS-\d+$")


def _compute_mapping(rows) -> list[tuple[int, str, str]]:
    """rows: (id, member_id, reviewed_at, created_at) in arbitrary order.
    Returns (member_pk, old_id, new_id) in original approval order
    (reviewed_at, falling back to created_at, then id), numbered 1-based."""
    approved = sorted(
        (r for r in rows if r[1] is not None),
        key=lambda r: (r[2] or r[3], r[0]),
    )
    mapping = []
    n = 0
    for pk, old_id, _reviewed, _created in approved:
        if UKAMKS_PATTERN.match(old_id):
            continue
        n += 1
        mapping.append((pk, old_id, f"UKAMKS-{n}"))
    return mapping


def upgrade() -> None:
    conn = op.get_bind()

    op.create_table(
        "member_id_sequence",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("value", sa.Integer(), nullable=False),
    )
    op.create_table(
        "member_id_migrations",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("member_pk", sa.Integer(), nullable=False),
        sa.Column("old_member_id", sa.String(length=32), nullable=False),
        sa.Column("new_member_id", sa.String(length=32), nullable=False),
        sa.Column("migrated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    rows = conn.execute(
        sa.text("SELECT id, member_id, reviewed_at, created_at FROM members")
    ).fetchall()
    mapping = _compute_mapping(rows)

    already = [r for r in rows if r[1] and UKAMKS_PATTERN.match(r[1])]
    max_new = len(mapping) + len(already)

    for pk, old_id, new_id in mapping:
        conn.execute(
            sa.text("UPDATE members SET member_id = :new WHERE id = :pk"),
            {"new": new_id, "pk": pk},
        )
        # credential usernames are the lowercased member id; only touch the
        # row that still mirrors the old id so custom usernames survive.
        conn.execute(
            sa.text(
                "UPDATE member_credentials SET username = :username "
                "WHERE member_id = :pk AND username = :old_username"
            ),
            {"username": new_id.lower(), "pk": pk, "old_username": old_id.lower()},
        )
        # audit details embed the id (e.g. "approved as KAM-2026-0001")
        conn.execute(
            sa.text(
                "UPDATE audit_logs SET detail = REPLACE(detail, :old, :new) "
                "WHERE detail LIKE :needle"
            ),
            {"old": old_id, "new": new_id, "needle": f"%{old_id}%"},
        )
        conn.execute(
            sa.text(
                "INSERT INTO member_id_migrations (member_pk, old_member_id, new_member_id) "
                "VALUES (:pk, :old, :new)"
            ),
            {"pk": pk, "old": old_id, "new": new_id},
        )
        conn.execute(
            sa.text(
                "INSERT INTO audit_logs (actor_admin_id, action, entity_type, entity_id, detail) "
                "VALUES (NULL, 'member.member_id_migration', 'member', :pk, :detail)"
            ),
            {"pk": str(pk), "detail": f"member id renumbered {old_id} -> {new_id}"},
        )

    conn.execute(
        sa.text("INSERT INTO member_id_sequence (id, value) VALUES (1, :v)"),
        {"v": max_new},
    )


def downgrade() -> None:
    conn = op.get_bind()

    rows = conn.execute(
        sa.text(
            "SELECT m.id, mi.old_member_id FROM members m "
            "JOIN member_id_migrations mi ON mi.member_pk = m.id"
        )
    ).fetchall()
    for pk, old_id in rows:
        current = conn.execute(
            sa.text("SELECT member_id FROM members WHERE id = :pk"), {"pk": pk}
        ).scalar()
        conn.execute(
            sa.text("UPDATE members SET member_id = :old WHERE id = :pk"),
            {"old": old_id, "pk": pk},
        )
        if current:
            conn.execute(
                sa.text(
                    "UPDATE member_credentials SET username = :username "
                    "WHERE member_id = :pk AND username = :current_username"
                ),
                {"username": old_id.lower(), "pk": pk, "current_username": current.lower()},
            )
    conn.execute(sa.text("DELETE FROM audit_logs WHERE action = 'member.member_id_migration'"))
    op.drop_table("member_id_migrations")
    op.drop_table("member_id_sequence")
