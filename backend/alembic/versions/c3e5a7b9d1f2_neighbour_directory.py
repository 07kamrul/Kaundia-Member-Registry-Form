"""neighbour directory: members.show_in_neighbour_directory + neighbour.view permission

Revision ID: c3e5a7b9d1f2
Revises: f2a4b6c8d0e2
Create Date: 2026-10-09
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c3e5a7b9d1f2"
down_revision: Union[str, Sequence[str], None] = "f2a4b6c8d0e2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

PERMISSION_KEY = "neighbour.view"

permissions_table = sa.table(
    "permissions",
    sa.column("id", sa.Integer),
    sa.column("key", sa.String),
    sa.column("resource", sa.String),
    sa.column("action", sa.String),
    sa.column("description", sa.String),
)

role_permissions_table = sa.table(
    "role_permissions", sa.column("role_id", sa.Integer), sa.column("permission_id", sa.Integer)
)

roles_table = sa.table("roles", sa.column("id", sa.Integer), sa.column("name", sa.String))


def upgrade() -> None:
    # Existing members default to visible, as the directory is opt-out.
    op.add_column(
        "members",
        sa.Column(
            "show_in_neighbour_directory", sa.Boolean(), nullable=False, server_default=sa.true()
        ),
    )

    conn = op.get_bind()
    perm_id = conn.execute(
        permissions_table.insert()
        .values(
            key=PERMISSION_KEY,
            resource="neighbour",
            action="view",
            description="View owners of own and nearest neighbouring plots",
        )
        .returning(permissions_table.c.id)
    ).scalar_one()
    role_ids = conn.execute(
        sa.select(roles_table.c.id).where(roles_table.c.name.in_(["super_admin", "member"]))
    ).scalars().all()
    if role_ids:
        conn.execute(
            role_permissions_table.insert(),
            [{"role_id": rid, "permission_id": perm_id} for rid in role_ids],
        )


def downgrade() -> None:
    conn = op.get_bind()
    perm_id = conn.execute(
        sa.select(permissions_table.c.id).where(permissions_table.c.key == PERMISSION_KEY)
    ).scalar_one_or_none()
    if perm_id is not None:
        conn.execute(role_permissions_table.delete().where(role_permissions_table.c.permission_id == perm_id))
        conn.execute(permissions_table.delete().where(permissions_table.c.id == perm_id))
    op.drop_column("members", "show_in_neighbour_directory")
