import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/navigation/nav_items.dart';
import '../../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import 'settings_bloc.dart';

/// Navigation shell: bottom navigation for the member tier, drawer for
/// management & super admin — items filtered by the resolved permission set.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionManager>().session;
    if (session == null) {
      // Redirect guard should have caught this; defensive fallback.
      return const Scaffold(body: SizedBox.shrink());
    }
    final loc = AppLocalizations.of(context);
    final visible = AppNav.visibleFor(
      landingTier: session.landingTier,
      can: session.can,
    );
    final currentRoute = GoRouterState.of(context).uri.path;
    final member = session.landingTier == LandingTier.member;

    final body = Scaffold(
      appBar: _AppBar(session: session, visible: visible),
      drawer: member
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                      child: Text(
                        loc.brandOrgName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final item in visible)
                      ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.labelKey(loc)),
                        selected: currentRoute == item.route ||
                            currentRoute.startsWith('${item.route}/'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(loc.commonLogout),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: member && visible.isNotEmpty
          ? NavigationBar(
              selectedIndex: _selectedIndex(visible, currentRoute),
              onDestinationSelected: (i) => context.go(visible[i].route),
              destinations: [
                for (final item in visible.take(5))
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, fill: 1),
                    label: item.labelKey(loc),
                  ),
              ],
            )
          : null,
      body: child,
    );
    return body;
  }

  int _selectedIndex(List<NavItem> visible, String currentRoute) {
    final idx = visible.indexWhere(
      (item) => currentRoute == item.route || currentRoute.startsWith('${item.route}/'),
    );
    return idx < 0 ? 0 : idx;
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({required this.session, required this.visible});

  final dynamic session;
  final List<NavItem> visible;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBar(
      title: Text(loc.brandOrgName),
      actions: [
        // Language toggle (globe) beside the theme toggle, mirroring the web app bar.
        IconButton(
          tooltip: loc.commonLanguage,
          icon: const Icon(Icons.language),
          onPressed: () {
            final bloc = context.read<SettingsBloc>();
            bloc.add(SettingsLanguageChanged(bloc.state.languageCode == 'bn' ? 'en' : 'bn'));
          },
        ),
        IconButton(
          tooltip: loc.commonTheme,
          icon: const Icon(Icons.brightness_6_outlined),
          onPressed: () {
            final bloc = context.read<SettingsBloc>();
            final next = switch (bloc.state.themeMode) {
              'dark' => 'light',
              'light' => 'system',
              _ => 'dark',
            };
            bloc.add(SettingsThemeChanged(next));
          },
        ),
        if (visible.any((i) => i.route == '/profile'))
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') _logout(context);
              if (value == 'password') context.go('/change-password');
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'password', child: Text(loc.memberChangePasswordTitle)),
              PopupMenuItem(value: 'logout', child: Text(loc.commonLogout)),
            ],
          ),
      ],
    );
  }
}

void _logout(BuildContext context) {
  context.read<AuthBloc>().add(const AuthLogoutRequested());
  context.go('/login');
}
