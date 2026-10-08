import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/rbac_repository.dart';
import '../../domain/rbac_entities.dart';
import '../../../../core/network/api_exception.dart';

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

sealed class RbacEvent extends Equatable {
  const RbacEvent();
  @override
  List<Object?> get props => const [];
}

final class RbacStarted extends RbacEvent {
  const RbacStarted();
}

/// Selects the role whose permission matrix is being edited and resets the draft.
final class RbacRoleSelected extends RbacEvent {
  const RbacRoleSelected(this.roleId);
  final String roleId;
  @override
  List<Object?> get props => [roleId];
}

/// Toggles a permission in the draft (local only; saved on [RbacMatrixSaveRequested]).
final class RbacPermissionToggled extends RbacEvent {
  const RbacPermissionToggled(this.permissionKey);
  final String permissionKey;
  @override
  List<Object?> get props => [permissionKey];
}

/// Persists the draft via PUT /admin/rbac/roles/{roleId}/permissions.
final class RbacMatrixSaveRequested extends RbacEvent {
  const RbacMatrixSaveRequested();
}

final class RbacUserSelected extends RbacEvent {
  const RbacUserSelected(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

final class RbacRoleAssignDraftChanged extends RbacEvent {
  const RbacRoleAssignDraftChanged(this.role);
  final String role;
  @override
  List<Object?> get props => [role];
}

final class RbacRoleAssignSubmitted extends RbacEvent {
  const RbacRoleAssignSubmitted();
}

final class RbacOverrideDraftChanged extends RbacEvent {
  const RbacOverrideDraftChanged({required this.permissionKey, required this.granted});

  final String permissionKey;
  final bool granted;
  @override
  List<Object?> get props => [permissionKey, granted];
}

final class RbacCreateUserSubmitted extends RbacEvent {
  const RbacCreateUserSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final AdminRoleName role;
  @override
  List<Object?> get props => [name, email, password, role];
}

final class RbacOverrideApplied extends RbacEvent {
  const RbacOverrideApplied({required this.permissionKey, required this.granted});
  final String permissionKey;
  final bool granted;
  @override
  List<Object?> get props => [permissionKey, granted];
}

final class RbacOverrideRemoved extends RbacEvent {
  const RbacOverrideRemoved(this.permissionKey);
  final String permissionKey;
  @override
  List<Object?> get props => [permissionKey];
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

class RbacBloc extends Bloc<RbacEvent, RbacState> {
  RbacBloc(this._repo) : super(const RbacState()) {
    on<RbacStarted>(_onStarted);
    on<RbacRoleSelected>(_onRoleSelected);
    on<RbacPermissionToggled>(_onPermissionToggled);
    on<RbacMatrixSaveRequested>(_onMatrixSave);
    on<RbacUserSelected>(_onUserSelected);
    on<RbacRoleAssignDraftChanged>(_onRoleAssignDraftChanged);
    on<RbacRoleAssignSubmitted>(_onRoleAssignSubmitted);
    on<RbacCreateUserSubmitted>(_onCreateUserSubmitted);
    on<RbacOverrideDraftChanged>(_onOverrideDraftChanged);
    on<RbacOverrideApplied>(_onOverrideApplied);
    on<RbacOverrideRemoved>(_onOverrideRemoved);
  }

  final RbacRepository _repo;

  Future<void> _onStarted(RbacStarted event, Emitter<RbacState> emit) async {
    emit(state.copyWith(status: RbacStatus.loading, clearErrorKind: true));
    // Same dependency chain as the Angular component: permissions first
    // (seeds the override draft), then roles; users load independently.
    try {
      final permissions = await _repo.listPermissions();
      try {
        final roles = await _repo.listRoles();
        var users = const <AdminUser>[];
        RbacErrorKind? usersError;
        try {
          users = await _repo.listUsers();
        } on ApiException {
          usersError = RbacErrorKind.loadUsers;
        }
        final firstRole = roles._first;
        emit(state.copyWith(
          status: RbacStatus.ready,
          permissions: permissions,
          roles: roles,
          users: users,
          selectedRoleId: firstRole?.id,
          draftKeys: firstRole == null ? const {} : firstRole.permissionKeys.toSet(),
          overrideDraftKey: permissions.isEmpty ? '' : permissions.first.key,
          selectedUserId: users._first?.id,
          roleAssignDraft: users._first?.role ?? '',
        ));
        final firstUser = users._first;
        if (firstUser != null) {
          await _loadOverrides(firstUser.id, emit);
        }
        if (usersError != null) {
          emit(state.copyWith(errorKind: usersError));
        }
      } on ApiException {
        emit(state.copyWith(
          status: RbacStatus.failure,
          errorKind: RbacErrorKind.loadRoles,
        ));
      }
    } on ApiException {
      emit(state.copyWith(
        status: RbacStatus.failure,
        errorKind: RbacErrorKind.loadPermissions,
      ));
    }
  }

  void _onRoleSelected(RbacRoleSelected event, Emitter<RbacState> emit) {
    final role = state.roles.where((r) => r.id == event.roleId)._first;
    emit(state.copyWith(
      selectedRoleId: event.roleId,
      draftKeys: role?.permissionKeys.toSet() ?? const {},
      matrixSaveError: false,
    ));
  }

  void _onPermissionToggled(RbacPermissionToggled event, Emitter<RbacState> emit) {
    final next = Set<String>.of(state.draftKeys);
    if (!next.remove(event.permissionKey)) next.add(event.permissionKey);
    emit(state.copyWith(draftKeys: next, matrixSaveError: false));
  }

  Future<void> _onMatrixSave(RbacMatrixSaveRequested event, Emitter<RbacState> emit) async {
    final roleId = state.selectedRoleId;
    // super_admin always has every permission — the Angular UI disables the
    // toggles; mirror that guard here so a stray event cannot PUT.
    if (roleId == null || state.selectedRole?.isSuperAdmin == true) return;
    emit(state.copyWith(savingMatrix: true, matrixSaveError: false));
    try {
      final updated = await _repo.updateRolePermissions(roleId, state.draftKeys.toList());
      final roles = [
        for (final r in state.roles) if (r.id == updated.id) updated else r,
      ];
      emit(state.copyWith(roles: roles, savingMatrix: false));
    } on ApiException {
      emit(state.copyWith(
        savingMatrix: false,
        matrixSaveError: true,
        errorKind: RbacErrorKind.saveChange,
      ));
    }
  }

  Future<void> _onUserSelected(RbacUserSelected event, Emitter<RbacState> emit) async {
    final user = state.users.where((u) => u.id == event.userId)._first;
    emit(state.copyWith(
      selectedUserId: event.userId,
      roleAssignDraft: user?.role ?? '',
      overridesStatus: OverridesStatus.loading,
      overridesError: false,
    ));
    await _loadOverrides(event.userId, emit);
  }

  void _onRoleAssignDraftChanged(RbacRoleAssignDraftChanged event, Emitter<RbacState> emit) {
    emit(state.copyWith(roleAssignDraft: event.role, roleAssignError: false));
  }

  Future<void> _onRoleAssignSubmitted(RbacRoleAssignSubmitted event, Emitter<RbacState> emit) async {
    final userId = state.selectedUserId;
    if (userId == null || state.roleAssignDraft.isEmpty) return;
    emit(state.copyWith(savingRoleAssign: true, roleAssignError: false));
    try {
      final updated = await _repo.updateUserRole(userId, state.roleAssignDraft, null);
      final users = [for (final u in state.users) if (u.id == updated.id) updated else u];
      emit(state.copyWith(users: users, savingRoleAssign: false));
    } on ApiException {
      emit(state.copyWith(
        savingRoleAssign: false,
        roleAssignError: true,
        errorKind: RbacErrorKind.assignRole,
      ));
    }
  }

  Future<void> _onCreateUserSubmitted(RbacCreateUserSubmitted event, Emitter<RbacState> emit) async {
    if (event.name.isEmpty ||
        event.email.isEmpty ||
        event.password.isEmpty ||
        event.role.apiValue.isEmpty) {
      return;
    }
    emit(state.copyWith(
      creatingUser: true,
      clearCreateUserError: true,
      clearCreateUserSuccess: true,
    ));
    try {
      final user = await _repo.createUser(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(state.copyWith(
        users: [...state.users, user],
        creatingUser: false,
        createUserSuccess: user.email,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        creatingUser: false,
        // The Angular page surfaces err.error.detail (business message) first.
        createUserError: e.businessMessage,
        errorKind: RbacErrorKind.createUser,
      ));
    }
  }

  void _onOverrideDraftChanged(RbacOverrideDraftChanged event, Emitter<RbacState> emit) {
    emit(state.copyWith(
      overrideDraftKey: event.permissionKey,
      overrideDraftGranted: event.granted,
    ));
  }

  Future<void> _onOverrideApplied(RbacOverrideApplied event, Emitter<RbacState> emit) async {
    final userId = state.selectedUserId;
    if (userId == null || event.permissionKey.isEmpty) return;
    final next = [
      for (final o in state.overrides)
        if (o.permissionKey != event.permissionKey) o,
      PermissionOverride(permissionKey: event.permissionKey, granted: event.granted),
    ];
    await _saveOverrides(userId, next, emit);
  }

  Future<void> _onOverrideRemoved(RbacOverrideRemoved event, Emitter<RbacState> emit) async {
    final userId = state.selectedUserId;
    if (userId == null) return;
    final next = [
      for (final o in state.overrides)
        if (o.permissionKey != event.permissionKey) o,
    ];
    await _saveOverrides(userId, next, emit);
  }

  Future<void> _loadOverrides(String userId, Emitter<RbacState> emit) async {
    emit(state.copyWith(overridesStatus: OverridesStatus.loading, overridesError: false));
    try {
      final overrides = await _repo.listUserOverrides(userId);
      emit(state.copyWith(overrides: overrides, overridesStatus: OverridesStatus.ready));
    } on ApiException {
      emit(state.copyWith(
        overridesStatus: OverridesStatus.failure,
        errorKind: RbacErrorKind.loadOverrides,
      ));
    }
  }

  Future<void> _saveOverrides(
    String userId,
    List<PermissionOverride> overrides,
    Emitter<RbacState> emit,
  ) async {
    emit(state.copyWith(savingOverrides: true, overridesError: false));
    try {
      final result = await _repo.setUserOverrides(userId, overrides);
      emit(state.copyWith(overrides: result, savingOverrides: false));
    } on ApiException {
      emit(state.copyWith(
        savingOverrides: false,
        overridesError: true,
        errorKind: RbacErrorKind.saveOverrides,
      ));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get _first => isEmpty ? null : first;
}
