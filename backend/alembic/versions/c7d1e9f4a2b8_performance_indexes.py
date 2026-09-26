"""performance indexes for list ordering and eager-load child lookups

Revision ID: c7d1e9f4a2b8
Revises: f9e8d7c6b5a4
Create Date: 2026-09-26 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c7d1e9f4a2b8'
down_revision: Union[str, None] = 'f9e8d7c6b5a4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (index name, table, columns)
INDEXES = [
    # Admin list endpoints ORDER BY created_at DESC, optionally WHERE status = ?
    ('ix_members_created_at', 'members', ['created_at']),
    ('ix_members_status_created_at', 'members', ['status', 'created_at']),
    # selectinload(Member.properties / .nominees) and every child DELETE/UPDATE
    # filters on these foreign keys; none of them were indexed.
    ('ix_properties_member_id', 'properties', ['member_id']),
    ('ix_nominees_member_id', 'nominees', ['member_id']),
    ('ix_co_owners_property_id', 'co_owners', ['property_id']),
    ('ix_applicable_docs_property_id', 'applicable_docs', ['property_id']),
    # Permission resolution joins/filters on these.
    ('ix_user_permission_overrides_permission_id', 'user_permission_overrides', ['permission_id']),
    ('ix_admin_users_role_id', 'admin_users', ['role_id']),
]


def upgrade() -> None:
    for name, table, columns in INDEXES:
        op.create_index(name, table, columns)


def downgrade() -> None:
    for name, table, _columns in reversed(INDEXES):
        op.drop_index(name, table_name=table)
