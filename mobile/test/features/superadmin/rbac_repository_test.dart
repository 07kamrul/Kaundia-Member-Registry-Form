import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/features/superadmin/data/rbac_repository.dart';
import 'package:kaundia_app/features/superadmin/domain/rbac_entities.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient client;
  late RbacRepository repo;

  setUp(() {
    client = _MockApiClient();
    repo = RbacRepository(client);
  });

  test('listPermissions GETs /admin/rbac/permissions and maps rows', () async {
    when(() => client.getUri('/admin/rbac/permissions')).thenAnswer((_) async => [
          {
            'key': 'manage_roles',
            'resource': 'roles',
            'action': 'manage',
            'description': 'Manage roles',
          },
        ]);
    final result = await repo.listPermissions();
    expect(result, hasLength(1));
    expect(result.first.key, 'manage_roles');
    expect(result.first.resource, 'roles');
    verify(() => client.getUri('/admin/rbac/permissions')).called(1);
  });

  test('listRoles GETs /admin/rbac/roles and maps ids to String', () async {
    when(() => client.getUri('/admin/rbac/roles')).thenAnswer((_) async => [
          {
            'id': 2,
            'name': 'administrator',
            'description': null,
            'permission_keys': ['view_audit_log'],
          },
        ]);
    final result = await repo.listRoles();
    expect(result.single.id, '2');
    expect(result.single.permissionKeys, ['view_audit_log']);
  });

  test('updateRolePermissions PUTs snake_case permission_keys payload', () async {
    when(() => client.put('/admin/rbac/roles/2/permissions', any(that: equals({
          'permission_keys': ['a', 'b'],
        })))).thenAnswer((_) async => {
          'id': 2,
          'name': 'administrator',
          'description': null,
          'permission_keys': ['a', 'b'],
        });
    final updated = await repo.updateRolePermissions('2', ['a', 'b']);
    expect(updated.id, '2');
    expect(updated.permissionKeys, ['a', 'b']);
  });

  test('listUsers GETs /admin/rbac/users', () async {
    when(() => client.getUri('/admin/rbac/users')).thenAnswer((_) async => [
          {
            'id': 5,
            'name': 'Karim',
            'email': 'karim@example.com',
            'role': 'administrator',
            'role_id': 2,
          },
        ]);
    final result = await repo.listUsers();
    expect(result.single.id, '5');
    expect(result.single.roleId, '2');
  });

  test('listUserOverrides GETs the per-user path', () async {
    when(() => client.getUri('/admin/rbac/users/7/overrides'))
        .thenAnswer((_) async => [
              {'permission_key': 'manage_users', 'granted': true},
            ]);
    final result = await repo.listUserOverrides('7');
    expect(result.single.permissionKey, 'manage_users');
    expect(result.single.granted, isTrue);
  });

  test('setUserOverrides PUTs the snake_case override list', () async {
    when(() => client.put('/admin/rbac/users/7/overrides', any(that: equals([
          {
            'permission_key': 'manage_users',
            'granted': false,
          },
        ])))).thenAnswer((_) async => [
              {'permission_key': 'manage_users', 'granted': false},
            ]);
    final result = await repo.setUserOverrides(
      '7',
      const [PermissionOverride(permissionKey: 'manage_users', granted: false)],
    );
    expect(result.single.granted, isFalse);
  });

  test('createUser POSTs snake_case body with null role_id', () async {
    when(() => client.post('/admin/rbac/users', any(that: equals({
          'name': 'New Admin',
          'email': 'new@example.com',
          'password': 'secret',
          'role': 'administrator',
          'role_id': null,
        })))).thenAnswer((_) async => {
          'id': 9,
          'name': 'New Admin',
          'email': 'new@example.com',
          'role': 'administrator',
          'role_id': null,
        });
    final user = await repo.createUser(
      name: 'New Admin',
      email: 'new@example.com',
      password: 'secret',
      role: AdminRoleName.administrator,
    );
    expect(user.id, '9');
    expect(user.roleId, isNull);
  });

  test('updateUserRole PATCHes role and numeric role_id', () async {
    when(() => client.patch('/admin/rbac/users/7/role', any(that: equals({
          'role': 'super_admin',
          'role_id': null,
        })))).thenAnswer((_) async => {
          'id': 7,
          'name': 'Karim',
          'email': 'karim@example.com',
          'role': 'super_admin',
          'role_id': null,
        });
    final user = await repo.updateUserRole('7', 'super_admin', null);
    expect(user.role, 'super_admin');
  });
}
