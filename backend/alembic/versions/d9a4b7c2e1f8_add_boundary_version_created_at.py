"""add created_at to plot_boundary_versions

Revision ID: d9a4b7c2e1f8
Revises: c7f1a3e9d4b6
Create Date: 2026-10-10

The original plot boundary migration (c7f1a3e9d4b6) shipped without the
`created_at` column that the PlotBoundaryVersion model declares, causing
INSERTs to fail with "column plot_boundary_versions.created_at does not
exist" on databases that had already applied it.
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d9a4b7c2e1f8"
down_revision: Union[str, Sequence[str], None] = "c7f1a3e9d4b6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "plot_boundary_versions",
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("plot_boundary_versions", "created_at")
