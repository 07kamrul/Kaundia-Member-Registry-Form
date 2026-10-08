import 'package:equatable/equatable.dart';

import '../enums/enums.dart';

/// Authenticated session: role + resolved permission set. Permission-driven UI
/// flows through [can]/[canAny] — never role-name checks in widgets.
class Session extends Equatable {
  const Session({
    required this.accessToken,
    required this.role,
    required this.permissions,
    this.mustChangePassword = false,
  });

  final String accessToken;
  final String role;
  final Set<String> permissions;
  final bool mustChangePassword;

  bool get isMemberTier => role == 'member';

  /// Mirrors Angular auth.landingTier(): super_admin / management / member.
  LandingTier get landingTier {
    if (role == 'super_admin') return LandingTier.superAdmin;
    if (role != 'member') return LandingTier.management;
    return LandingTier.member;
  }

  bool can(String permissionKey) => permissions.contains(permissionKey);

  bool canAny(Iterable<String> keys) => keys.any(permissions.contains);

  @override
  List<Object?> get props => [accessToken, role, permissions, mustChangePassword];
}

/// Route-guard / nav-filter permission unions, mirroring Angular app.routes.ts.
class AppPermissions {
  const AppPermissions._();

  static const memberArea = 'profile.view_own';
  static const submissions = 'membership.review';
  static const propertyRequests = 'property.review';
  static const membersViewAll = 'member.view_all';
  static const feeSettings = 'manage_fee_settings';
  static const societyCosts = 'manage_costs';
  static const finance = 'manage_finance';
  static const roadmapManagement = 'manage_roadmap';
  static const configLists = 'manage_system_config';
  static const contentManagement = 'manage_notices';
  static const roles = 'manage_roles';
  static const users = 'manage_users';
  static const auditLog = 'view_audit_log';
  static const resolutionBookManage = 'manage_resolution_book';

  static const superAdminArea = <String>[roles, users];
  static const managementArea = <String>[
    submissions,
    propertyRequests,
    membersViewAll,
    feeSettings,
    societyCosts,
    finance,
    roadmapManagement,
    configLists,
    contentManagement,
  ];
}
