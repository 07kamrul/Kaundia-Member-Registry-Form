import '../domain/rbac_entities.dart';

/// snake_case API DTOs for /admin/rbac/*, with hand-written field-for-field
/// mappers to the camelCase domain entities (ids become String client-side).

class PermissionDefDto {
  const PermissionDefDto({
    required this.key,
    required this.resource,
    required this.action,
    required this.description,
  });

  final String key;
  final String resource;
  final String action;
  final String description;

  factory PermissionDefDto.fromApi(Map<String, dynamic> json) => PermissionDefDto(
        key: json['key'] as String,
        resource: json['resource'] as String,
        action: json['action'] as String,
        description: json['description'] as String,
      );

  PermissionDef toEntity() => PermissionDef(
        key: key,
        resource: resource,
        action: action,
        description: description,
      );
}

class RoleDefDto {
  const RoleDefDto({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionKeys,
  });

  final int id;
  final String name;
  final String? description;
  final List<String> permissionKeys;

  factory RoleDefDto.fromApi(Map<String, dynamic> json) => RoleDefDto(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        permissionKeys: [
          for (final k in (json['permission_keys'] as List<dynamic>? ?? const [])) k as String,
        ],
      );

  RoleDef toEntity() => RoleDef(
        id: id.toString(),
        name: name,
        description: description,
        permissionKeys: List<String>.of(permissionKeys),
      );
}

class PermissionOverrideDto {
  const PermissionOverrideDto({required this.permissionKey, required this.granted});

  final String permissionKey;
  final bool granted;

  factory PermissionOverrideDto.fromApi(Map<String, dynamic> json) => PermissionOverrideDto(
        permissionKey: json['permission_key'] as String,
        granted: json['granted'] as bool,
      );

  Map<String, dynamic> toDto() => {'permission_key': permissionKey, 'granted': granted};

  PermissionOverride toEntity() => PermissionOverride(
        permissionKey: permissionKey,
        granted: granted,
      );

  factory PermissionOverrideDto.fromEntity(PermissionOverride entity) => PermissionOverrideDto(
        permissionKey: entity.permissionKey,
        granted: entity.granted,
      );
}

class AdminUserDto {
  const AdminUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleId,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final int? roleId;

  factory AdminUserDto.fromApi(Map<String, dynamic> json) => AdminUserDto(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        roleId: json['role_id'] as int?,
      );

  AdminUser toEntity() => AdminUser(
        id: id.toString(),
        name: name,
        email: email,
        role: role,
        roleId: roleId?.toString(),
      );
}
