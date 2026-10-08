part of 'rbac_bloc.dart';

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
