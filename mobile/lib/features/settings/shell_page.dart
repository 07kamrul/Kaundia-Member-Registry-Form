import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/navigation/nav_items.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import 'settings_bloc.dart';

/// Adaptive navigation shell, items filtered by the resolved permission set:
/// - compact: member → bottom bar (+ "More" sheet), management → drawer
/// - medium: navigation rail
/// - expanded: permanent side panel
class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});

  /// Bottom bar shows this many routes; the rest live behind "More".
  static const _bottomBarRoutes = 4;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionManager>().session;
    if (session == null) {
      // Redirect guard should have caught this; defensive fallback.
      return const Scaffold(body: SizedBox.shrink());
    }
    final visible = AppNav.visibleFor(
      landingTier: session.landingTier,
      can: session.can,
    );
    final currentRoute = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(visible, currentRoute);
    final member = session.landingTier == LandingTier.member;

    return switch (context.windowSize) {
      WindowSize.expanded => Scaffold(
          appBar: _AppBar(visible: visible, showMenu: false),
          body: Row(
            children: [
              SizedBox(
                width: 280,
                child: _NavPanel(visible: visible, selected: selected),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      WindowSize.medium => Scaffold(
          appBar: _AppBar(visible: visible, showMenu: false),
          body: Row(
            children: [
              _Rail(visible: visible, selected: selected),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      WindowSize.compact => Scaffold(
          appBar: _AppBar(visible: visible, showMenu: !member),
          drawer: member
              ? null
              : Drawer(child: _NavPanel(visible: visible, selected: selected, popFirst: true)),
          bottomNavigationBar: member && visible.isNotEmpty
              ? _BottomBar(visible: visible, selected: selected)
              : null,
          body: child,
        ),
    };
  }

  static int _selectedIndex(List<NavItem> visible, String currentRoute) {
    return visible.indexWhere(
      (item) => currentRoute == item.route || currentRoute.startsWith('${item.route}/'),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.visible, required this.selected});

  final List<NavItem> visible;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hasMore = visible.length > ShellPage._bottomBarRoutes + 1;
    final primary = hasMore ? visible.take(ShellPage._bottomBarRoutes).toList() : visible;
    final overflow = hasMore ? visible.skip(ShellPage._bottomBarRoutes).toList() : <NavItem>[];
    // Routes behind "More" highlight the More tab.
    final index = selected < 0
        ? 0
        : selected < primary.length
            ? selected
            : primary.length;

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        if (i < primary.length) {
          context.go(primary[i].route);
        } else {
          _showMore(context, overflow);
        }
      },
      destinations: [
        for (final item in primary)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.icon, fill: 1),
            label: item.labelKey(loc),
            tooltip: item.labelKey(loc),
          ),
        if (hasMore)
          NavigationDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps),
            label: MaterialLocalizations.of(context).moreButtonTooltip,
          ),
      ],
    );
  }

  void _showMore(BuildContext context, List<NavItem> items) {
    final loc = AppLocalizations.of(context);
    final currentRoute = GoRouterState.of(context).uri.path;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
        children: [
          for (final item in items)
            _MoreTile(
              item: item,
              label: item.labelKey(loc),
              selected: currentRoute == item.route || currentRoute.startsWith('${item.route}/'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(item.route);
              },
            ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: scheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.visible, required this.selected});

  final List<NavItem> visible;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    // Many management routes: let the rail scroll instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: selected < 0 ? null : selected,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -1,
              onDestinationSelected: (i) => context.go(visible[i].route),
              destinations: [
                for (final item in visible)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, fill: 1),
                    label: SizedBox(
                      width: 72,
                      child: Text(
                        item.labelKey(loc),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
              trailing: IconButton(
                tooltip: loc.commonLogout,
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded list of destinations — used as the modal drawer on phones and the
/// permanent side panel on large screens.
class _NavPanel extends StatelessWidget {
  const _NavPanel({required this.visible, required this.selected, this.popFirst = false});

  final List<NavItem> visible;
  final int selected;
  final bool popFirst;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    void go(String route) {
      if (popFirst) Navigator.of(context).pop();
      context.go(route);
    }

    return SafeArea(
      child: Column(
        children: [
          if (popFirst)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, AppColors.emerald900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.secondary,
                    child: const Icon(Icons.diversity_3, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.brandOrgName,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (var i = 0; i < visible.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      leading: Icon(visible[i].icon),
                      title: Text(
                        visible[i].labelKey(loc),
                        style: TextStyle(
                          fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: i == selected,
                      onTap: () => go(visible[i].route),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(loc.commonLogout, style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                if (popFirst) Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({required this.visible, required this.showMenu});

  final List<NavItem> visible;
  final bool showMenu;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeMode = context.select<SettingsBloc, String>((b) => b.state.themeMode);
    return AppBar(
      automaticallyImplyLeading: showMenu,
      title: Row(
        children: [
          ClipOval(
            child: Image.asset('assets/images/logo.jpeg', width: 32, height: 32),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(loc.brandOrgName, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        // Language toggle beside the theme toggle, mirroring the web app bar.
        IconButton(
          tooltip: loc.commonLanguage,
          icon: const Icon(Icons.translate),
          onPressed: () {
            final bloc = context.read<SettingsBloc>();
            bloc.add(SettingsLanguageChanged(bloc.state.languageCode == 'bn' ? 'en' : 'bn'));
          },
        ),
        IconButton(
          tooltip: loc.commonTheme,
          icon: Icon(switch (themeMode) {
            'dark' => Icons.dark_mode_outlined,
            'light' => Icons.light_mode_outlined,
            _ => Icons.brightness_auto_outlined,
          }),
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
            tooltip: loc.navProfile,
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') _logout(context);
              if (value == 'password') context.go('/change-password');
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'password',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_reset),
                  title: Text(loc.memberChangePasswordTitle),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(loc.commonLogout),
                ),
              ),
            ],
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

void _logout(BuildContext context) {
  context.read<AuthBloc>().add(const AuthLogoutRequested());
  context.go('/login');
}
