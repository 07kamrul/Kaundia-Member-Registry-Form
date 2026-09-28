"""normalize member identifiers and add partial unique indexes for dedupe

Revision ID: d4e6f8a0b2c4
Revises: b2c4d6e8f0a1
Create Date: 2026-09-29 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4e6f8a0b2c4'
down_revision: Union[str, None] = 'b2c4d6e8f0a1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# One partial unique index per identifier, scoped to applications that still
# block a resubmission (see _BLOCKING_STATUSES in
# app/api/routes/submissions.py). A REJECTED row is excluded so a rejected
# applicant can re-apply with the same nid/mobile/email.
_INDEXES = [
    ("ix_members_nid_active", "nid"),
    ("ix_members_mobile_active", "mobile"),
    ("ix_members_email_active", "email"),
]


def upgrade() -> None:
    conn = op.get_bind()

    # Normalize stored values the same way app/services/normalization.py
    # does, so the columns match what the duplicate-check query compares
    # against going forward.
    conn.execute(sa.text(r"UPDATE members SET nid = regexp_replace(nid, '\D', '', 'g')"))
    conn.execute(sa.text(r"UPDATE members SET mobile = regexp_replace(mobile, '\D', '', 'g')"))
    conn.execute(sa.text("UPDATE members SET email = lower(trim(email))"))

    for _name, column in _INDEXES:
        collisions = conn.execute(sa.text(
            f"SELECT {column}, count(*) FROM members "
            f"WHERE status <> 'rejected' GROUP BY {column} HAVING count(*) > 1"
        )).fetchall()
        if collisions:
            raise RuntimeError(
                f"members has non-rejected {column} collisions, resolve manually before migrating: {collisions}"
            )

    for name, column in _INDEXES:
        op.create_index(
            name,
            "members",
            [column],
            unique=True,
            postgresql_where=sa.text("status <> 'rejected'"),
        )


def downgrade() -> None:
    for name, _column in reversed(_INDEXES):
        op.drop_index(name, table_name="members")
