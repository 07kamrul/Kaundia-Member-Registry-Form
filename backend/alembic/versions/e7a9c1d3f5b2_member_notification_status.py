"""member notification_status

Records whether the applicant was successfully emailed about a rejection, so
an admin can see failures and resend.

Revision ID: e7a9c1d3f5b2
Revises: d4e6f8a0b2c4
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = 'e7a9c1d3f5b2'
down_revision: Union[str, None] = 'd4e6f8a0b2c4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('members', sa.Column('notification_status', sa.String(length=16), nullable=True))


def downgrade() -> None:
    op.drop_column('members', 'notification_status')
