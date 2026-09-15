"""structured address fields

Revision ID: b7c2f5a1d3e9
Revises: a4146a81884f
Create Date: 2026-09-15 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b7c2f5a1d3e9'
down_revision: Union[str, None] = 'a4146a81884f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('members', sa.Column('permanent_house', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('permanent_road', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('permanent_post_office', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('permanent_upazila', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('permanent_district', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('current_house', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('current_road', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('current_post_office', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('current_upazila', sa.String(length=255), nullable=True))
    op.add_column('members', sa.Column('current_district', sa.String(length=255), nullable=True))
    op.drop_column('members', 'permanent_address')
    op.drop_column('members', 'current_address')


def downgrade() -> None:
    op.add_column('members', sa.Column('permanent_address', sa.Text(), nullable=True))
    op.add_column('members', sa.Column('current_address', sa.Text(), nullable=True))
    op.drop_column('members', 'current_district')
    op.drop_column('members', 'current_upazila')
    op.drop_column('members', 'current_post_office')
    op.drop_column('members', 'current_road')
    op.drop_column('members', 'current_house')
    op.drop_column('members', 'permanent_district')
    op.drop_column('members', 'permanent_upazila')
    op.drop_column('members', 'permanent_post_office')
    op.drop_column('members', 'permanent_road')
    op.drop_column('members', 'permanent_house')
