"""rbac roles permissions

Revision ID: a1b2c3d4e5f6
Revises: f3a9b2c6d8e1
Create Date: 2026-09-17 01:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'f3a9b2c6d8e1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


ROLE_DEFAULT_PERMISSIONS = {
    'super_admin': None,  # filled with every permission key at runtime
    'executive_committee': (
        'member.view_all', 'member.manage', 'property.view_all', 'property.review',
        'membership.review', 'approve_membership', 'complaint.view_all', 'complaint.review',
        'manage_notices', 'report.view',
    ),
    'administrator': (
        'member.register', 'member.verify', 'member.manage', 'document.verify',
        'manage_notices', 'complaint.view_assigned', 'complaint.process', 'report.view_operational',
    ),
    'member': (
        'profile.view_own', 'profile.edit_own', 'property.view_own', 'property.edit_own',
        'membership.view_own_status', 'notice.view', 'event.view', 'complaint.create', 'request.create',
    ),
}

# (key, resource, action, description)
PERMISSIONS = [
    ('manage_users', 'user', 'manage', 'Create/update/deactivate users, assign roles'),
    ('manage_roles', 'role', 'manage', 'Manage roles and role permission assignments'),
    ('manage_system_config', 'system', 'manage', 'Manage system configuration'),
    ('manage_organization', 'organization', 'manage', 'Manage organization settings'),
    ('view_audit_log', 'audit', 'view', 'View audit/access logs'),
    ('member.view_all', 'member', 'view_all', 'View all members'),
    ('member.manage', 'member', 'manage', 'Manage member records'),
    ('member.register', 'member', 'register', 'Register new members'),
    ('member.verify', 'member', 'verify', 'Verify member registration/profile'),
    ('property.view_all', 'property', 'view_all', 'View all properties'),
    ('property.review', 'property', 'review', 'Review property submissions'),
    ('property.view_own', 'property', 'view_own', 'View own property'),
    ('property.edit_own', 'property', 'edit_own', 'Edit own property'),
    ('document.verify', 'document', 'verify', 'Verify uploaded documents'),
    ('membership.review', 'membership', 'review', 'Review membership submissions'),
    ('approve_membership', 'membership', 'approve', 'Approve membership applications'),
    ('membership.view_own_status', 'membership', 'view_own_status', 'View own membership status'),
    ('complaint.view_all', 'complaint', 'view_all', 'View all complaints'),
    ('complaint.review', 'complaint', 'review', 'Review complaints (committee level)'),
    ('complaint.view_assigned', 'complaint', 'view_assigned', 'View assigned complaints'),
    ('complaint.process', 'complaint', 'process', 'Process assigned complaints'),
    ('complaint.create', 'complaint', 'create', 'Create a complaint'),
    ('request.create', 'request', 'create', 'Create a request'),
    ('manage_notices', 'notice', 'manage', 'Manage notices and events'),
    ('notice.view', 'notice', 'view', 'View notices'),
    ('event.view', 'event', 'view', 'View events'),
    ('report.view', 'report', 'view', 'View committee-level reports'),
    ('report.view_operational', 'report', 'view_operational', 'View operational reports'),
    ('profile.view_own', 'profile', 'view_own', 'View own profile'),
    ('profile.edit_own', 'profile', 'edit_own', 'Edit own profile'),
]

ROLES = [
    ('super_admin', 'Super Admin - full system access'),
    ('executive_committee', 'Executive Committee - membership/property/complaint approvals'),
    ('administrator', 'Administrator - operational registration and document handling'),
    ('member', 'Member - self-service access to own records'),
]


def upgrade() -> None:
    bind = op.get_bind()

    op.create_table(
        'roles',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('name', sa.String(length=64), nullable=False, unique=True),
        sa.Column('description', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_roles_name', 'roles', ['name'])

    op.create_table(
        'permissions',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('key', sa.String(length=128), nullable=False, unique=True),
        sa.Column('resource', sa.String(length=64), nullable=False),
        sa.Column('action', sa.String(length=64), nullable=False),
        sa.Column('description', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_permissions_key', 'permissions', ['key'])

    op.create_table(
        'role_permissions',
        sa.Column('role_id', sa.Integer(), sa.ForeignKey('roles.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('permission_id', sa.Integer(), sa.ForeignKey('permissions.id', ondelete='CASCADE'), primary_key=True),
    )

    op.create_table(
        'user_permission_overrides',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('admin_users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('permission_id', sa.Integer(), sa.ForeignKey('permissions.id', ondelete='CASCADE'), nullable=False),
        sa.Column('granted', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('user_id', 'permission_id', name='uq_user_permission'),
    )
    op.create_index('ix_user_permission_overrides_user_id', 'user_permission_overrides', ['user_id'])

    op.add_column('admin_users', sa.Column('role_id', sa.Integer(), sa.ForeignKey('roles.id', ondelete='SET NULL'), nullable=True))

    roles_table = sa.table(
        'roles', sa.column('id', sa.Integer), sa.column('name', sa.String), sa.column('description', sa.String)
    )
    permissions_table = sa.table(
        'permissions',
        sa.column('id', sa.Integer),
        sa.column('key', sa.String),
        sa.column('resource', sa.String),
        sa.column('action', sa.String),
        sa.column('description', sa.String),
    )
    role_permissions_table = sa.table(
        'role_permissions', sa.column('role_id', sa.Integer), sa.column('permission_id', sa.Integer)
    )

    role_name_to_id: dict[str, int] = {}
    for name, description in ROLES:
        result = bind.execute(
            roles_table.insert().values(name=name, description=description).returning(roles_table.c.id)
        )
        role_name_to_id[name] = result.scalar_one()

    key_to_permission_id: dict[str, int] = {}
    for key, resource, action, description in PERMISSIONS:
        result = bind.execute(
            permissions_table.insert()
            .values(key=key, resource=resource, action=action, description=description)
            .returning(permissions_table.c.id)
        )
        key_to_permission_id[key] = result.scalar_one()

    all_permission_keys = [p[0] for p in PERMISSIONS]
    for role_name, permission_keys in ROLE_DEFAULT_PERMISSIONS.items():
        keys = all_permission_keys if permission_keys is None else permission_keys
        role_id = role_name_to_id[role_name]
        for key in keys:
            bind.execute(
                role_permissions_table.insert().values(
                    role_id=role_id, permission_id=key_to_permission_id[key]
                )
            )

    admin_role_map = {
        'super_admin': 'super_admin',
        'executive_committee': 'executive_committee',
        'administrator': 'administrator',
    }
    for admin_role_value, role_name in admin_role_map.items():
        bind.execute(
            sa.text('UPDATE admin_users SET role_id = :role_id WHERE role = :role_value'),
            {'role_id': role_name_to_id[role_name], 'role_value': admin_role_value},
        )


def downgrade() -> None:
    op.drop_column('admin_users', 'role_id')
    op.drop_index('ix_user_permission_overrides_user_id', table_name='user_permission_overrides')
    op.drop_table('user_permission_overrides')
    op.drop_table('role_permissions')
    op.drop_index('ix_permissions_key', table_name='permissions')
    op.drop_table('permissions')
    op.drop_index('ix_roles_name', table_name='roles')
    op.drop_table('roles')
