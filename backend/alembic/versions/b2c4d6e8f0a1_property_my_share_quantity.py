"""property my_share_quantity field

Revision ID: b2c4d6e8f0a1
Revises: a5c8e1f3b7d2
Create Date: 2026-09-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b2c4d6e8f0a1'
down_revision: Union[str, None] = 'a5c8e1f3b7d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('properties', sa.Column('my_share_quantity', sa.String(length=128), nullable=True))


def downgrade() -> None:
    op.drop_column('properties', 'my_share_quantity')
