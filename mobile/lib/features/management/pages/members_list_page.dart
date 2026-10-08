import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/enums/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/members_cubit.dart';
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
    final loc = AppLocalizations.of(context);
    final canManage =
        sl<SessionManager>().session?.can('member.manage') ?? false;
    return BlocProvider(
      create: (_) =>
          MembersCubit(repository: AdminRepository(apiClient: sl<ApiClient>()))
            ..load(),
      child: BlocConsumer<MembersCubit, MembersState>(
        listener: (context, state) {
          if (state.error != null) {
            showAppToast(context, describeApiError(context, state.error),
                error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<MembersCubit>();
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminMembersListTitle,
                  subtitle: loc.adminMembersListSubtitle),
              if (state.loading)
                const SkeletonLoader(lines: 6)
              else if (state.items.isEmpty && state.error == null)
                EmptyState(message: loc.adminMembersListNoMembers)
              else
                AppDataTableCards<Member>(
                  items: state.items,
                  rowBuilder: (context, m) =>
                      _row(context, loc, cubit, m, canManage, state),
                  onRowTap: (m) => context.go('/members/${m.id}'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations loc, MembersCubit cubit,
      Member m, bool canManage, MembersState state) {
    final contribution = m.status != SubmissionStatus.approved
        ? '—'
        : m.dueInstallments > 0
            ? '${m.dueInstallments} ${loc.adminMembersListMonthsOverdue}'
            : loc.adminMembersListFullyPaid;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(
                  kind: switch (m.status) {
                    SubmissionStatus.pending => StatusKind.pending,
                    SubmissionStatus.approved => StatusKind.approved,
                    SubmissionStatus.rejected => StatusKind.rejected,
                    _ => StatusKind.neutral,
                  },
                  label: statusLabel(loc, m.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(
                label: loc.adminMembersListTableHeadersMemberId,
                value: m.memberId ?? '—'),
            InfoRow(
                label: loc.adminMembersListTableHeadersMobile, value: m.mobile),
            InfoRow(
                label: loc.adminMembersListTableHeadersContributionStatus,
                value: contribution),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: loc.adminMembersListViewDetailsTitle,
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => context.go('/members/${m.id}'),
                ),
                if (canManage && m.status == SubmissionStatus.approved) ...[
                  IconButton(
                    tooltip: loc.adminMembersListResetPasswordTitle,
                    icon: const Icon(Icons.key_outlined),
                    onPressed: state.busyId == m.id
                        ? null
                        : () async {
                            final confirmed = await confirmDialog(
                              context,
                              title: loc.adminMembersListResetModalTitle,
                              message:
                                  '${m.fullName} ${loc.adminMembersListResetModalMessageSuffix}',
                              confirmLabel:
                                  loc.adminMembersListResetModalConfirmLabel,
                            );
                            if (confirmed && context.mounted) {
                              final sent = await cubit.resetPassword(m.id);
                              if (context.mounted) {
                                showAppToast(
                                  context,
                                  sent
                                      ? loc
                                          .adminMembersListResetModalSuccessMessage(
                                              m.fullName)
                                      : loc
                                          .adminMembersListResetModalSuccessNoEmail,
                                );
                              }
                            }
                          },
                  ),
                  IconButton(
                    tooltip: loc.adminMembersListDeleteMemberTitle,
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: state.busyId == m.id
                        ? null
                        : () async {
                            final confirmed = await confirmDialog(
                              context,
                              title: loc.adminMembersListDeleteModalTitle,
                              message:
                                  '${m.fullName} ${loc.adminMembersListDeleteModalMessageSuffix}',
                              confirmLabel:
                                  loc.adminMembersListDeleteModalConfirmLabel,
                              destructive: true,
                            );
                            if (confirmed && context.mounted)
                              await cubit.delete(m.id);
                          },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
