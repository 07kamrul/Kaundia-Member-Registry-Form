import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/rbac_repository.dart';
import '../../domain/rbac_entities.dart';
import '../../../../core/network/api_exception.dart';

part 'rbac_event.dart';
part 'rbac_state.dart';

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
