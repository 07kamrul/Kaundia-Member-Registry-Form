"""division and holding number fields

Revision ID: e2f6a8b4c1d3
Revises: d1e5f7a3b9c2
Create Date: 2026-09-16 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e2f6a8b4c1d3'
down_revision: Union[str, None] = 'd1e5f7a3b9c2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('members', sa.Column('permanent_division', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('current_division', sa.String(length=255), nullable=True))
    op.add_column('properties', sa.Column('holding_number', sa.String(length=128), nullable=True))


def downgrade() -> None:
    op.drop_column('properties', 'holding_number')
    op.drop_column('members', 'current_division')
    op.drop_column('members', 'permanent_division')
