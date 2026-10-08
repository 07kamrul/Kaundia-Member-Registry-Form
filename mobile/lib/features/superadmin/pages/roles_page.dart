import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/rbac_repository.dart';
import '../domain/rbac_entities.dart';
import '../presentation/bloc/rbac_bloc.dart';

/// Port of the Angular RoleManagementComponent: permission matrix per role,
/// create-administrator form and per-user permission overrides. On mobile the
/// wide matrix becomes a role selector + grouped checkbox list, and the two
/// halves of the Angular page become tabs (Roles / Users).
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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: loc.adminRoleManagementTitle,
              subtitle: loc.adminRoleManagementSubtitle,
            ),
            AppTabs(
              labels: [loc.superadminTabsRoles, loc.superadminTabsUsers],
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            Expanded(
              child: BlocBuilder<RbacBloc, RbacState>(
                builder: (context, state) {
                  if (state.status == RbacStatus.initial ||
                      state.status == RbacStatus.loading) {
                    return const SkeletonLoader(lines: 8);
                  }
                  if (state.status == RbacStatus.failure) {
                    return InlineError(
                      message: _loadErrorText(loc, state.errorKind),
                      onRetry: () => context.read<RbacBloc>().add(const RbacStarted()),
                    );
                  }
                  return IndexedStack(
                    index: _tabIndex,
                    children: const [_RolesMatrixTab(), _UsersTab()],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _loadErrorText(AppLocalizations loc, RbacErrorKind? kind) => switch (kind) {
      RbacErrorKind.loadRoles => loc.adminRoleManagementErrorsLoadRolesFailed,
      RbacErrorKind.loadUsers => loc.adminRoleManagementErrorsLoadUsersFailed,
      _ => loc.adminRoleManagementErrorsLoadPermissionsFailed,
    };

String _roleLabel(AppLocalizations loc, AdminRoleName role) => switch (role) {
      AdminRoleName.administrator => loc.superadminRoleAdministrator,
      AdminRoleName.executiveCommittee => loc.superadminRoleExecutiveCommittee,
      AdminRoleName.superAdmin => loc.superadminRoleSuperAdmin,
    };

/// Tab 1: role selector + grouped checkbox permission matrix with a save bar.
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
        final role = state.selectedRole;
        final locked = role?.isSuperAdmin ?? false;
        final matchesDraft = role != null &&
            role.permissionKeys.length == state.draftKeys.length &&
            role.permissionKeys.every(state.draftKeys.contains);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (state.roles.isEmpty)
              EmptyState(message: loc.superadminRolesEmpty)
            else ...[
              DropdownButtonFormField<String>(
                initialValue: state.selectedRoleId,
                decoration: InputDecoration(
                  labelText: loc.adminRoleManagementCreateAdminRoleLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final r in state.roles) DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (value) {
                  if (value != null) bloc.add(RbacRoleSelected(value));
                },
              ),
              if (state.matrixSaveError) ...[
                const SizedBox(height: 8),
                InlineError(
                  message: loc.adminRoleManagementErrorsSaveChangeFailed,
                  onRetry: () => bloc.add(const RbacMatrixSaveRequested()),
                ),
              ],
              const SizedBox(height: 12),
              for (final group in state.permissionsByResource.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Text(group.key, style: Theme.of(context).textTheme.titleSmall),
                ),
                AppCard(
                  child: Column(
                    children: [
                      for (final permission in group.value)
                        AppCheckbox(
                          label: permission.description,
                          value: state.draftKeys.contains(permission.key),
                          onChanged: locked || state.savingMatrix
                              ? null
                              : (_) => bloc.add(RbacPermissionToggled(permission.key)),
                        ),
                    ],
                  ),
                ),
              ],
              if (locked) ...[
                const SizedBox(height: 8),
                Center(
                  child: StatusBadge(
                    kind: StatusKind.approved,
                    label: loc.adminRoleManagementAllPermissionsAlways,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: loc.commonSave,
                expanded: true,
                onPressed: locked || state.savingMatrix || role == null || matchesDraft
                    ? null
                    : () => bloc.add(const RbacMatrixSaveRequested()),
              ),
              if (state.savingMatrix)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Tab 2: create administrator + assign role + per-user permission overrides.
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<RbacBloc, RbacState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _CreateUserCard(),
            const SizedBox(height: 16),
            if (!state.hasUsers)
              EmptyState(message: loc.superadminUsersEmpty)
            else ...[
              Text(loc.adminRoleManagementUserOverridesTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                loc.adminRoleManagementUserOverridesSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _UserOverridesCard(state: state),
            ],
          ],
        );
      },
    );
  }
}

class _CreateUserCard extends StatefulWidget {
  const _CreateUserCard();

  @override
  State<_CreateUserCard> createState() => _CreateUserCardState();
}

class _CreateUserCardState extends State<_CreateUserCard> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AdminRoleName _role = AdminRoleName.administrator;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = context.watch<RbacBloc>().state;
    final bloc = context.read<RbacBloc>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.adminRoleManagementCreateAdminTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(loc.adminRoleManagementCreateAdminSubtitle,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminNameLabel,
              hintText: loc.adminRoleManagementCreateAdminNamePlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminEmailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminPasswordLabel,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AdminRoleName>(
            initialValue: _role,
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminRoleLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final r in AdminRoleName.values)
                DropdownMenuItem(value: r, child: Text(_roleLabel(loc, r))),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            label: loc.adminRoleManagementCreateAdminSubmitButton,
            expanded: true,
            onPressed: state.creatingUser
                ? null
                : () => bloc.add(RbacCreateUserSubmitted(
                      name: _name.text.trim(),
                      email: _email.text.trim(),
                      password: _password.text,
                      role: _role,
                    )),
          ),
          if (state.createUserError != null) ...[
            const SizedBox(height: 8),
            InlineError(message: loc.adminRoleManagementErrorsCreateUserFailed),
          ],
          if (state.createUserSuccess != null) ...[
            const SizedBox(height: 8),
            StatusBadge(
              kind: StatusKind.approved,
              label:
                  '${loc.adminRoleManagementCreateAdminSuccessPrefix} ${state.createUserSuccess}',
            ),
          ],
        ],
      ),
    );
  }
}

