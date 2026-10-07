"""password reset tokens for self-service forgot-password flow

Revision ID: c1a2b3d4e5f7
Revises: b8e2c4a6d9f1
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = 'c1a2b3d4e5f7'
down_revision: Union[str, None] = 'b8e2c4a6d9f1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'password_reset_tokens',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('user_type', sa.String(length=10), nullable=False),
        sa.Column('member_id', sa.Integer(), sa.ForeignKey('members.id', ondelete='CASCADE'), nullable=True),
        sa.Column('admin_id', sa.Integer(), sa.ForeignKey('admin_users.id', ondelete='CASCADE'), nullable=True),
        sa.Column('token_hash', sa.String(length=64), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('used_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_password_reset_tokens_token_hash', 'password_reset_tokens', ['token_hash'], unique=True)
    op.create_index('ix_password_reset_tokens_member_id', 'password_reset_tokens', ['member_id'])
    op.create_index('ix_password_reset_tokens_admin_id', 'password_reset_tokens', ['admin_id'])


def downgrade() -> None:
    op.drop_index('ix_password_reset_tokens_admin_id', table_name='password_reset_tokens')
    op.drop_index('ix_password_reset_tokens_member_id', table_name='password_reset_tokens')
    op.drop_index('ix_password_reset_tokens_token_hash', table_name='password_reset_tokens')
    op.drop_table('password_reset_tokens')
