"""online resolution book: meetings, resolutions, meeting_attendance, meeting_recordings + manage_resolution_book permission

Revision ID: e8a4c2f6b1d3
Revises: c8e1f3a5b7d9
Create Date: 2026-10-08 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e8a4c2f6b1d3'
down_revision: Union[str, None] = 'c8e1f3a5b7d9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'meetings',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('meeting_no', sa.String(length=32), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('time', sa.Time(), nullable=True),
        sa.Column('meeting_type', sa.String(length=16), nullable=False, server_default='online'),
        sa.Column('chairperson', sa.String(length=255), nullable=False),
        sa.Column('chairperson_member_id', sa.Integer(), sa.ForeignKey('members.id', ondelete='SET NULL'), nullable=True),
        sa.Column('agenda', sa.Text(), nullable=False),
        sa.Column('summary', sa.Text(), nullable=True),
        sa.Column('next_meeting_date', sa.Date(), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=False, server_default='completed'),
        sa.Column('created_by', sa.Integer(), sa.ForeignKey('admin_users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint('meeting_no', name='uq_meetings_meeting_no'),
    )
    op.create_index('ix_meetings_date', 'meetings', ['date'])
    op.create_index('ix_meetings_status_date', 'meetings', ['status', 'date'])

    op.create_table(
        'resolutions',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('meeting_id', sa.Integer(), sa.ForeignKey('meetings.id', ondelete='CASCADE'), nullable=False),
        sa.Column('resolution_no', sa.Integer(), nullable=False),
        sa.Column('decision', sa.Text(), nullable=False),
        sa.Column('vote_for', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('vote_against', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('vote_neutral', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('assigned_to_member_id', sa.Integer(), sa.ForeignKey('members.id', ondelete='SET NULL'), nullable=True),
        sa.Column('task', sa.Text(), nullable=True),
        sa.Column('due_date', sa.Date(), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=False, server_default='pending'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(
        'ix_resolutions_meeting_no', 'resolutions', ['meeting_id', 'resolution_no'], unique=True
    )
    op.create_index('ix_resolutions_status', 'resolutions', ['status'])

    op.create_table(
        'meeting_attendance',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('meeting_id', sa.Integer(), sa.ForeignKey('meetings.id', ondelete='CASCADE'), nullable=False),
        sa.Column('member_id', sa.Integer(), sa.ForeignKey('members.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(length=16), nullable=False, server_default='absent'),
        sa.Column('recorded_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(
        'ix_meeting_attendance_meeting_member',
        'meeting_attendance',
        ['meeting_id', 'member_id'],
        unique=True,
    )

    op.create_table(
        'meeting_recordings',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('meeting_id', sa.Integer(), sa.ForeignKey('meetings.id', ondelete='CASCADE'), nullable=False),
        sa.Column('file_path', sa.String(length=512), nullable=False),
        sa.Column('original_name', sa.String(length=255), nullable=False),
        sa.Column('file_type', sa.String(length=16), nullable=False),
        sa.Column('file_size', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('uploaded_by', sa.Integer(), sa.ForeignKey('admin_users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('uploaded_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_meeting_recordings_meeting', 'meeting_recordings', ['meeting_id'])


def downgrade() -> None:
    op.drop_index('ix_meeting_recordings_meeting', table_name='meeting_recordings')
    op.drop_table('meeting_recordings')
    op.drop_index('ix_meeting_attendance_meeting_member', table_name='meeting_attendance')
    op.drop_table('meeting_attendance')
    op.drop_index('ix_resolutions_status', table_name='resolutions')
    op.drop_index('ix_resolutions_meeting_no', table_name='resolutions')
    op.drop_table('resolutions')
    op.drop_index('ix_meetings_status_date', table_name='meetings')
    op.drop_index('ix_meetings_date', table_name='meetings')
    op.drop_table('meetings')
