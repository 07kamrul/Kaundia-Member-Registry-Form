import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/attachment_viewer.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/finance_repository.dart';
import '../domain/finance_entities.dart';
import '../domain/payment_entities.dart';
import '../presentation/bloc/fund_transparency_cubit.dart';

/// Port of Angular FundTransparencyComponent: period selector, totals +
/// balance stat cards, category breakdowns as progress bars (charts are
/// represented as stat cards/progress bars — no chart lib), paginated ledger
/// and PDF report download.
class FundTransparencyPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const FundTransparencyPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FundTransparencyCubit(
        repository: FinanceRepository(apiClient: sl<ApiClient>()),
      ),
      child: const _FundView(),
    );
  }
}

class _FundView extends StatefulWidget {
  const _FundView();

  @override
  State<_FundView> createState() => _FundViewState();
}

class _FundViewState extends State<_FundView> {
  @override
  void initState() {
    super.initState();
    context.read<FundTransparencyCubit>().applyPeriod(FinancePeriod.month);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<FundTransparencyCubit, FundTransparencyState>(
        listener: (context, state) {
          final path = state.pdfSavedPath;
          if (path != null) {
            OpenFilex.open(path);
            context.read<FundTransparencyCubit>().clearPdfSavedPath();
          }
        },
        builder: (context, state) {
          final cubit = context.read<FundTransparencyCubit>();
          final body = switch (state.status) {
            FundStatus.loading => const SkeletonLoader(lines: 8),
            FundStatus.failure => InlineError(
                message: loc.memberFundTransparencyErrorsLoadFailed,
                onRetry: () => cubit.applyPeriod(state.period),
              ),
            FundStatus.loaded => _loaded(context, state, loc, cubit),
          };
          return body;
        },
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    FundTransparencyState state,
    AppLocalizations loc,
    FundTransparencyCubit cubit,
  ) {
    final summary = state.summary;
    if (summary == null) {
      return InlineError(
        message: loc.memberFundTransparencyErrorsLoadFailed,
        onRetry: () => cubit.applyPeriod(state.period),
      );
    }
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final lang = isBn ? 'bn' : 'en';
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(title: loc.memberFundTransparencyTitle),
        // Period chips.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final period in FinancePeriod.values)
                ChoiceChip(
                  label: Text(_periodLabel(period, loc)),
                  selected: state.period == period,
                  onSelected: (_) => period == FinancePeriod.custom
                      ? _pickCustomRange(context, cubit, state)
                      : cubit.applyPeriod(period),
                ),
            ],
          ),
        ),
        if (state.isEmptyState)
          EmptyState(
            message: loc.memberFundTransparencyEmptyTitle,
            icon: Icons.volunteer_activism_outlined,
          )
        else ...[
          AppCard(
            child: Row(
              children: [
                _stat(context, loc.memberFundTransparencyTotalIncome,
                    formatTaka(summary.totals.income, lang)),
                _stat(context, loc.memberFundTransparencyTotalExpense,
                    formatTaka(summary.totals.expense, lang)),
                _stat(context, loc.memberFundTransparencyNetSaved,
                    formatTaka(summary.totals.net, lang)),
              ],
            ),
          ),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(loc.memberFundTransparencyCurrentBalance,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                Text(
                  formatTaka(summary.balance, lang),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          AppCard(
            title: loc.memberFundTransparencyIncomeBreakdown,
            child: _breakdown(summary.incomeByCategory, loc.memberFundTransparencyIncomeBreakdownEmpty),
          ),
          AppCard(
            title: loc.memberFundTransparencyExpenseBreakdown,
            child: _breakdown(summary.expenseByCategory, loc.memberFundTransparencyExpenseBreakdownEmpty),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppButton(
              label: state.pdfDownloading
                  ? loc.commonLoading
                  : loc.memberFundTransparencyDownloadPdf,
              icon: Icons.picture_as_pdf_outlined,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: state.pdfDownloading ? null : cubit.downloadReport,
            ),
          ),
          if (state.pdfError)
            InlineError(
              message: loc.memberFundTransparencyErrorsPdfFailed,
              onRetry: cubit.downloadReport,
            ),
          // Ledger.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(loc.memberFundTransparencyLedgerCount(
                      state.ledger?.total ?? 0),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: loc.memberFundTransparencyFiltersClearAll,
                  onPressed: () => cubit.setFilters(),
                  icon: const Icon(Icons.filter_alt_off_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: loc.memberFundTransparencyFiltersSearchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (q) => cubit.setFilters(search: q),
            ),
          ),
          if (state.ledgerError)
            InlineError(
              message: loc.memberFundTransparencyErrorsLoadFailed,
              onRetry: () => cubit.changePage(0),
            )
          else if (state.ledgerLoading)
            const SkeletonLoader(lines: 4)
          else if ((state.ledger?.items ?? const []).isEmpty)
            EmptyState(message: loc.memberFundTransparencyLedgerEmpty)
          else
            for (final txn in state.ledger!.items)
              AppCard(
                onTap: txn.attachmentUrl != null
                    ? () => showAttachmentViewer(
                        context, rawPathOrUrl: txn.attachmentUrl!, title: txn.description)
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(txn.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${txn.txnDate}'
                            '${txn.categoryLabel != null ? ' · ${txn.categoryLabel}' : ''}'
                            '${txn.referenceNo != null ? ' · ${txn.referenceNo}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${txn.type == FinanceType.income ? '+' : '−'} ${formatTaka(txn.amount, lang)}',
                      style: TextStyle(
                        color: txn.type == FinanceType.income
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          if (state.totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      state.page > 1 ? () => cubit.changePage(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(loc.memberFundTransparencyLedgerPage(state.page, state.totalPages)),
                IconButton(
                  onPressed: state.page < state.totalPages
                      ? () => cubit.changePage(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _breakdown(List<FinanceCategoryBreakdown> rows, String emptyMessage) {
    if (rows.isEmpty) return Text(emptyMessage);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(row.category)),
                    Text('${row.share.toStringAsFixed(1)}%'),
                  ],
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: row.share.toDouble().clamp(2, 100) / 100),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, value, __) => LinearProgressIndicator(value: value),
                ),
              ],
            ),
          ),
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

  String _periodLabel(FinancePeriod period, AppLocalizations loc) =>
      switch (period) {
        FinancePeriod.month => loc.memberFundTransparencyPeriodMonth,
        FinancePeriod.year => loc.memberFundTransparencyPeriodYear,
        FinancePeriod.custom => loc.memberFundTransparencyPeriodCustom,
        FinancePeriod.all => loc.memberFundTransparencyPeriodAll,
      };

  Future<void> _pickCustomRange(
    BuildContext context,
    FundTransparencyCubit cubit,
    FundTransparencyState state,
  ) async {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDate: now,
      helpText: loc.memberFundTransparencyFiltersDateFrom,
    );
    if (from == null || !context.mounted) return;
    final to = await showDatePicker(
      context: context,
      firstDate: from,
      lastDate: now,
      initialDate: now,
      helpText: loc.memberFundTransparencyFiltersDateTo,
    );
    if (to == null || !context.mounted) return;
    await cubit.applyPeriod(
      FinancePeriod.custom,
      dateFrom: from.toIso8601String().substring(0, 10),
      dateTo: to.toIso8601String().substring(0, 10),
    );
  }
}
