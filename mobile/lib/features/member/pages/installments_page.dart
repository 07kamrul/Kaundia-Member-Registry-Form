import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../data/payment_repository.dart';
import '../domain/finance_entities.dart';
import '../domain/member_entities.dart';
import '../domain/payment_entities.dart';
import '../presentation/bloc/installments_bloc.dart';
import '../presentation/widgets/member_ui.dart';
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
          final hasData = state.installments.isNotEmpty;
          final body = switch (state.status) {
            InstallmentsStatus.loading when !hasData => const SkeletonLoader(lines: 6),
            InstallmentsStatus.failure => InlineError(
                message: loc.memberInstallmentsLoadError,
                onRetry: () => bloc.add(const InstallmentsLoaded()),
              ),
            _ => _loaded(context, state, loc, bloc),
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
    final payments = state.payable?.payments ?? const <InstallmentPayment>[];
    return PageBody(
      onRefresh: () => reloadAndWait<InstallmentsState>(
        bloc,
        () => bloc.add(const InstallmentsLoaded()),
        (s) => s.status != InstallmentsStatus.loading,
      ),
      children: [
        PageHeader(
          title: loc.memberInstallmentsTitle,
          subtitle: loc.memberInstallmentsSubtitle,
          icon: Icons.calendar_month_outlined,
        ),
        if (state.canPay)
          _PayBanner(
            title: loc.memberPayDuesBannerTitle(state.payableCount),
            amount: '৳ ${_grouped(state.payable!.totalDue)}',
            onPay: () => bloc.add(const PayDuesDialogOpened()),
          ),
        Gutter(vertical: 6, child: _SummaryTiles(state: state)),
        if (state.years.length > 1) _YearFilter(state: state, bloc: bloc),
        if (rows.isEmpty)
          EmptyState(
            message: state.installments.isEmpty
                ? loc.memberInstallmentsEmptyState
                : loc.memberInstallmentsEmptyFiltered,
            icon: Icons.account_balance_wallet_outlined,
          )
        else
          Gutter(
            vertical: 6,
            child: ResponsiveGrid(
              minItemWidth: 300,
              maxColumns: 3,
              children: [
                for (final i in rows)
                  _InstallmentCard(installment: i, pending: !i.isPaid && state.isPending(i.id)),
              ],
            ),
          ),
        if (payments.isNotEmpty) ...[
          SectionTitle(loc.memberPayDuesHistoryTitle),
          Gutter(
            child: ResponsiveGrid(
              minItemWidth: 320,
              maxColumns: 2,
              children: [for (final p in payments.take(5)) _PaymentCard(payment: p)],
            ),
          ),
        ],
        const SizedBox(height: 8),
        NoticeBanner(
          message: state.canPay ? loc.memberPayDuesNotice : loc.memberInstallmentsPaymentNotice,
        ),
      ],
    );
  }
}

class _PayBanner extends StatelessWidget {
  const _PayBanner({required this.title, required this.amount, required this.onPay});

  final String title;
  final String amount;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final info = Row(
      children: [
        const LeadingIcon(icon: Icons.notifications_active_outlined, color: AppColors.gold, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final button = AppButton(
      label: loc.memberPayDuesPayNow,
      icon: Icons.payments_outlined,
      onPressed: onPay,
    );
    return Card(
      margin: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) => c.maxWidth < 440
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [info, const SizedBox(height: 12), button],
                )
              : Row(children: [Expanded(child: info), const SizedBox(width: 12), button]),
        ),
      ),
    );
  }
}

class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.state});

  final InstallmentsState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ResponsiveGrid(
      minItemWidth: 220,
      maxColumns: 3,
      children: [
        StatTile(
          label: loc.memberInstallmentsSummaryPaid,
          value: '৳ ${_grouped(state.paidTotal)}',
          icon: Icons.check_circle_outline,
        ),
        StatTile(
          label: loc.memberInstallmentsSummaryDue,
          value: '৳ ${_grouped(state.dueTotal)}',
          icon: Icons.pending_actions_outlined,
          accent: Theme.of(context).colorScheme.error,
        ),
        StatTile(
          label: loc.memberInstallmentsSummaryPayments,
          value: '${state.paidCount} / ${state.filtered.length}',
          icon: Icons.receipt_long_outlined,
          accent: AppColors.gold,
        ),
      ],
    );
  }
}

class _YearFilter extends StatelessWidget {
  const _YearFilter({required this.state, required this.bloc});

  final InstallmentsState state;
  final InstallmentsBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final gutter = context.pageGutter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 4),
      child: Row(
        children: [
          ChoiceChip(
            avatar: const Icon(Icons.filter_list, size: 18),
            label: Text(loc.memberInstallmentsFilterAll),
            selected: state.selectedYear == null,
            onSelected: (_) => bloc.add(const InstallmentsYearFilterChanged(null)),
          ),
          for (final y in state.years) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('$y'),
              selected: state.selectedYear == y,
              onSelected: (_) => bloc.add(InstallmentsYearFilterChanged(y)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({required this.installment, required this.pending});

  final MemberInstallment installment;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final i = installment;
    final (StatusKind kind, String label, IconData icon, Color color) = pending
        ? (StatusKind.pending, loc.memberPayDuesStatusPending, Icons.hourglass_top, AppColors.gold)
        : i.isPaid
            ? (StatusKind.approved, loc.memberInstallmentsStatusPaid, Icons.check, theme.colorScheme.primary)
            : (StatusKind.rejected, loc.memberInstallmentsStatusDue, Icons.schedule, theme.colorScheme.error);
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          LeadingIcon(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${monthLabel(i.month, loc)} ${i.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '৳ ${_grouped(i.amount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (i.paidAt != null)
                  Text(
                    '${loc.memberInstallmentsPaidAtColumn}: ${i.paidAt}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(kind: kind, label: label),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final InstallmentPayment payment;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = payment;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.installments.map((i) => '${monthLabel(i.month, loc)} ${i.year}').join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              _paymentBadge(p.status, loc),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${p.method} · ${p.transactionRef} · ${p.paidOn}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          if (p.status == SubmissionStatus.rejected && p.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${loc.memberPayDuesRejectedReason}: ${p.rejectionReason}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '৳ ${_grouped(p.amount)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBadge(SubmissionStatus status, AppLocalizations loc) {
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
