part of 'rbac_bloc.dart';


/// Which load/save failed — the page maps each to its localized message,
/// mirroring the Angular `admin.roleManagement.errors.*` keys.
enum RbacErrorKind {
  loadPermissions,
  loadRoles,
  loadUsers,
  saveChange,
  createUser,
  assignRole,
  loadOverrides,
  saveOverrides,
}

enum RbacStatus { initial, loading, ready, failure }

enum OverridesStatus { initial, loading, ready, failure }

class RbacState extends Equatable {
  const RbacState({
    this.status = RbacStatus.initial,
    this.errorKind,
    this.permissions = const [],
    this.roles = const [],
    this.users = const [],
    this.selectedRoleId,
    this.draftKeys = const {},
    this.savingMatrix = false,
    this.matrixSaveError = false,
    this.selectedUserId,
    this.roleAssignDraft = '',
    this.savingRoleAssign = false,
    this.roleAssignError = false,
    this.overrides = const [],
    this.overridesStatus = OverridesStatus.initial,
    this.overrideDraftKey = '',
    this.overrideDraftGranted = true,
    this.savingOverrides = false,
    this.overridesError = false,
    this.creatingUser = false,
    this.createUserError,
    this.createUserSuccess,
  });

  final RbacStatus status;
  final RbacErrorKind? errorKind;
  final List<PermissionDef> permissions;
  final List<RoleDef> roles;
  final List<AdminUser> users;

  // Permission matrix editor.
  final String? selectedRoleId;
  final Set<String> draftKeys;
  final bool savingMatrix;
  final bool matrixSaveError;

  // User management.
  final String? selectedUserId;
  final String roleAssignDraft;
  final bool savingRoleAssign;
  final bool roleAssignError;
  final List<PermissionOverride> overrides;
  final OverridesStatus overridesStatus;
  final String overrideDraftKey;
  final bool overrideDraftGranted;
  final bool savingOverrides;
  final bool overridesError;
  final bool creatingUser;
  final String? createUserError;
  final String? createUserSuccess;

  bool get hasUsers => users.isNotEmpty;

  RoleDef? get selectedRole =>
      roles.where((r) => r.id == selectedRoleId)._first;

  AdminUser? get selectedUser =>
      users.where((u) => u.id == selectedUserId)._first;

  /// Groups permissions by their resource prefix for the mobile matrix.
  Map<String, List<PermissionDef>> get permissionsByResource {
    final map = <String, List<PermissionDef>>{};
    for (final p in permissions) {
      (map[p.resource] ??= []).add(p);
    }
    return map;
  }

  RbacState copyWith({
    RbacStatus? status,
    RbacErrorKind? errorKind,
    bool clearErrorKind = false,
    List<PermissionDef>? permissions,
    List<RoleDef>? roles,
    List<AdminUser>? users,
    String? selectedRoleId,
    Set<String>? draftKeys,
    bool? savingMatrix,
    bool? matrixSaveError,
    String? selectedUserId,
    String? roleAssignDraft,
    bool? savingRoleAssign,
    bool? roleAssignError,
    List<PermissionOverride>? overrides,
    OverridesStatus? overridesStatus,
    String? overrideDraftKey,
    bool? overrideDraftGranted,
    bool? savingOverrides,
    bool? overridesError,
    bool? creatingUser,
    String? createUserError,
    bool clearCreateUserError = false,
    String? createUserSuccess,
    bool clearCreateUserSuccess = false,
  }) {
    return RbacState(
      status: status ?? this.status,
      errorKind: clearErrorKind ? null : (errorKind ?? this.errorKind),
      permissions: permissions ?? this.permissions,
      roles: roles ?? this.roles,
      users: users ?? this.users,
      selectedRoleId: selectedRoleId ?? this.selectedRoleId,
      draftKeys: draftKeys ?? this.draftKeys,
      savingMatrix: savingMatrix ?? this.savingMatrix,
      matrixSaveError: matrixSaveError ?? this.matrixSaveError,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      roleAssignDraft: roleAssignDraft ?? this.roleAssignDraft,
      savingRoleAssign: savingRoleAssign ?? this.savingRoleAssign,
      roleAssignError: roleAssignError ?? this.roleAssignError,
      overrides: overrides ?? this.overrides,
      overridesStatus: overridesStatus ?? this.overridesStatus,
      overrideDraftKey: overrideDraftKey ?? this.overrideDraftKey,
      overrideDraftGranted: overrideDraftGranted ?? this.overrideDraftGranted,
      savingOverrides: savingOverrides ?? this.savingOverrides,
      overridesError: overridesError ?? this.overridesError,
      creatingUser: creatingUser ?? this.creatingUser,
      createUserError: clearCreateUserError ? null : (createUserError ?? this.createUserError),
      createUserSuccess:
          clearCreateUserSuccess ? null : (createUserSuccess ?? this.createUserSuccess),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorKind,
        permissions,
        roles,
        users,
        selectedRoleId,
        draftKeys,
        savingMatrix,
        matrixSaveError,
        selectedUserId,
        roleAssignDraft,
        savingRoleAssign,
        roleAssignError,
        overrides,
        overridesStatus,
        overrideDraftKey,
        overrideDraftGranted,
        savingOverrides,
        overridesError,
        creatingUser,
        createUserError,
        createUserSuccess,
      ];
}
