/// RBAC domain entities (camelCase, ids as String). Ported 1:1 from the
/// Angular `RbacService` interfaces (frontend/src/app/core/services/rbac.service.ts).
class PermissionDef {
  const PermissionDef({
    required this.key,
    required this.resource,
    required this.action,
    required this.description,
  });

  final String key;
  final String resource;
  final String action;
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionDef &&
          key == other.key &&
          resource == other.resource &&
          action == other.action &&
          description == other.description;

  @override
  int get hashCode => Object.hash(key, resource, action, description);
}

class RoleDef {
  const RoleDef({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionKeys,
  });

  final String id;
  final String name;
  final String? description;
  final List<String> permissionKeys;

  bool hasPermission(String permissionKey) => permissionKeys.contains(permissionKey);

  /// The Angular template locks the whole matrix for `super_admin`.
  bool get isSuperAdmin => name == 'super_admin';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleDef &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          const ListEquality().equals(permissionKeys, other.permissionKeys);

  @override
  int get hashCode => Object.hash(id, name, description, Object.hashAll(permissionKeys));
}

class PermissionOverride {
  const PermissionOverride({required this.permissionKey, required this.granted});

  final String permissionKey;
  final bool granted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionOverride &&
          permissionKey == other.permissionKey &&
          granted == other.granted;

  @override
  int get hashCode => Object.hash(permissionKey, granted);
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleId,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? roleId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUser &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role &&
          roleId == other.roleId;

  @override
  int get hashCode => Object.hash(id, name, email, role, roleId);
}

class ListEquality {
  const ListEquality();

  bool equals<T>(List<T> a, List<T> b) =>
      a.length == b.length && Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
}

/// The three assignable role names mirrored from the Angular `<select>` options.
enum AdminRoleName { administrator, executiveCommittee, superAdmin }

extension AdminRoleNameX on AdminRoleName {
  static AdminRoleName fromApi(String? value) => switch (value) {
        'administrator' => AdminRoleName.administrator,
        'executive_committee' => AdminRoleName.executiveCommittee,
        'super_admin' => AdminRoleName.superAdmin,
        _ => AdminRoleName.administrator,
      };

  String get apiValue => switch (this) {
        AdminRoleName.administrator => 'administrator',
        AdminRoleName.executiveCommittee => 'executive_committee',
        AdminRoleName.superAdmin => 'super_admin',
      };
}
