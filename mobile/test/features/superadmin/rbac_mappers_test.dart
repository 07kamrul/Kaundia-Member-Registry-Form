import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/superadmin/data/rbac_dtos.dart';
import 'package:kaundia_app/features/superadmin/domain/rbac_entities.dart';

void main() {
  test('PermissionDefDto maps every field from snake_case API JSON', () {
    final dto = PermissionDefDto.fromApi(const {
      'key': 'manage_roles',
      'resource': 'roles',
      'action': 'manage',
      'description': 'Manage roles',
    });
    expect(dto.key, 'manage_roles');
    expect(dto.resource, 'roles');
    expect(dto.action, 'manage');
    expect(dto.description, 'Manage roles');

    final entity = dto.toEntity();
    expect(entity.key, 'manage_roles');
    expect(entity.resource, 'roles');
    expect(entity.action, 'manage');
    expect(entity.description, 'Manage roles');
  });

  test('RoleDefDto maps id to String and permission_keys to permissionKeys', () {
    final dto = RoleDefDto.fromApi(const {
      'id': 3,
      'name': 'administrator',
      'description': 'Administrator role',
      'permission_keys': ['manage_roles', 'view_audit_log'],
    });
    expect(dto.id, 3);
    expect(dto.name, 'administrator');
    expect(dto.description, 'Administrator role');
    expect(dto.permissionKeys, ['manage_roles', 'view_audit_log']);

    final entity = dto.toEntity();
    expect(entity.id, '3');
    expect(entity.name, 'administrator');
    expect(entity.description, 'Administrator role');
    expect(entity.permissionKeys, ['manage_roles', 'view_audit_log']);
    expect(entity.hasPermission('manage_roles'), isTrue);
    expect(entity.hasPermission('manage_users'), isFalse);
    expect(entity.isSuperAdmin, isFalse);
  });

  test('RoleDefDto handles null description and missing permission_keys', () {
    final dto = RoleDefDto.fromApi(const {
      'id': 1,
      'name': 'super_admin',
      'description': null,
    });
    expect(dto.description, isNull);
    expect(dto.permissionKeys, isEmpty);
    expect(dto.toEntity().isSuperAdmin, isTrue);
  });

  test('PermissionOverrideDto round-trips through the API payload shape', () {
    final dto = PermissionOverrideDto.fromApi(const {
      'permission_key': 'manage_users',
      'granted': false,
    });
    expect(dto.permissionKey, 'manage_users');
    expect(dto.granted, isFalse);

    final payload = dto.toDto();
    expect(payload['permission_key'], 'manage_users');
    expect(payload['granted'], isFalse);

    final entity = dto.toEntity();
    expect(entity.permissionKey, 'manage_users');
    expect(entity.granted, isFalse);

    final fromEntity = PermissionOverrideDto.fromEntity(entity);
    expect(fromEntity.permissionKey, 'manage_users');
    expect(fromEntity.granted, isFalse);
  });

  test('AdminUserDto maps id and nullable role_id to String', () {
    final dto = AdminUserDto.fromApi(const {
      'id': 12,
      'name': 'Karim',
      'email': 'karim@example.com',
      'role': 'administrator',
      'role_id': 3,
    });
    expect(dto.id, 12);
    expect(dto.roleId, 3);

    final entity = dto.toEntity();
    expect(entity.id, '12');
    expect(entity.name, 'Karim');
    expect(entity.email, 'karim@example.com');
    expect(entity.role, 'administrator');
    expect(entity.roleId, '3');
  });

  test('AdminUserDto handles null role_id', () {
    final dto = AdminUserDto.fromApi(const {
      'id': 7,
      'name': 'Rahim',
      'email': 'rahim@example.com',
      'role': 'executive_committee',
      'role_id': null,
    });
    expect(dto.roleId, isNull);
    expect(dto.toEntity().roleId, isNull);
  });

  test('AdminRoleNameX maps role strings both ways', () {
    expect(AdminRoleNameX.fromApi('administrator'), AdminRoleName.administrator);
    expect(AdminRoleNameX.fromApi('executive_committee'), AdminRoleName.executiveCommittee);
    expect(AdminRoleNameX.fromApi('super_admin'), AdminRoleName.superAdmin);
    expect(AdminRoleNameX.fromApi('unknown'), AdminRoleName.administrator);
    expect(AdminRoleName.executiveCommittee.apiValue, 'executive_committee');
    expect(AdminRoleName.superAdmin.apiValue, 'super_admin');
  });
}
