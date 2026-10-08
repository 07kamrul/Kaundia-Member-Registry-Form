"""add joint_owner_count to properties

Revision ID: f2a4b6c8d0e2
Revises: a1f2c3d4e5b6
Create Date: 2026-10-08
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f2a4b6c8d0e2"
down_revision: Union[str, Sequence[str], None] = "a1f2c3d4e5b6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "properties",
        sa.Column("joint_owner_count", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("properties", "joint_owner_count")
