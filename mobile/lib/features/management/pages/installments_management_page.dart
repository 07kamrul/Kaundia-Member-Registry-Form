import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/installments_mgmt_bloc.dart';
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
class InstallmentsManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const InstallmentsManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<InstallmentsManagementPage> createState() =>
      _InstallmentsManagementPageState();
}

class _InstallmentsManagementPageState
    extends State<InstallmentsManagementPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final canManage =
        sl<SessionManager>().session?.can('member.manage') ?? false;
    return BlocProvider(
      create: (_) => InstallmentsMgmtBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..loadMembers(),
      child: BlocConsumer<InstallmentsMgmtBloc, InstallmentsMgmtState>(
        listener: (context, state) {
          if (state.error != null) {
            showAppToast(context, describeApiError(context, state.error),
                error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<InstallmentsMgmtBloc>();
          final selected = bloc.selectedMember;
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminInstallmentsTitle,
                  subtitle: loc.adminInstallmentsSubtitle),
              if (state.loadingMembers)
                const SkeletonLoader(lines: 4)
              else if (state.members.isEmpty)
                EmptyState(message: loc.adminInstallmentsNoMembers)
              else ...[
                // Member picker (master list).
                SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.members.length,
                    itemBuilder: (context, index) {
                      final m = state.members[index];
                      final active = m.id == state.selectedMemberId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(m.fullName),
                          selected: active,
                          onSelected: (_) => bloc.add(InstallmentsMemberSelected(memberId: m.id)),
                        ),
                      );
                    },
                  ),
                ),
                if (selected != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      '${selected.fullName} · ${selected.memberId ?? ''}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
                if (state.loadingInstallments)
                  const SkeletonLoader(lines: 3)
                else if (state.installments.isEmpty)
                  EmptyState(message: loc.adminInstallmentsNoInstallments)
                else
                  Wrap(
                    children: [
                      for (final i in state.installments)
                        _MonthCard(
                          installment: i,
                          loc: loc,
                          canManage: canManage,
                          busy: state.markingId == i.id,
                          onMarkPaid: () => bloc.add(InstallmentMarkPaid(installment: i)),
                        ),
                    ],
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.installment,
    required this.loc,
    required this.canManage,
    required this.busy,
    required this.onMarkPaid,
  });

  final Installment installment;
  final AppLocalizations loc;
  final bool canManage;
  final bool busy;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${monthLabelOf(loc, installment.month)} ${installment.year}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                formatTaka(installment.amount, decimals: 0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (installment.isPaid)
                StatusBadge(
                    kind: StatusKind.approved, label: loc.adminInstallmentsPaid)
              else
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: loc.adminInstallmentsMarkPaidButton,
                    onPressed: canManage && !busy ? onMarkPaid : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
