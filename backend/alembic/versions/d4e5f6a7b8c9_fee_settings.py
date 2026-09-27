"""versioned fee_settings table with date-ranged history

Revision ID: d4e5f6a7b8c9
Revises: c7d1e9f4a2b8
Create Date: 2026-09-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4e5f6a7b8c9'
down_revision: Union[str, None] = 'c7d1e9f4a2b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "fee_settings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("key", sa.String(length=64), nullable=False),
        sa.Column("value", sa.Numeric(12, 2), nullable=False),
        sa.Column("unit", sa.String(length=32), nullable=True),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("status", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column(
            "created_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_fee_settings_key", "fee_settings", ["key"])
    op.create_index("ix_fee_settings_status", "fee_settings", ["status"])
    # At most one active (status = 1) row per key at any time.
    op.create_index(
        "ux_fee_settings_active_key",
        "fee_settings",
        ["key"],
        unique=True,
        postgresql_where=sa.text("status = 1"),
        sqlite_where=sa.text("status = 1"),
    )


def downgrade() -> None:
    op.drop_index("ux_fee_settings_active_key", table_name="fee_settings")
    op.drop_index("ix_fee_settings_status", table_name="fee_settings")
    op.drop_index("ix_fee_settings_key", table_name="fee_settings")
    op.drop_table("fee_settings")
