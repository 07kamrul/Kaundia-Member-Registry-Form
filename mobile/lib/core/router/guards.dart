import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/session.dart';
import '../di/injector.dart';
import '../navigation/nav_items.dart';

/// go_router redirect guard, mirroring Angular authGuard + permissionGuard:
/// - unauthenticated access to guarded routes -> /login (remembering returnUrl)
/// - member with must_change_password -> /change-password
/// - insufficient permission -> /403
String? appRedirect(BuildContext context, GoRouterState state) {
  final session = sl<SessionManager>().session;
  final loc = state.uri.toString();
  final isPublic = _publicPrefixes.any((p) => loc == p || loc.startsWith('$p/'));

  if (session == null) {
    if (isPublic) return null;
    return '/login?returnUrl=${Uri.encodeComponent(loc)}';
  }
  if (session.mustChangePassword && loc != '/change-password' && !isPublic) {
    return '/change-password';
  }
  if (isPublic) {
    if (loc == '/login' || loc == '/register') return null;
  }

  final required = _requiredPermissionFor(loc);
  if (required != null && !session.canAny(required)) return '/403';
  return null;
}

const _publicPrefixes = [
  '/',
  '/register',
  '/login',
  '/forgot-password',
  '/reset-password',
  '/notices',
  '/events',
  '/403',
];

const _areaPermissions = <String, List<String>>{
  '/installments-management': ['member.view_all'],
  '/picnic-payments': ['member.view_all'],
  '/fee-settings': ['manage_fee_settings'],
  '/society-costs': ['manage_costs'],
  '/finance-management': ['manage_finance'],
  '/payment-verifications': ['manage_finance'],
  '/roadmap-management': ['manage_roadmap'],
  '/config-lists': ['manage_system_config'],
  '/notices-management': ['manage_notices'],
  '/events-management': ['manage_notices'],
  '/roles': ['manage_roles', 'manage_users'],
  '/audit-log': ['view_audit_log'],
  '/property-requests': ['property.review'],
};

/// Prefix-matched areas (list + detail routes).
const _areaPrefixPermissions = <String, List<String>>{
  '/submissions': ['membership.review'],
  '/members': ['member.view_all'],
  '/resolution-book/add': ['manage_resolution_book'],
  '/resolution-book/edit': ['manage_resolution_book'],
};

/// Member-area pages require profile.view_own (permissionGuard in Angular).
const _memberPages = [
  '/profile',
  '/installments',
  '/cost-shares',
  '/property-requests/new',
  '/picnic-payment',
];

List<String>? _requiredPermissionFor(String loc) {
  final path = loc.split('?').first;
  if (_memberPages.contains(path) ||
      (path.startsWith('/property-requests/') && path.endsWith('/edit'))) {
    return [AppNav.memberAreaPermission];
  }
  final exact = _areaPermissions[path];
  if (exact != null) return exact;
  for (final entry in _areaPrefixPermissions.entries) {
    if (path == entry.key || path.startsWith('${entry.key}/')) return entry.value;
  }
  return null;
}

/// Landing route after login, mirroring Angular roleGuard: fee managers ->
/// /fee-settings, everyone else -> the dashboard (which itself switches by tier).
String landingRoute(Session session) {
  const feeManagerPermissions = ['manage_fee_settings'];
  if (session.canAny(feeManagerPermissions)) return '/fee-settings';
  return '/dashboard';
}
