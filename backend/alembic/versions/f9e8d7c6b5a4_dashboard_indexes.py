"""dashboard indexes

Revision ID: f9e8d7c6b5a4
Revises: a1b2c3d4e5f6
Create Date: 2026-09-25 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f9e8d7c6b5a4'
down_revision: Union[str, None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index('ix_members_status', 'members', ['status'])
    op.create_index('ix_installments_member_id', 'installments', ['member_id'])
    op.create_index('ix_installments_status', 'installments', ['status'])


def downgrade() -> None:
    op.drop_index('ix_installments_status', table_name='installments')
    op.drop_index('ix_installments_member_id', table_name='installments')
    op.drop_index('ix_members_status', table_name='members')
