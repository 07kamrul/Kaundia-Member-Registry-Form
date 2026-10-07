"""property change requests (member add/edit/delete -> admin review)

Revision ID: a9c3e5f1b7d2
Revises: c1a2b3d4e5f7
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = 'a9c3e5f1b7d2'
down_revision: Union[str, None] = 'c1a2b3d4e5f7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'property_change_requests',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('member_id', sa.Integer(), sa.ForeignKey('members.id', ondelete='CASCADE'), nullable=False),
        sa.Column('property_id', sa.Integer(), sa.ForeignKey('properties.id', ondelete='SET NULL'), nullable=True),
        sa.Column('action', sa.Enum('add', 'edit', 'delete', name='property_change_action'), nullable=False),
        sa.Column('payload', sa.JSON(), nullable=False),
        sa.Column('status', sa.Enum('pending', 'approved', 'cancelled', name='property_change_status'), nullable=False),
        sa.Column('cancel_reason', sa.Text(), nullable=True),
        sa.Column('reviewed_by', sa.Integer(), sa.ForeignKey('admin_users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_property_change_requests_member_id', 'property_change_requests', ['member_id'])
    op.create_index('ix_property_change_requests_property_id', 'property_change_requests', ['property_id'])
    op.create_index('ix_property_change_requests_status', 'property_change_requests', ['status'])


def downgrade() -> None:
    op.drop_index('ix_property_change_requests_status', table_name='property_change_requests')
    op.drop_index('ix_property_change_requests_property_id', table_name='property_change_requests')
    op.drop_index('ix_property_change_requests_member_id', table_name='property_change_requests')
    op.drop_table('property_change_requests')
    sa.Enum(name='property_change_action').drop(op.get_bind(), checkfirst=True)
    sa.Enum(name='property_change_status').drop(op.get_bind(), checkfirst=True)
