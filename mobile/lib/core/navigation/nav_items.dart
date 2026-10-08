import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../enums/enums.dart';

/// One config list drives both bottom-nav (member) and drawer
/// (management / super admin), permission-filtered at runtime.
class NavItem {
  const NavItem({
    required this.labelKey,
    required this.route,
    required this.icon,
    this.requiredPermission,
    this.tier,
  });

  final String Function(AppLocalizations) labelKey;
  final String route;
  final IconData icon;
  final String? requiredPermission;
  final LandingTierFilter? tier;
}

enum LandingTierFilter { member, management, superAdmin }

class AppNav {
  const AppNav._();

  static const memberAreaPermission = 'profile.view_own';

  static String Function(AppLocalizations) _t(String Function(AppLocalizations) f) => f;

  static final List<NavItem> items = [
    NavItem(
      labelKey: _t((l) => l.navDashboard),
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
    ),
    NavItem(
      labelKey: _t((l) => l.navProfile),
      route: '/profile',
      icon: Icons.person_outline,
      requiredPermission: 'profile.view_own',
      tier: LandingTierFilter.member,
    ),
    NavItem(
      labelKey: _t((l) => l.navInstallments),
      route: '/installments',
      icon: Icons.payments_outlined,
      requiredPermission: 'profile.view_own',
      tier: LandingTierFilter.member,
    ),
    NavItem(
      labelKey: _t((l) => l.navCostShares),
      route: '/cost-shares',
      icon: Icons.pie_chart_outline,
      requiredPermission: 'profile.view_own',
      tier: LandingTierFilter.member,
    ),
    NavItem(
      labelKey: _t((l) => l.navNotices),
      route: '/notices',
      icon: Icons.campaign_outlined,
    ),
    NavItem(
      labelKey: _t((l) => l.navEvents),
      route: '/events',
      icon: Icons.event_outlined,
    ),
    NavItem(
      labelKey: _t((l) => l.navFundTransparency),
      route: '/fund-transparency',
      icon: Icons.volunteer_activism_outlined,
    ),
    NavItem(
      labelKey: _t((l) => l.navRoadmap),
      route: '/roadmap',
      icon: Icons.map_outlined,
    ),
    NavItem(
      labelKey: _t((l) => l.navResolutionBook),
      route: '/resolution-book',
      icon: Icons.menu_book_outlined,
    ),
    NavItem(
      labelKey: _t((l) => l.navSubmissions),
      route: '/submissions',
      icon: Icons.fact_check_outlined,
      requiredPermission: 'membership.review',
    ),
    NavItem(
      labelKey: _t((l) => l.navMembersList),
      route: '/members',
      icon: Icons.groups_outlined,
      requiredPermission: 'member.view_all',
    ),
    NavItem(
      labelKey: _t((l) => l.navInstallments),
      route: '/installments-management',
      icon: Icons.receipt_long_outlined,
      requiredPermission: 'member.view_all',
    ),
    NavItem(
      labelKey: _t((l) => l.navFeeSettings),
      route: '/fee-settings',
      icon: Icons.settings_suggest_outlined,
      requiredPermission: 'manage_fee_settings',
    ),
    NavItem(
      labelKey: _t((l) => l.navSocietyCosts),
      route: '/society-costs',
      icon: Icons.account_balance_wallet_outlined,
      requiredPermission: 'manage_costs',
    ),
    NavItem(
      labelKey: _t((l) => l.navFinanceManagement),
      route: '/finance-management',
      icon: Icons.account_balance_outlined,
      requiredPermission: 'manage_finance',
    ),
    NavItem(
      labelKey: _t((l) => l.navConfigLists),
      route: '/config-lists',
      icon: Icons.tune_outlined,
      requiredPermission: 'manage_system_config',
    ),
    NavItem(
      labelKey: _t((l) => l.navNoticesManagement),
      route: '/notices-management',
      icon: Icons.edit_note_outlined,
      requiredPermission: 'manage_notices',
    ),
    NavItem(
      labelKey: _t((l) => l.navEventsManagement),
      route: '/events-management',
      icon: Icons.edit_calendar_outlined,
      requiredPermission: 'manage_notices',
    ),
    NavItem(
      labelKey: _t((l) => l.navRolesPermissions),
      route: '/roles',
      icon: Icons.admin_panel_settings_outlined,
      requiredPermission: 'manage_roles',
      tier: LandingTierFilter.superAdmin,
    ),
    NavItem(
      labelKey: _t((l) => l.navAuditLog),
      route: '/audit-log',
      icon: Icons.history_outlined,
      requiredPermission: 'view_audit_log',
      tier: LandingTierFilter.superAdmin,
    ),
  ];

  static List<NavItem> visibleFor({
    required LandingTier landingTier,
    required bool Function(String) can,
  }) {
    return items.where((item) {
      if (item.tier == LandingTierFilter.member && landingTier != LandingTier.member) {
        return false;
      }
      if (item.tier == LandingTierFilter.superAdmin && landingTier != LandingTier.superAdmin) {
        return false;
      }
      final p = item.requiredPermission;
      return p == null || can(p);
    }).toList();
  }
}
