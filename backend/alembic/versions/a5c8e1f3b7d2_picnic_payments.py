"""picnic_payments table storing the fee breakdown snapshot per payment

Revision ID: a5c8e1f3b7d2
Revises: b3d7f1a9c2e4
Create Date: 2026-09-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a5c8e1f3b7d2'
# Merges the two pre-existing heads (notices/events chain and the
# normalize_login_identifiers branch) so the migration history is linear again.
down_revision: Union[str, Sequence[str], None] = ('b3d7f1a9c2e4', 'b3d4e5f6a7c8')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "picnic_payments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("member_id", sa.Integer(), sa.ForeignKey("members.id", ondelete="CASCADE"), nullable=False),
        sa.Column("head_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("additional_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("additional_count", sa.Integer(), nullable=False),
        sa.Column("total", sa.Numeric(12, 2), nullable=False),
        sa.Column("additional_heads", sa.JSON(), nullable=True),
        sa.Column("payment_date", sa.Date(), nullable=False),
        sa.Column("receipt_no", sa.String(length=64), nullable=True),
        sa.Column("payment_method", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_picnic_payments_member_id", "picnic_payments", ["member_id"])


def downgrade() -> None:
    op.drop_index("ix_picnic_payments_member_id", table_name="picnic_payments")
    op.drop_table("picnic_payments")
