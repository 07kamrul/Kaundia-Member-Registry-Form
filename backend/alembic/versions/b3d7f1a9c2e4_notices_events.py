"""notices and events tables for the published bulletin/event programme

Revision ID: b3d7f1a9c2e4
Revises: f6a7b8c9d0e1
Create Date: 2026-09-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b3d7f1a9c2e4'
down_revision: Union[str, None] = 'f6a7b8c9d0e1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "notices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("config_list_items.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_members_only", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("publish_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_by",
            sa.Integer(),
            sa.ForeignKey("admin_users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_notices_category_id", "notices", ["category_id"])
    op.create_index("ix_notices_created_by", "notices", ["created_by"])
    op.create_index(
        "ix_notices_is_published_publish_at", "notices", ["is_published", "publish_at"]
    )

    op.create_table(
        "events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", sa.String(length=255), nullable=True),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("config_list_items.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_members_only", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column(
            "created_by",
            sa.Integer(),
            sa.ForeignKey("admin_users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_events_category_id", "events", ["category_id"])
    op.create_index("ix_events_created_by", "events", ["created_by"])
    op.create_index("ix_events_is_published_start_at", "events", ["is_published", "start_at"])


def downgrade() -> None:
    op.drop_index("ix_events_is_published_start_at", table_name="events")
    op.drop_index("ix_events_created_by", table_name="events")
    op.drop_index("ix_events_category_id", table_name="events")
    op.drop_table("events")
    op.drop_index("ix_notices_is_published_publish_at", table_name="notices")
    op.drop_index("ix_notices_created_by", table_name="notices")
    op.drop_index("ix_notices_category_id", table_name="notices")
    op.drop_table("notices")
