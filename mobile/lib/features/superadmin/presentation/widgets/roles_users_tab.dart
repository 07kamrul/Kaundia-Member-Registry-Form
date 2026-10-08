import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/rbac_entities.dart';
import '../bloc/rbac_bloc.dart';

/// Users tab of the roles page (create administrator, role assignment and
/// per-user permission overrides) plus helpers shared with the roles tab.

const Duration _rbacRefreshTimeout = Duration(seconds: 20);

bool isRbacLoading(RbacState s) =>
    s.status == RbacStatus.initial || s.status == RbacStatus.loading;

/// Pull-to-refresh: reloads everything and waits for the bloc to settle.
Future<void> refreshRbac(RbacBloc bloc) async {
  final done = bloc.stream.firstWhere((s) => !isRbacLoading(s)).timeout(_rbacRefreshTimeout);
  bloc.add(const RbacStarted());
  try {
    await done;
  } on TimeoutException {
    // Slow network: stop the spinner; the page shows the bloc's outcome.
  } on StateError {
    // Bloc closed (page left) before the reload finished.
  }
}

String adminRoleLabel(AppLocalizations loc, AdminRoleName role) => switch (role) {
      AdminRoleName.administrator => loc.superadminRoleAdministrator,
      AdminRoleName.executiveCommittee => loc.superadminRoleExecutiveCommittee,
      AdminRoleName.superAdmin => loc.superadminRoleSuperAdmin,
    };

/// Tab 2: create administrator + assign role + per-user permission overrides.
class RolesUsersTab extends StatelessWidget {
  const RolesUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RbacBloc>();
    return BlocBuilder<RbacBloc, RbacState>(
      builder: (context, state) {
        final overrides = state.hasUsers
            ? _UserOverridesCard(state: state)
            : EmptyState(icon: Icons.group_outlined, message: loc.superadminUsersEmpty);
        return PageBody(
          onRefresh: () => refreshRbac(bloc),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pageGutter, 12, context.pageGutter, 0),
              child: ResponsiveGrid(
                minItemWidth: 420,
                maxColumns: 2,
                children: [const _CreateUserCard(), overrides],
              ),
            ),
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
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _CardHeading(
            icon: Icons.person_add_alt_1_outlined,
            title: loc.adminRoleManagementCreateAdminTitle,
            subtitle: loc.adminRoleManagementCreateAdminSubtitle,
          ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminNameLabel,
              hintText: loc.adminRoleManagementCreateAdminNamePlaceholder,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminEmailLabel,
              prefixIcon: const Icon(Icons.alternate_email),
            ),
          ),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementCreateAdminPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscure ? loc.authLoginShowPassword : loc.authLoginHidePassword,
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          _roleDropdown(loc),
          AppButton(
            label: loc.adminRoleManagementCreateAdminSubmitButton,
            icon: Icons.person_add_alt_1_outlined,
            expanded: true,
            loading: state.creatingUser,
            onPressed: () => context.read<RbacBloc>().add(RbacCreateUserSubmitted(
                  name: _name.text.trim(),
                  email: _email.text.trim(),
                  password: _password.text,
                  role: _role,
                )),
          ),
          if (state.createUserError != null)
            InlineError(message: loc.adminRoleManagementErrorsCreateUserFailed),
          if (state.createUserSuccess != null)
            StatusBadge(
              kind: StatusKind.approved,
              label:
                  '${loc.adminRoleManagementCreateAdminSuccessPrefix} ${state.createUserSuccess}',
            ),
        ],
      ),
    );
  }

  Widget _roleDropdown(AppLocalizations loc) {
    return DropdownButtonFormField<AdminRoleName>(
      initialValue: _role,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: loc.adminRoleManagementCreateAdminRoleLabel,
        prefixIcon: const Icon(Icons.badge_outlined),
      ),
      items: [
        for (final r in AdminRoleName.values)
          DropdownMenuItem(value: r, child: Text(adminRoleLabel(loc, r))),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _role = value);
      },
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _CardHeading(
            icon: Icons.tune_rounded,
            title: loc.adminRoleManagementUserOverridesTitle,
            subtitle: loc.adminRoleManagementUserOverridesSubtitle,
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(state.selectedUserId),
            initialValue: state.users.any((u) => u.id == state.selectedUserId)
                ? state.selectedUserId
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.adminRoleManagementUserOverridesUserLabel,
              prefixIcon: const Icon(Icons.person_search_outlined),
            ),
            items: [
              for (final u in state.users)
                DropdownMenuItem(
                  value: u.id,
                  child: Text('${u.name} (${u.role})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) bloc.add(RbacUserSelected(value));
            },
          ),
          if (state.selectedUserId != null) ...[
            _RoleAssignRow(state: state),
            if (state.roleAssignError)
              InlineError(message: loc.adminRoleManagementErrorsAssignRoleFailed),
            const Divider(height: 8),
            _OverrideEditor(state: state),
            _OverrideChips(state: state),
          ],
        ],
      ),
    );
  }
}

