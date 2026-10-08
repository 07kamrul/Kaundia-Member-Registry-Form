import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/rbac_repository.dart';
import '../domain/rbac_entities.dart';
import '../presentation/bloc/rbac_bloc.dart';
import '../presentation/widgets/roles_users_tab.dart';

/// Port of the Angular RoleManagementComponent: permission matrix per role,
/// create-administrator form and per-user permission overrides. The wide
/// matrix becomes role chips + permission groups (expansion tiles on phones,
/// a two-column card grid on tablets); the two halves of the Angular page
/// become tabs (Roles / Users).
class RolesPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const RolesPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RbacBloc(RbacRepository(sl<ApiClient>()))..add(const RbacStarted()),
      child: const _RolesView(),
    );
  }
}

class _RolesView extends StatefulWidget {
  const _RolesView();

  @override
  State<_RolesView> createState() => _RolesViewState();
}

class _RolesViewState extends State<_RolesView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveCenter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      icon: Icons.admin_panel_settings_outlined,
                      title: loc.adminRoleManagementTitle,
                      subtitle: loc.adminRoleManagementSubtitle,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.pageGutter - 12),
                      child: AppTabs(
                        labels: [loc.superadminTabsRoles, loc.superadminTabsUsers],
                        selectedIndex: _tabIndex,
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (a, b) => a.status != b.status || a.errorKind != b.errorKind,
      builder: (context, state) {
        if (isRbacLoading(state)) return const SkeletonLoader(lines: 8);
        if (state.status == RbacStatus.failure) {
          return InlineError(
            message: _loadErrorText(loc, state.errorKind),
            onRetry: () => context.read<RbacBloc>().add(const RbacStarted()),
          );
        }
        return IndexedStack(
          index: _tabIndex,
          children: const [_RolesMatrixTab(), RolesUsersTab()],
        );
      },
    );
  }
}

String _loadErrorText(AppLocalizations loc, RbacErrorKind? kind) => switch (kind) {
      RbacErrorKind.loadRoles => loc.adminRoleManagementErrorsLoadRolesFailed,
      RbacErrorKind.loadUsers => loc.adminRoleManagementErrorsLoadUsersFailed,
      _ => loc.adminRoleManagementErrorsLoadPermissionsFailed,
    };

/// Tab 1: role chips + grouped permission matrix with a pinned save bar.
class _RolesMatrixTab extends StatelessWidget {
  const _RolesMatrixTab();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (a, b) =>
          a.roles != b.roles ||
          a.permissions != b.permissions ||
          a.selectedRoleId != b.selectedRoleId ||
          a.draftKeys != b.draftKeys ||
          a.savingMatrix != b.savingMatrix ||
          a.matrixSaveError != b.matrixSaveError,
      builder: (context, state) {
        final bloc = context.read<RbacBloc>();
        if (state.roles.isEmpty) {
          return EmptyState(icon: Icons.shield_outlined, message: loc.superadminRolesEmpty);
        }
        final role = state.selectedRole;
        final locked = role?.isSuperAdmin ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageBody(
                onRefresh: () => refreshRbac(bloc),
                children: [
                  SectionTitle(loc.adminRoleManagementCreateAdminRoleLabel),
                  _RoleChips(state: state),
                  if (locked) const _LockedBanner(),
                  if (state.matrixSaveError)
                    InlineError(
                      message: loc.adminRoleManagementErrorsSaveChangeFailed,
                      onRetry: () => bloc.add(const RbacMatrixSaveRequested()),
                    ),
                  _PermissionGroups(state: state, locked: locked),
                ],
              ),
            ),
            if (role != null && !locked) _MatrixSaveBar(state: state, role: role),
          ],
        );
      },
    );
  }
}

class _RoleChips extends StatelessWidget {
  const _RoleChips({required this.state});

  final RbacState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RbacBloc>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in state.roles)
            ChoiceChip(
              avatar: Icon(
                r.isSuperAdmin ? Icons.lock_outline : Icons.badge_outlined,
                size: 18,
              ),
              showCheckmark: false,
              label: Text(r.name),
              tooltip: r.description,
              selected: state.selectedRoleId == r.id,
              onSelected: (_) => bloc.add(RbacRoleSelected(r.id)),
            ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.fromLTRB(context.pageGutter, 12, context.pageGutter, 0),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.adminRoleManagementAllPermissionsAlways,
                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expansion tiles on phones, a two-column card grid on tablets.
class _PermissionGroups extends StatelessWidget {
  const _PermissionGroups({required this.state, required this.locked});

  final RbacState state;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final groups = state.permissionsByResource.entries.toList();
    final gutter = context.pageGutter;
    if (context.isCompact) {
      return Padding(
        padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
        child: Column(
          spacing: 8,
          children: [
            for (final g in groups)
              _GroupTile(name: g.key, permissions: g.value, state: state, locked: locked),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
      child: ResponsiveGrid(
        minItemWidth: 300,
        maxColumns: 2,
        children: [
          for (final g in groups)
            AppCard(
              margin: EdgeInsets.zero,
              title: g.key,
              trailing: _GrantedCount(permissions: g.value, state: state),
              child: _PermissionChecks(permissions: g.value, state: state, locked: locked),
            ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.name,
    required this.permissions,
    required this.state,
    required this.locked,
  });

  final String name;
  final List<PermissionDef> permissions;
  final RbacState state;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: _GrantedCount(permissions: permissions, state: state, asText: true),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [_PermissionChecks(permissions: permissions, state: state, locked: locked)],
      ),
    );
  }
}

/// "granted / total" for a permission group.
class _GrantedCount extends StatelessWidget {
  const _GrantedCount({required this.permissions, required this.state, this.asText = false});

  final List<PermissionDef> permissions;
  final RbacState state;
  final bool asText;

  @override
  Widget build(BuildContext context) {
    final granted = permissions.where((p) => state.draftKeys.contains(p.key)).length;
    final label = '$granted / ${permissions.length}';
    if (asText) return Text(label, style: Theme.of(context).textTheme.bodySmall);
    return StatusBadge(
      kind: granted == 0
          ? StatusKind.neutral
          : granted == permissions.length
              ? StatusKind.approved
              : StatusKind.pending,
      label: label,
    );
  }
}

class _PermissionChecks extends StatelessWidget {
  const _PermissionChecks({
    required this.permissions,
    required this.state,
    required this.locked,
  });

  final List<PermissionDef> permissions;
  final RbacState state;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RbacBloc>();
    return Column(
      children: [
        for (final permission in permissions)
          AppCheckbox(
            label: permission.description,
            value: locked || state.draftKeys.contains(permission.key),
            onChanged: locked || state.savingMatrix
                ? null
                : (_) => bloc.add(RbacPermissionToggled(permission.key)),
          ),
      ],
    );
  }
}

class _MatrixSaveBar extends StatelessWidget {
  const _MatrixSaveBar({required this.state, required this.role});

  final RbacState state;
  final RoleDef role;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unchanged = role.permissionKeys.length == state.draftKeys.length &&
        role.permissionKeys.every(state.draftKeys.contains);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: ResponsiveCenter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${role.name} · ${state.draftKeys.length} / ${state.permissions.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: loc.commonSave,
                  icon: Icons.save_outlined,
                  loading: state.savingMatrix,
                  onPressed: unchanged
                      ? null
                      : () => context.read<RbacBloc>().add(const RbacMatrixSaveRequested()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
