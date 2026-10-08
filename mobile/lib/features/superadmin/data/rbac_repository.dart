import '../../../core/network/api_client.dart';
import '../domain/rbac_entities.dart';
import 'rbac_dtos.dart';

/// Ported 1:1 from the Angular RbacService — same paths, same payload shapes.
class RbacRepository {
  RbacRepository(this._client);

  final ApiClient _client;

  static const _base = '/admin/rbac';

  Future<List<PermissionDef>> listPermissions() async {
    final rows = await _client.getUri('$_base/permissions') as List<dynamic>;
    return [
      for (final row in rows) PermissionDefDto.fromApi(row as Map<String, dynamic>).toEntity(),
    ];
  }

  Future<List<RoleDef>> listRoles() async {
    final rows = await _client.getUri('$_base/roles') as List<dynamic>;
    return [
      for (final row in rows) RoleDefDto.fromApi(row as Map<String, dynamic>).toEntity(),
    ];
  }

  Future<RoleDef> updateRolePermissions(String roleId, List<String> permissionKeys) async {
    final json = await _client.put('$_base/roles/$roleId/permissions', {
      'permission_keys': permissionKeys,
    }) as Map<String, dynamic>;
    return RoleDefDto.fromApi(json).toEntity();
  }

  Future<List<AdminUser>> listUsers() async {
    final rows = await _client.getUri('$_base/users') as List<dynamic>;
    return [
      for (final row in rows) AdminUserDto.fromApi(row as Map<String, dynamic>).toEntity(),
    ];
  }

  Future<List<PermissionOverride>> listUserOverrides(String userId) async {
    final rows = await _client.getUri('$_base/users/$userId/overrides') as List<dynamic>;
    return [
      for (final row in rows)
        PermissionOverrideDto.fromApi(row as Map<String, dynamic>).toEntity(),
    ];
  }

  Future<List<PermissionOverride>> setUserOverrides(
    String userId,
    List<PermissionOverride> overrides,
  ) async {
    final rows = await _client.put('$_base/users/$userId/overrides', [
      for (final o in overrides) PermissionOverrideDto.fromEntity(o).toDto(),
    ]) as List<dynamic>;
    return [
      for (final row in rows)
        PermissionOverrideDto.fromApi(row as Map<String, dynamic>).toEntity(),
    ];
  }

  Future<AdminUser> createUser({
    required String name,
    required String email,
    required String password,
    required AdminRoleName role,
  }) async {
    final json = await _client.post('$_base/users', {
      'name': name,
      'email': email,
      'password': password,
      'role': role.apiValue,
      'role_id': null,
    }) as Map<String, dynamic>;
    return AdminUserDto.fromApi(json).toEntity();
  }

  Future<AdminUser> updateUserRole(String userId, String role, String? roleId) async {
    final json = await _client.patch('$_base/users/$userId/role', {
      'role': role,
      'role_id': roleId == null ? null : int.parse(roleId),
    }) as Map<String, dynamic>;
    return AdminUserDto.fromApi(json).toEntity();
  }
}
