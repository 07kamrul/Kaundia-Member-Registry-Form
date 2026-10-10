"""version-level review workflow for plot boundaries

Revision ID: a8c3f5d7b2e9
Revises: d9a4b7c2e1f8
Create Date: 2026-10-10

Moves review state from the boundary row to the version row:

- plot_boundary_versions gains `review_status` (pending/approved/rejected/
  superseded/withdrawn), `submitted_by_role`, `reviewed_by_admin_id`,
  `reviewed_at` and `review_note`; existing rows are backfilled from the old
  boundary-style `status` column.
- plot_boundaries gains `live_version_id` (approved shape everyone sees),
  `pending_version_id` (at most one submission awaiting review) and the soft
  delete attribution columns (`deleted_by_admin_id`, `deleted_reason`,
  `deleted_at`); pointers are backfilled from existing version rows.

The boundary-level `status` column is kept as a derived mirror so older
readers keep working; new code treats the version rows as authoritative.
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a8c3f5d7b2e9"
down_revision: Union[str, Sequence[str], None] = "d9a4b7c2e1f8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("plot_boundary_versions") as batch:
        batch.add_column(
            sa.Column("review_status", sa.String(32), nullable=False, server_default="pending")
        )
        batch.add_column(
            sa.Column("submitted_by_role", sa.String(16), nullable=False, server_default="member")
        )
        batch.add_column(
            sa.Column("reviewed_by_admin_id", sa.Integer(), nullable=True)
        )
        batch.create_foreign_key(
            "fk_pbv_reviewed_by_admin", "admin_users", ["reviewed_by_admin_id"], ["id"], ondelete="SET NULL"
        )
        batch.add_column(sa.Column("reviewed_at", sa.String(32), nullable=True))
        batch.add_column(sa.Column("review_note", sa.Text(), nullable=True))
        batch.create_index("ix_plot_boundary_versions_review_status", ["review_status"])

    # Backfill review_status from the legacy status column.
    op.execute(
        """
        UPDATE plot_boundary_versions SET review_status = CASE status
            WHEN 'approved' THEN 'approved'
            WHEN 'rejected' THEN 'rejected'
            ELSE 'pending'
        END
        """
    )
    # Decision rows (approve/reject/delete) were performed by an admin.
    op.execute(
        """
        UPDATE plot_boundary_versions SET submitted_by_role = 'admin'
        WHERE changed_by_admin_id IS NOT NULL AND changed_by_member_id IS NULL
        """
    )

    with op.batch_alter_table("plot_boundaries") as batch:
        batch.add_column(sa.Column("live_version_id", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("pending_version_id", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("deleted_by_admin_id", sa.Integer(), nullable=True))
        batch.create_foreign_key(
            "fk_pb_live_version", "plot_boundary_versions", ["live_version_id"], ["id"], ondelete="SET NULL"
        )
        batch.create_foreign_key(
            "fk_pb_pending_version", "plot_boundary_versions", ["pending_version_id"], ["id"], ondelete="SET NULL"
        )
        batch.create_foreign_key(
            "fk_pb_deleted_by_admin", "admin_users", ["deleted_by_admin_id"], ["id"], ondelete="SET NULL"
        )
        batch.add_column(sa.Column("deleted_reason", sa.Text(), nullable=True))
        batch.add_column(sa.Column("deleted_at", sa.String(32), nullable=True))

    # Backfill the pointers: the newest approved version is live, the newest
    # still-pending version is the pending one.
    op.execute(
        """
        UPDATE plot_boundaries SET live_version_id = (
            SELECT v.id FROM plot_boundary_versions v
            WHERE v.boundary_id = plot_boundaries.id AND v.review_status = 'approved'
            ORDER BY v.version DESC LIMIT 1
        )
        """
    )
    op.execute(
        """
        UPDATE plot_boundaries SET pending_version_id = (
            SELECT v.id FROM plot_boundary_versions v
            WHERE v.boundary_id = plot_boundaries.id AND v.review_status = 'pending'
            ORDER BY v.version DESC LIMIT 1
        )
        """
    )
    # Mirror column now carries the effective review status.
    op.execute(
        """
        UPDATE plot_boundaries SET status = CASE
            WHEN is_deleted = 1 THEN 'rejected'
            WHEN pending_version_id IS NOT NULL THEN 'pending'
            WHEN live_version_id IS NOT NULL THEN 'approved'
            ELSE 'rejected'
        END
        """
    )


def downgrade() -> None:
    with op.batch_alter_table("plot_boundaries") as batch:
        batch.drop_column("deleted_at")
        batch.drop_column("deleted_reason")
        batch.drop_column("deleted_by_admin_id")
        batch.drop_column("pending_version_id")
        batch.drop_column("live_version_id")
    with op.batch_alter_table("plot_boundary_versions") as batch:
        batch.drop_index("ix_plot_boundary_versions_review_status")
        batch.drop_column("review_note")
        batch.drop_column("reviewed_at")
        batch.drop_column("reviewed_by_admin_id")
        batch.drop_column("submitted_by_role")
        batch.drop_column("review_status")
