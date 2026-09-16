"""member gender field

Revision ID: c9d4e6f2a8b1
Revises: b7c2f5a1d3e9
Create Date: 2026-09-16 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c9d4e6f2a8b1'
down_revision: Union[str, None] = 'b7c2f5a1d3e9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('members', sa.Column('gender', sa.String(length=16), nullable=True))
    op.execute("UPDATE members SET gender = 'পুরুষ' WHERE gender IS NULL")
    op.alter_column('members', 'gender', nullable=False)
    op.drop_column('members', 'whatsapp')


def downgrade() -> None:
    op.add_column('members', sa.Column('whatsapp', sa.String(length=32), nullable=True))
    op.execute("UPDATE members SET whatsapp = mobile WHERE whatsapp IS NULL")
    op.alter_column('members', 'whatsapp', nullable=False)
    op.drop_column('members', 'gender')
