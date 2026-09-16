"""add admin role

Revision ID: f3a9b2c6d8e1
Revises: e2f6a8b4c1d3
Create Date: 2026-09-16 23:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f3a9b2c6d8e1'
down_revision: Union[str, None] = 'e2f6a8b4c1d3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    admin_role = sa.Enum('super_admin', 'executive_committee', 'administrator', name='admin_role')
    admin_role.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'admin_users',
        sa.Column(
            'role',
            admin_role,
            nullable=False,
            server_default='administrator',
        ),
    )


def downgrade() -> None:
    op.drop_column('admin_users', 'role')
    sa.Enum(name='admin_role').drop(op.get_bind(), checkfirst=True)
