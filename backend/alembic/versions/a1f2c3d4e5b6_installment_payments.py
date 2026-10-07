"""member self-service installment payments (submit -> committee verifies)

Revision ID: a1f2c3d4e5b6
Revises: e8a4c2f6b1d3
Create Date: 2026-10-08 13:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1f2c3d4e5b6'
down_revision: Union[str, None] = 'e8a4c2f6b1d3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'installment_payments',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('member_id', sa.Integer(), sa.ForeignKey('members.id', ondelete='CASCADE'), nullable=False),
        sa.Column('method', sa.String(length=64), nullable=False),
        sa.Column('transaction_ref', sa.String(length=64), nullable=False),
        sa.Column('sender_account', sa.String(length=64), nullable=True),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('paid_on', sa.Date(), nullable=False),
        sa.Column('proof_url', sa.String(length=512), nullable=True),
        sa.Column('note', sa.String(length=500), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=False, server_default='pending'),
        sa.Column('rejection_reason', sa.String(length=500), nullable=True),
        sa.Column('reviewed_by', sa.Integer(), sa.ForeignKey('admin_users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_installment_payments_member_id', 'installment_payments', ['member_id'])
    op.create_index(
        'uq_installment_payments_method_ref', 'installment_payments', ['method', 'transaction_ref'], unique=True
    )
    op.create_index('ix_installment_payments_status_created', 'installment_payments', ['status', 'created_at'])

    op.create_table(
        'installment_payment_items',
        sa.Column(
            'payment_id', sa.Integer(), sa.ForeignKey('installment_payments.id', ondelete='CASCADE'), primary_key=True
        ),
        sa.Column(
            'installment_id', sa.Integer(), sa.ForeignKey('installments.id', ondelete='CASCADE'), primary_key=True
        ),
    )
    op.create_index(
        'ix_installment_payment_items_installment_id', 'installment_payment_items', ['installment_id']
    )


def downgrade() -> None:
    op.drop_index('ix_installment_payment_items_installment_id', table_name='installment_payment_items')
    op.drop_table('installment_payment_items')
    op.drop_index('ix_installment_payments_status_created', table_name='installment_payments')
    op.drop_index('uq_installment_payments_method_ref', table_name='installment_payments')
    op.drop_index('ix_installment_payments_member_id', table_name='installment_payments')
    op.drop_table('installment_payments')
