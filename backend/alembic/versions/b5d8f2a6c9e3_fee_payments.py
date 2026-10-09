"""fee_payments table for the unified member Fees page

Revision ID: b5d8f2a6c9e3
Revises: c3e5a7b9d1f2
Create Date: 2026-10-10 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b5d8f2a6c9e3'
down_revision: Union[str, Sequence[str], None] = 'c3e5a7b9d1f2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "fee_payments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("member_id", sa.Integer(), sa.ForeignKey("members.id", ondelete="CASCADE"), nullable=False),
        sa.Column("fee_type", sa.String(length=32), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("payment_date", sa.Date(), nullable=False),
        sa.Column("receipt_no", sa.String(length=64), nullable=True),
        sa.Column("payment_method", sa.String(length=64), nullable=True),
        sa.Column("note", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_fee_payments_member_id", "fee_payments", ["member_id"])
    op.create_index("ix_fee_payments_fee_type", "fee_payments", ["fee_type"])
    op.create_index("ix_fee_payments_payment_date", "fee_payments", ["payment_date"])


def downgrade() -> None:
    op.drop_index("ix_fee_payments_payment_date", table_name="fee_payments")
    op.drop_index("ix_fee_payments_fee_type", table_name="fee_payments")
    op.drop_index("ix_fee_payments_member_id", table_name="fee_payments")
    op.drop_table("fee_payments")