class _RoleAssignRow extends StatelessWidget {
  const _RoleAssignRow({required this.state});

  final RbacState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RbacBloc>();
    final draft = AdminRoleName.values.any((r) => r.apiValue == state.roleAssignDraft)
        ? state.roleAssignDraft
        : null;
    final dropdown = DropdownButtonFormField<String>(
      key: ValueKey('${state.selectedUserId}-$draft'),
      initialValue: draft,
      isExpanded: true,
      decoration: InputDecoration(labelText: loc.adminRoleManagementUserOverridesAssignRoleLabel),
      items: [
        for (final r in AdminRoleName.values)
          DropdownMenuItem(value: r.apiValue, child: Text(adminRoleLabel(loc, r))),
      ],
      onChanged: (value) => bloc.add(RbacRoleAssignDraftChanged(value ?? '')),
    );
    final button = AppButton(
      label: loc.adminRoleManagementUserOverridesSaveRoleButton,
      variant: AppButtonVariant.secondary,
      loading: state.savingRoleAssign,
      onPressed: () => bloc.add(const RbacRoleAssignSubmitted()),
    );
    return _FieldWithAction(field: dropdown, action: button);
  }
}

/// Field + trailing button side by side, stacked when narrow.
class _FieldWithAction extends StatelessWidget {
  const _FieldWithAction({required this.field, required this.action});

  final Widget field;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [field, action],
          );
        }
        return Row(
          spacing: 8,
          children: [Expanded(child: field), action],
        );
      },
    );
  }
}

class _OverrideEditor extends StatelessWidget {
  const _OverrideEditor({required this.state});

  final RbacState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RbacBloc>();
    final draftKey = state.overrideDraftKey.isNotEmpty
        ? state.overrideDraftKey
        : (state.permissions.isNotEmpty ? state.permissions.first.key : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(draftKey),
          initialValue: state.permissions.any((p) => p.key == draftKey) ? draftKey : null,
          isExpanded: true,
          decoration:
              InputDecoration(labelText: loc.adminRoleManagementUserOverridesPermissionLabel),
          items: [
            for (final p in state.permissions)
              DropdownMenuItem(
                value: p.key,
                child: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => bloc.add(RbacOverrideDraftChanged(
            permissionKey: value ?? '',
            granted: state.overrideDraftGranted,
          )),
        ),
        _FieldWithAction(
          field: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (granted, label, icon) in [
                (true, loc.adminRoleManagementUserOverridesGrantOption, Icons.add),
                (false, loc.adminRoleManagementUserOverridesRevokeOption, Icons.remove),
              ])
                ChoiceChip(
                  avatar: Icon(icon, size: 16),
                  showCheckmark: false,
                  label: Text(label),
                  selected: state.overrideDraftGranted == granted,
                  onSelected: (_) => bloc.add(RbacOverrideDraftChanged(
                      permissionKey: draftKey, granted: granted)),
                ),
            ],
          ),
          action: AppButton(
            label: loc.adminRoleManagementUserOverridesApplyButton,
            loading: state.savingOverrides,
            onPressed: draftKey.isEmpty
                ? null
                : () => bloc.add(RbacOverrideApplied(
                      permissionKey: draftKey,
                      granted: state.overrideDraftGranted,
                    )),
          ),
        ),
        if (state.overridesError)
          InlineError(
            message: loc.adminRoleManagementErrorsSaveOverridesFailed,
            onRetry: () => bloc.add(RbacUserSelected(state.selectedUserId!)),
          ),
      ],
    );
  }
}

class _OverrideChips extends StatelessWidget {
  const _OverrideChips({required this.state});

  final RbacState state;

  String _permissionLabel(String key) {
    for (final p in state.permissions) {
      if (p.key == key) return p.description;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RbacBloc>();
    final scheme = Theme.of(context).colorScheme;
    switch (state.overridesStatus) {
      case OverridesStatus.failure:
        return InlineError(
          message: loc.adminRoleManagementErrorsLoadOverridesFailed,
          onRetry: () => bloc.add(RbacUserSelected(state.selectedUserId!)),
        );
      case OverridesStatus.loading:
        return const LinearProgressIndicator();
      case OverridesStatus.initial:
      case OverridesStatus.ready:
        break;
    }
    if (state.overrides.isEmpty) {
      return Text(
        loc.adminRoleManagementUserOverridesNoOverrides,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in state.overrides)
          InputChip(
            avatar: Icon(
              o.granted ? Icons.add : Icons.remove,
              size: 16,
              color: o.granted ? scheme.primary : scheme.error,
            ),
            label: Text(_permissionLabel(o.permissionKey), overflow: TextOverflow.ellipsis),
            deleteButtonTooltipMessage: MaterialLocalizations.of(context).deleteButtonTooltip,
            onDeleted: state.savingOverrides
                ? null
                : () => bloc.add(RbacOverrideRemoved(o.permissionKey)),
          ),
      ],
    );
  }
}
