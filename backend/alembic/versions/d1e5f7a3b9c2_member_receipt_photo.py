"""member receipt photo

Revision ID: d1e5f7a3b9c2
Revises: c9d4e6f2a8b1
Create Date: 2026-09-16 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd1e5f7a3b9c2'
down_revision: Union[str, None] = 'c9d4e6f2a8b1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('members', sa.Column('receipt_photo_path', sa.String(length=512), nullable=True))


def downgrade() -> None:
    op.drop_column('members', 'receipt_photo_path')