class _UserOverridesCard extends StatelessWidget {
  const _UserOverridesCard({required this.state});

  final RbacState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RbacBloc>();
    final draftKey = state.overrideDraftKey.isNotEmpty
        ? state.overrideDraftKey
        : (state.permissions.isNotEmpty ? state.permissions.first.key : '');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: state.selectedUserId,
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementUserOverridesUserLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final u in state.users)
                DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.role})')),
            ],
            onChanged: (value) {
              if (value != null) bloc.add(RbacUserSelected(value));
            },
          ),
          if (state.selectedUserId != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.roleAssignDraft,
                    decoration: InputDecoration(
                      labelText: loc.adminRoleManagementUserOverridesAssignRoleLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final r in AdminRoleName.values)
                        DropdownMenuItem(value: r.apiValue, child: Text(_roleLabel(loc, r))),
                    ],
                    onChanged: (value) => bloc.add(RbacRoleAssignDraftChanged(value ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: loc.adminRoleManagementUserOverridesSaveRoleButton,
                  onPressed: state.savingRoleAssign
                      ? null
                      : () => bloc.add(const RbacRoleAssignSubmitted()),
                ),
              ],
            ),
            if (state.roleAssignError) ...[
              const SizedBox(height: 8),
              InlineError(message: loc.adminRoleManagementErrorsAssignRoleFailed),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: draftKey.isEmpty ? null : draftKey,
                    decoration: InputDecoration(
                      labelText: loc.adminRoleManagementUserOverridesPermissionLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in state.permissions)
                        DropdownMenuItem(value: p.key, child: Text(p.description)),
                    ],
                    onChanged: (value) => bloc.add(RbacOverrideDraftChanged(
                      permissionKey: value ?? '',
                      granted: state.overrideDraftGranted,
                    )),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    initialValue: state.overrideDraftGranted,
                    decoration: InputDecoration(
                      labelText: loc.adminRoleManagementUserOverridesActionLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Text(loc.adminRoleManagementUserOverridesGrantOption),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text(loc.adminRoleManagementUserOverridesRevokeOption),
                      ),
                    ],
                    onChanged: (value) => bloc.add(RbacOverrideDraftChanged(
                      permissionKey: draftKey,
                      granted: value ?? true,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: loc.adminRoleManagementUserOverridesApplyButton,
              onPressed: state.savingOverrides || draftKey.isEmpty
                  ? null
                  : () => bloc.add(RbacOverrideApplied(
                        permissionKey: draftKey,
                        granted: state.overrideDraftGranted,
                      )),
            ),
            if (state.overridesError) ...[
              const SizedBox(height: 8),
              InlineError(
                message: loc.adminRoleManagementErrorsSaveOverridesFailed,
                onRetry: () => bloc.add(RbacUserSelected(state.selectedUserId!)),
              ),
            ],
            if (state.overridesStatus == OverridesStatus.failure) ...[
              const SizedBox(height: 8),
              InlineError(
                message: loc.adminRoleManagementErrorsLoadOverridesFailed,
                onRetry: () => bloc.add(RbacUserSelected(state.selectedUserId!)),
              ),
            ],
            const SizedBox(height: 8),
            if (state.overridesStatus == OverridesStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SkeletonLoader(lines: 2),
              )
            else if (state.overridesStatus != OverridesStatus.failure && state.overrides.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.adminRoleManagementUserOverridesNoOverrides,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else if (state.overridesStatus != OverridesStatus.failure)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in state.overrides)
                    InputChip(
                      avatar: Icon(
                        o.granted ? Icons.add : Icons.remove,
                        size: 16,
                        color: o.granted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      label: Text(_permissionLabel(state, o.permissionKey)),
                      onDeleted: state.savingOverrides
                          ? null
                          : () => bloc.add(RbacOverrideRemoved(o.permissionKey)),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String _permissionLabel(RbacState state, String key) {
    for (final p in state.permissions) {
      if (p.key == key) return p.description;
    }
    return key;
  }
}
