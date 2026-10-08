import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/enums/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/members_bloc.dart';
import '../presentation/widgets/management_widgets.dart';
import 'submissions_list_page.dart';

/// All members (Angular members-list): list-cards with ID / name / mobile /
/// status / চাঁদার অবস্থা, eye -> read-only detail, delete with confirm.
class MembersListPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const MembersListPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final canManage =
        sl<SessionManager>().session?.can('member.manage') ?? false;
    return BlocProvider(
      create: (_) =>
          MembersBloc(repository: AdminRepository(apiClient: sl<ApiClient>()))
            ..add(const MembersLoadRequested()),
      child: _MembersView(canManage: canManage),
    );
  }
}

class _MembersView extends StatelessWidget {
  const _MembersView({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<MembersBloc, MembersState>(
      listener: (context, state) {
        // Load failures render inline; toast action failures on a loaded list.
        if (state.error != null && state.items.isNotEmpty) {
          showAppToast(context, describeApiError(context, state.error),
              error: true);
        }
      },
      builder: (context, state) {
        final bloc = context.read<MembersBloc>();
        return PageBody(
          onRefresh: () => reloadAndWait(
              bloc, const MembersLoadRequested(), (s) => s.loading),
          children: [
            PageHeader(
              icon: Icons.groups_outlined,
              title: loc.adminMembersListTitle,
              subtitle: loc.adminMembersListSubtitle,
            ),
            ..._content(context, loc, bloc, state),
          ],
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, AppLocalizations loc,
      MembersBloc bloc, MembersState state) {
    if (state.loading) return const [SkeletonLoader(lines: 6, height: 96)];
    if (state.items.isEmpty && state.error != null) {
      return [
        InlineError(
          message: loc.adminMembersListErrorsLoadFailed,
          onRetry: () => bloc.add(const MembersLoadRequested()),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        EmptyState(
            message: loc.adminMembersListNoMembers,
            icon: Icons.group_off_outlined),
      ];
    }
    return [
      _MembersSummary(items: state.items),
      ManagementRecordGrid(
        children: [
          for (final m in state.items)
            _MemberCard(
              member: m,
              canManage: canManage,
              busy: state.busyId == m.id,
            ),
        ],
      ),
    ];
  }
}

class _MembersSummary extends StatelessWidget {
  const _MembersSummary({required this.items});

  final List<Member> items;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    int count(SubmissionStatus s) => items.where((m) => m.status == s).length;
    return ManagementStatSummary(
      stats: [
        ManagementStat(
          label: loc.adminMembersListTitle,
          value: '${items.length}',
          icon: Icons.groups_outlined,
        ),
        ManagementStat(
          label: loc.adminStatusLabelsApproved,
          value: '${count(SubmissionStatus.approved)}',
          icon: Icons.verified_outlined,
          accent: AppColors.emerald600,
        ),
        ManagementStat(
          label: loc.adminStatusLabelsPending,
          value: '${count(SubmissionStatus.pending)}',
          icon: Icons.hourglass_top_outlined,
          accent: AppColors.goldStrong,
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.canManage,
    required this.busy,
  });

  final Member member;
  final bool canManage;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final m = member;
    final approved = m.status == SubmissionStatus.approved;
    final overdue = approved && m.dueInstallments > 0;
    void open() => context.go('/members/${m.id}');
    return ManagementRecordCard(
      leading: ManagementAvatar(name: m.fullName),
      title: m.fullName,
      subtitle: m.memberId ?? '—',
      badge: StatusBadge(
        kind: submissionStatusKind(m.status),
        label: statusLabel(loc, m.status),
      ),
      onTap: open,
      actions: [
        if (busy)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        IconButton(
          tooltip: loc.adminMembersListViewDetailsTitle,
          icon: const Icon(Icons.visibility_outlined),
          onPressed: open,
        ),
        if (canManage && approved) ...[
          IconButton(
            tooltip: loc.adminMembersListResetPasswordTitle,
            icon: const Icon(Icons.key_outlined),
            onPressed: busy ? null : () => _resetPassword(context, loc),
          ),
          IconButton(
            tooltip: loc.adminMembersListDeleteMemberTitle,
            icon: Icon(Icons.delete_outline,
                color: busy ? null : Theme.of(context).colorScheme.error),
            onPressed: busy ? null : () => _delete(context, loc),
          ),
        ],
      ],
      children: [
        InfoRow(label: loc.adminMembersListTableHeadersMobile, value: m.mobile),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(loc.adminMembersListTableHeadersContributionStatus,
                  style: Theme.of(context).textTheme.bodySmall),
              if (!approved)
                const Text('—')
              else
                StatusBadge(
                  kind: overdue ? StatusKind.pending : StatusKind.approved,
                  label: overdue
                      ? '${m.dueInstallments} ${loc.adminMembersListMonthsOverdue}'
                      : loc.adminMembersListFullyPaid,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resetPassword(BuildContext context, AppLocalizations loc) async {
    final bloc = context.read<MembersBloc>();
    final m = member;
    final confirmed = await confirmDialog(
      context,
      title: loc.adminMembersListResetModalTitle,
      message: '${m.fullName} ${loc.adminMembersListResetModalMessageSuffix}',
      confirmLabel: loc.adminMembersListResetModalConfirmLabel,
    );
    if (!confirmed || !context.mounted) return;
    final sent = await dispatchForBool(
        bloc, (c) => MemberPasswordResetRequested(m.id, completer: c));
    if (!context.mounted) return;
    showAppToast(
      context,
      sent
          ? loc.adminMembersListResetModalSuccessMessage(m.fullName)
          : loc.adminMembersListResetModalSuccessNoEmail,
    );
  }

  Future<void> _delete(BuildContext context, AppLocalizations loc) async {
    final bloc = context.read<MembersBloc>();
    final m = member;
    final confirmed = await confirmDialog(
      context,
      title: loc.adminMembersListDeleteModalTitle,
      message: '${m.fullName} ${loc.adminMembersListDeleteModalMessageSuffix}',
      confirmLabel: loc.adminMembersListDeleteModalConfirmLabel,
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await dispatchForBool(bloc, (c) => MemberDeleted(m.id, completer: c));
    }
  }
}
