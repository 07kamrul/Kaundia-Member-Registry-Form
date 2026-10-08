import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../data/payment_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/installments_bloc.dart';
import '../presentation/widgets/pay_dues_dialog.dart';

/// Port of Angular InstallmentsComponent: installment history with year filter,
/// summary cards, online pay banner + three-step pay-dues dialog, payment
/// history.
class InstallmentsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const InstallmentsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InstallmentsBloc(
        memberRepository: MemberRepository(apiClient: sl<ApiClient>()),
        paymentRepository: MemberPaymentRepository(apiClient: sl<ApiClient>()),
      )..add(const InstallmentsLoaded()),
      child: const _InstallmentsView(),
    );
  }
}

class _InstallmentsView extends StatelessWidget {
  const _InstallmentsView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<InstallmentsBloc, InstallmentsState>(
        listener: (context, state) {
          if (state.successMessage) {
            showAppToast(context, loc.memberPayDuesSubmitted);
            context.read<InstallmentsBloc>().add(const InstallmentsMessageCleared());
          }
          final err = state.submitError;
          if (err != null) {
            showAppToast(
              context,
              switch (err) {
                'submitError' => loc.memberPayDuesSubmitError,
                'proofSizeError' => loc.memberPayDuesProofSizeError,
                _ => err,
              },
              error: true,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<InstallmentsBloc>();
          final body = switch (state.status) {
            InstallmentsStatus.loading => const SkeletonLoader(lines: 6),
            InstallmentsStatus.failure => InlineError(
                message: loc.memberInstallmentsLoadError,
                onRetry: () => bloc.add(const InstallmentsLoaded()),
              ),
            InstallmentsStatus.loaded => _loaded(context, state, loc, bloc),
          };
          return Stack(
            children: [
              body,
              if (state.payDialogOpen && state.payable != null)
                PayDuesDialog(summary: state.payable!),
            ],
          );
        },
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    InstallmentsState state,
    AppLocalizations loc,
    InstallmentsBloc bloc,
  ) {
    final rows = state.sorted;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
          title: loc.memberInstallmentsTitle,
          subtitle: loc.memberInstallmentsSubtitle,
        ),
        if (state.canPay)
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.memberPayDuesBannerTitle(state.payableCount),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '৳ ${_grouped(state.payable!.totalDue)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: loc.memberPayDuesPayNow,
                  icon: Icons.payments_outlined,
                  onPressed: () => bloc.add(const PayDuesDialogOpened()),
                ),
              ],
            ),
          ),
        AppCard(
          child: Row(
            children: [
              _stat(context, loc.memberInstallmentsSummaryPaid, '৳ ${_grouped(state.paidTotal)}'),
              _stat(context, loc.memberInstallmentsSummaryDue, '৳ ${_grouped(state.dueTotal)}'),
              _stat(context, loc.memberInstallmentsSummaryPayments,
                  '${state.paidCount} / ${state.filtered.length}'),
            ],
          ),
        ),
        if (state.years.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                _yearChip(context, loc.memberInstallmentsFilterAll, state.selectedYear == null,
                    () => bloc.add(const InstallmentsYearFilterChanged(null))),
                for (final y in state.years)
                  _yearChip(context, '$y', state.selectedYear == y,
                      () => bloc.add(InstallmentsYearFilterChanged(y))),
              ],
            ),
          ),
        if (rows.isEmpty)
          EmptyState(
            message: state.installments.isEmpty
                ? loc.memberInstallmentsEmptyState
                : loc.memberInstallmentsEmptyFiltered,
            icon: Icons.account_balance_wallet_outlined,
          )
        else
          for (final i in rows)
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${monthLabel(i.month, loc)} - ${i.year}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '৳ ${_grouped(i.amount)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (i.paidAt != null)
                          Text(i.paidAt!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (!i.isPaid && state.isPending(i.id))
                    StatusBadge(kind: StatusKind.pending, label: loc.memberPayDuesStatusPending)
                  else
                    StatusBadge(
                      kind: i.isPaid ? StatusKind.approved : StatusKind.rejected,
                      label: i.isPaid
                          ? loc.memberInstallmentsStatusPaid
                          : loc.memberInstallmentsStatusDue,
                    ),
                ],
              ),
            ),
        if (state.payable != null && state.payable!.payments.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(loc.memberPayDuesHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final p in state.payable!.payments.take(5))
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.installments
                        .map((i) => '${monthLabel(i.month, loc)} ${i.year}')
                        .join(', '),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('${p.method} · ${p.transactionRef} · ${p.paidOn}',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (p.status == SubmissionStatus.rejected && p.rejectionReason != null)
                    Text(
                      '${loc.memberPayDuesRejectedReason}: ${p.rejectionReason}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text('৳ ${_grouped(p.amount)}')),
                      _paymentBadge(context, p.status, loc),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              state.canPay ? loc.memberPayDuesNotice : loc.memberInstallmentsPaymentNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _yearChip(BuildContext context, String label, bool active, VoidCallback onTap) {
    return ChoiceChip(label: Text(label), selected: active, onSelected: (_) => onTap());
  }

  Widget _paymentBadge(BuildContext context, SubmissionStatus status, AppLocalizations loc) {
    final (kind, label) = switch (status) {
      SubmissionStatus.approved => (StatusKind.approved, loc.memberPayDuesPaymentStatusApproved),
      SubmissionStatus.pending => (StatusKind.pending, loc.memberPayDuesPaymentStatusPending),
      SubmissionStatus.rejected => (StatusKind.rejected, loc.memberPayDuesPaymentStatusRejected),
      SubmissionStatus.unknown => (StatusKind.neutral, loc.commonNoData),
    };
    return StatusBadge(kind: kind, label: label);
  }
}

String _grouped(num value) => NumberFormatLike.enInGrouped(value.round());
