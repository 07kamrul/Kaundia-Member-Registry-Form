import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../presentation/bloc/installments_mgmt_bloc.dart';
import '../presentation/widgets/installments_management_widgets.dart';
import '../presentation/widgets/management_widgets.dart';

String monthLabelOf(AppLocalizations loc, int month) => switch (month) {
      1 => loc.commonMonthsJanuary,
      2 => loc.commonMonthsFebruary,
      3 => loc.commonMonthsMarch,
      4 => loc.commonMonthsApril,
      5 => loc.commonMonthsMay,
      6 => loc.commonMonthsJune,
      7 => loc.commonMonthsJuly,
      8 => loc.commonMonthsAugust,
      9 => loc.commonMonthsSeptember,
      10 => loc.commonMonthsOctober,
      11 => loc.commonMonthsNovember,
      12 => loc.commonMonthsDecember,
      _ => '$month',
    };

/// Installments management (Angular installments-management): member list on
/// the left, month cards with "mark paid" (PATCH /admin/installments/{id}).
class InstallmentsManagementPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const InstallmentsManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final canManage =
        sl<SessionManager>().session?.can('member.manage') ?? false;
    return BlocProvider(
      create: (_) => InstallmentsMgmtBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..add(const InstallmentsMembersLoadRequested()),
      child: _InstallmentsView(canManage: canManage),
    );
  }
}

class _InstallmentsView extends StatelessWidget {
  const _InstallmentsView({required this.canManage});

  /// Content width from which the member list sits beside the months.
  static const double _masterDetailMinWidth = 840;
  static const double _masterPaneWidth = 300;

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<InstallmentsMgmtBloc, InstallmentsMgmtState>(
      listener: (context, state) {
        // Load failures render inline; toast mark-paid failures.
        if (state.error != null && state.installments.isNotEmpty) {
          showAppToast(context, describeApiError(context, state.error),
              error: true);
        }
      },
      builder: (context, state) {
        final bloc = context.read<InstallmentsMgmtBloc>();
        return PageBody(
          onRefresh: () => _refresh(bloc),
          children: [
            PageHeader(
              icon: Icons.calendar_month_outlined,
              title: loc.adminInstallmentsTitle,
              subtitle: loc.adminInstallmentsSubtitle,
            ),
            if (!canManage)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pageGutter, vertical: 4),
                child: ManagementCallout(
                  message: loc.adminInstallmentsPermissionRequired,
                  icon: Icons.lock_outline,
                ),
              ),
            ..._content(context, loc, bloc, state),
          ],
        );
      },
    );
  }

  Future<void> _refresh(InstallmentsMgmtBloc bloc) {
    final selected = bloc.state.selectedMemberId;
    if (selected == null) {
      return reloadAndWait(bloc, const InstallmentsMembersLoadRequested(),
          (s) => s.loadingMembers);
    }
    return reloadAndWait(bloc, InstallmentsMemberSelected(memberId: selected),
        (s) => s.loadingInstallments);
  }

  List<Widget> _content(BuildContext context, AppLocalizations loc,
      InstallmentsMgmtBloc bloc, InstallmentsMgmtState state) {
    if (state.loadingMembers) return const [SkeletonLoader(lines: 4)];
    if (state.members.isEmpty && state.error != null) {
      return [
        InlineError(
          message: loc.adminInstallmentsErrorsLoadMembersFailed,
          onRetry: () => bloc.add(const InstallmentsMembersLoadRequested()),
        ),
      ];
    }
    if (state.members.isEmpty) {
      return [
        EmptyState(
            message: loc.adminInstallmentsNoMembers,
            icon: Icons.group_off_outlined),
      ];
    }
    void select(String id) => bloc.add(InstallmentsMemberSelected(memberId: id));
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < _masterDetailMinWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InstallmentsMemberDropdown(
                    members: state.members,
                    selectedId: state.selectedMemberId,
                    onSelected: select,
                  ),
                  const SizedBox(height: 8),
                  _SelectedMemberPanel(
                      bloc: bloc, state: state, canManage: canManage),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _masterPaneWidth,
                  child: InstallmentsMemberList(
                    members: state.members,
                    selectedId: state.selectedMemberId,
                    onSelected: select,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SelectedMemberPanel(
                      bloc: bloc, state: state, canManage: canManage),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }
}

/// Selected member heading, paid/due summary and the month grid.
class _SelectedMemberPanel extends StatelessWidget {
  const _SelectedMemberPanel({
    required this.bloc,
    required this.state,
    required this.canManage,
  });

  final InstallmentsMgmtBloc bloc;
  final InstallmentsMgmtState state;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final selected = bloc.selectedMember;
    if (selected == null) {
      return EmptyState(
          message: loc.adminInstallmentsSelectMember,
          icon: Icons.person_search_outlined);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ManagementAvatar(name: selected.fullName),
          title: Text(selected.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(selected.memberId ?? '—'),
        ),
        ..._installments(context, loc),
      ],
    );
  }

  List<Widget> _installments(BuildContext context, AppLocalizations loc) {
    if (state.loadingInstallments) {
      return const [SkeletonLoader(lines: 3)];
    }
    final memberId = state.selectedMemberId;
    if (state.installments.isEmpty && state.error != null && memberId != null) {
      return [
        InlineError(
          message: loc.adminInstallmentsErrorsLoadInstallmentsFailed,
          onRetry: () => bloc.add(InstallmentsMemberSelected(memberId: memberId)),
        ),
      ];
    }
    if (state.installments.isEmpty) {
      return [
        EmptyState(
            message: loc.adminInstallmentsNoInstallments,
            icon: Icons.event_busy_outlined),
      ];
    }
    return [
      InstallmentsSummary(installments: state.installments),
      ResponsiveGrid(
        minItemWidth: 132,
        maxColumns: 6,
        children: [
          for (final i in state.installments)
            InstallmentMonthCard(
              label: '${monthLabelOf(loc, i.month)} ${i.year}',
              installment: i,
              canManage: canManage,
              busy: state.markingId == i.id,
              onMarkPaid: () => bloc.add(InstallmentMarkPaid(installment: i)),
            ),
        ],
      ),
    ];
  }
}
