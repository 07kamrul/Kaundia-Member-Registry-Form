"""plot boundary tables (member-drawn polygons, versions, disputes)

Revision ID: c7f1a3e9d4b6
Revises: b5d8f2a6c9e3
Create Date: 2026-10-10

Geometry is stored as RFC 7946 GeoJSON in a JSON column (SQLite dev / Postgres
without PostGIS). If PostGIS is adopted later, add a `geom` generated column
from this JSON in a follow-up migration plus a GiST index.
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c7f1a3e9d4b6"
down_revision: Union[str, Sequence[str], None] = "b5d8f2a6c9e3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "plot_boundaries",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "property_id",
            sa.Integer(),
            sa.ForeignKey("properties.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "member_id",
            sa.Integer(),
            sa.ForeignKey("members.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("geom", sa.JSON(), nullable=False),
        sa.Column("computed_area_sqm", sa.Numeric(14, 2), nullable=True),
        sa.Column("computed_area_shotangsho", sa.Numeric(14, 2), nullable=True),
        sa.Column("status", sa.String(32), nullable=False, server_default="pending_review"),
        sa.Column("review_note", sa.Text(), nullable=True),
        sa.Column("current_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("reviewed_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("reviewed_at", sa.String(32), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_index("ix_plot_boundaries_property_id", "plot_boundaries", ["property_id"])
    op.create_index("ix_plot_boundaries_member_id", "plot_boundaries", ["member_id"])
    op.create_index("ix_plot_boundaries_status", "plot_boundaries", ["status"])
    op.create_index("ix_plot_boundaries_is_deleted", "plot_boundaries", ["is_deleted"])

    op.create_table(
        "plot_boundary_versions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "boundary_id",
            sa.Integer(),
            sa.ForeignKey("plot_boundaries.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("geom", sa.JSON(), nullable=False),
        sa.Column("computed_area_sqm", sa.Numeric(14, 2), nullable=True),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("change_type", sa.String(32), nullable=False),
        sa.Column("changed_by_member_id", sa.Integer(), sa.ForeignKey("members.id", ondelete="SET NULL")),
        sa.Column("changed_by_admin_id", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL")),
        sa.Column("note", sa.Text(), nullable=True),
    )
    op.create_index("ix_plot_boundary_versions_boundary_id", "plot_boundary_versions", ["boundary_id"])
    op.create_index(
        "uq_plot_boundary_versions_boundary_version",
        "plot_boundary_versions",
        ["boundary_id", "version"],
        unique=True,
    )

    op.create_table(
        "boundary_disputes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "boundary_id",
            sa.Integer(),
            sa.ForeignKey("plot_boundaries.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "other_boundary_id",
            sa.Integer(),
            sa.ForeignKey("plot_boundaries.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("overlap_area_sqm", sa.Numeric(14, 2), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("status", sa.String(32), nullable=False, server_default="open"),
        sa.Column("resolved_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL")),
        sa.Column("resolved_at", sa.String(32), nullable=True),
        sa.Column("resolution_note", sa.Text(), nullable=True),
    )
    op.create_index("ix_boundary_disputes_boundary_id", "boundary_disputes", ["boundary_id"])
    op.create_index("ix_boundary_disputes_status", "boundary_disputes", ["status"])


def downgrade() -> None:
    op.drop_table("boundary_disputes")
    op.drop_table("plot_boundary_versions")
    op.drop_table("plot_boundaries")
