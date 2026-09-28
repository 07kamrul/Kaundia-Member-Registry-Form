"""normalize login identifiers to lowercase

Revision ID: b3d4e5f6a7c8
Revises: f9e8d7c6b5a4
Create Date: 2026-09-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b3d4e5f6a7c8'
down_revision: Union[str, None] = 'f9e8d7c6b5a4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    admin_collisions = conn.execute(sa.text(
        "SELECT lower(trim(email)) AS normalized, count(*) "
        "FROM admin_users GROUP BY normalized HAVING count(*) > 1"
    )).fetchall()
    if admin_collisions:
        raise RuntimeError(
            f"admin_users has case-insensitive email collisions, resolve manually before migrating: {admin_collisions}"
        )

    credential_collisions = conn.execute(sa.text(
        "SELECT lower(trim(username)) AS normalized, count(*) "
        "FROM member_credentials GROUP BY normalized HAVING count(*) > 1"
    )).fetchall()
    if credential_collisions:
        raise RuntimeError(
            f"member_credentials has case-insensitive username collisions, resolve manually before migrating: {credential_collisions}"
        )

    conn.execute(sa.text("UPDATE admin_users SET email = lower(trim(email))"))
    conn.execute(sa.text("UPDATE member_credentials SET username = lower(trim(username))"))


def downgrade() -> None:
    pass
