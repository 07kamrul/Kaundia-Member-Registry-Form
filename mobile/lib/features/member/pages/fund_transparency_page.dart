import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/attachment_viewer.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/finance_repository.dart';
import '../domain/finance_entities.dart';
import '../domain/payment_entities.dart';
import '../presentation/bloc/fund_transparency_bloc.dart';
import '../presentation/widgets/member_ui.dart';

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
      create: (_) => FundTransparencyBloc(
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
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FundTransparencyBloc>().add(const FundStarted(FinancePeriod.month));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<FundTransparencyBloc, FundTransparencyState>(
        listener: (context, state) {
          final path = state.pdfSavedPath;
          if (path != null) {
            OpenFilex.open(path);
            context.read<FundTransparencyBloc>().add(const FundPdfSavedPathCleared());
          }
        },
        builder: (context, state) {
          final bloc = context.read<FundTransparencyBloc>();
          return switch (state.status) {
            FundStatus.loading when state.summary == null => const SkeletonLoader(lines: 8),
            FundStatus.failure => InlineError(
                message: loc.memberFundTransparencyErrorsLoadFailed,
                onRetry: () => bloc.add(FundPeriodChanged(state.period)),
              ),
            _ => _loaded(context, state, loc, bloc),
          };
        },
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    FundTransparencyState state,
    AppLocalizations loc,
    FundTransparencyBloc bloc,
  ) {
    final summary = state.summary;
    if (summary == null) {
      return InlineError(
        message: loc.memberFundTransparencyErrorsLoadFailed,
        onRetry: () => bloc.add(FundPeriodChanged(state.period)),
      );
    }
    final lang = Localizations.localeOf(context).languageCode == 'bn' ? 'bn' : 'en';
    return PageBody(
      onRefresh: () => reloadAndWait<FundTransparencyState>(
        bloc,
        () => bloc.add(FundPeriodChanged(
          state.period,
          dateFrom: state.ledgerDateFrom,
          dateTo: state.ledgerDateTo,
        )),
        (s) => s.status != FundStatus.loading && !s.ledgerLoading,
      ),
      children: [
        PageHeader(
          title: loc.memberFundTransparencyTitle,
          subtitle: loc.memberFundTransparencySubtitle,
          icon: Icons.account_balance_outlined,
        ),
        _PeriodChips(state: state, onPick: (p) => _onPeriod(context, bloc, p)),
        if (state.isEmptyState)
          EmptyState(
            message: loc.memberFundTransparencyEmptyTitle,
            icon: Icons.volunteer_activism_outlined,
          )
        else
          ..._summary(context, state, summary, loc, bloc, lang),
      ],
    );
  }

  List<Widget> _summary(
    BuildContext context,
    FundTransparencyState state,
    FinanceSummary summary,
    AppLocalizations loc,
    FundTransparencyBloc bloc,
    String lang,
  ) {
    return [
      _BalanceCard(balance: formatTaka(summary.balance, lang)),
      Gutter(vertical: 6, child: _TotalsGrid(summary: summary, lang: lang)),
      Gutter(
        vertical: 6,
        child: ResponsiveGrid(
          minItemWidth: 420,
          maxColumns: 2,
          children: [
            _BreakdownCard(
              title: loc.memberFundTransparencyIncomeBreakdown,
              rows: summary.incomeByCategory,
              emptyMessage: loc.memberFundTransparencyIncomeBreakdownEmpty,
              color: AppColors.emerald600,
            ),
            _BreakdownCard(
              title: loc.memberFundTransparencyExpenseBreakdown,
              rows: summary.expenseByCategory,
              emptyMessage: loc.memberFundTransparencyExpenseBreakdownEmpty,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
      Gutter(
        vertical: 6,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: state.pdfDownloading ? loc.commonLoading : loc.memberFundTransparencyDownloadPdf,
            icon: Icons.picture_as_pdf_outlined,
            variant: AppButtonVariant.secondary,
            loading: state.pdfDownloading,
            onPressed: () => bloc.add(const FundReportDownloaded()),
          ),
        ),
      ),
      if (state.pdfError)
        NoticeBanner(
          tone: NoticeTone.error,
          message: loc.memberFundTransparencyErrorsPdfFailed,
          action: TextButton(
            onPressed: () => bloc.add(const FundReportDownloaded()),
            child: Text(loc.commonRetry),
          ),
        ),
      ..._ledger(context, state, loc, bloc, lang),
    ];
  }

  List<Widget> _ledger(
    BuildContext context,
    FundTransparencyState state,
    AppLocalizations loc,
    FundTransparencyBloc bloc,
    String lang,
  ) {
    final items = state.ledger?.items ?? const <FinanceTransaction>[];
    return [
      SectionTitle(
        loc.memberFundTransparencyLedgerCount(state.ledger?.total ?? 0),
        trailing: IconButton(
          tooltip: loc.memberFundTransparencyFiltersClearAll,
          onPressed: () {
            _search.clear();
            bloc.add(const FundLedgerFiltersChanged());
          },
          icon: const Icon(Icons.filter_alt_off_outlined),
        ),
      ),
      Gutter(
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: loc.memberFundTransparencyFiltersSearchPlaceholder,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: loc.memberFundTransparencyFiltersSearch,
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => bloc.add(FundLedgerFiltersChanged(search: _search.text)),
            ),
          ),
          onSubmitted: (q) => bloc.add(FundLedgerFiltersChanged(search: q)),
        ),
      ),
      const SizedBox(height: 8),
      if (state.ledgerError)
        InlineError(
          message: loc.memberFundTransparencyErrorsLoadFailed,
          onRetry: () => bloc.add(const FundLedgerPageChanged(0)),
        )
      else if (state.ledgerLoading)
        const SkeletonLoader(lines: 4, height: 72)
      else if (items.isEmpty)
        EmptyState(message: loc.memberFundTransparencyLedgerEmpty, icon: Icons.receipt_long_outlined)
      else
        Gutter(
          child: ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 3,
            children: [for (final txn in items) _TxnCard(txn: txn, lang: lang)],
          ),
        ),
      if (state.totalPages > 1)
        PagerBar(
          label: loc.memberFundTransparencyLedgerPage(state.page, state.totalPages),
          previousTooltip: loc.adminAuditLogPaginationPrev,
          nextTooltip: loc.adminAuditLogPaginationNext,
          onPrevious: state.page > 1 ? () => bloc.add(const FundLedgerPageChanged(-1)) : null,
          onNext: state.page < state.totalPages ? () => bloc.add(const FundLedgerPageChanged(1)) : null,
        ),
    ];
  }

  void _onPeriod(BuildContext context, FundTransparencyBloc bloc, FinancePeriod period) {
    if (period == FinancePeriod.custom) {
      _pickCustomRange(context, bloc);
    } else {
      bloc.add(FundPeriodChanged(period));
    }
  }

  Future<void> _pickCustomRange(BuildContext context, FundTransparencyBloc bloc) async {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: loc.memberFundTransparencyFiltersDateRange,
      fieldStartLabelText: loc.memberFundTransparencyFiltersDateFrom,
      fieldEndLabelText: loc.memberFundTransparencyFiltersDateTo,
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: child,
        ),
      ),
    );
    if (range == null || !context.mounted) return;
    bloc.add(FundPeriodChanged(
      FinancePeriod.custom,
      dateFrom: range.start.toIso8601String().substring(0, 10),
      dateTo: range.end.toIso8601String().substring(0, 10),
    ));
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.state, required this.onPick});

  final FundTransparencyState state;
  final ValueChanged<FinancePeriod> onPick;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final gutter = context.pageGutter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
      child: Row(
        children: [
          for (final period in FinancePeriod.values) ...[
            if (period != FinancePeriod.values.first) const SizedBox(width: 8),
            ChoiceChip(
              avatar: period == FinancePeriod.custom ? const Icon(Icons.date_range, size: 18) : null,
              label: Text(_periodLabel(period, loc)),
              selected: state.period == period,
              onSelected: (_) => onPick(period),
            ),
          ],
        ],
      ),
    );
  }

  String _periodLabel(FinancePeriod period, AppLocalizations loc) => switch (period) {
        FinancePeriod.month => loc.memberFundTransparencyPeriodMonth,
        FinancePeriod.year => loc.memberFundTransparencyPeriodYear,
        FinancePeriod.custom => loc.memberFundTransparencyPeriodCustom,
        FinancePeriod.all => loc.memberFundTransparencyPeriodAll,
      };
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const onBrand = Colors.white;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: onBrand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.savings_outlined, color: onBrand),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.memberFundTransparencyCurrentBalance,
                    style: theme.textTheme.bodyMedium?.copyWith(color: onBrand.withValues(alpha: 0.85)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      balance,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: onBrand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsGrid extends StatelessWidget {
  const _TotalsGrid({required this.summary, required this.lang});

  final FinanceSummary summary;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ResponsiveGrid(
      minItemWidth: 220,
      maxColumns: 3,
      children: [
        StatTile(
          label: loc.memberFundTransparencyTotalIncome,
          value: formatTaka(summary.totals.income, lang),
          icon: Icons.south_west,
          accent: AppColors.emerald600,
        ),
        StatTile(
          label: loc.memberFundTransparencyTotalExpense,
          value: formatTaka(summary.totals.expense, lang),
          icon: Icons.north_east,
          accent: Theme.of(context).colorScheme.error,
        ),
        StatTile(
          label: loc.memberFundTransparencyNetSaved,
          value: formatTaka(summary.totals.net, lang),
          icon: Icons.trending_up,
          accent: AppColors.gold,
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.rows,
    required this.emptyMessage,
    required this.color,
  });

  final String title;
  final List<FinanceCategoryBreakdown> rows;
  final String emptyMessage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      title: title,
      child: rows.isEmpty
          ? Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          : Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(row.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${row.share.toStringAsFixed(1)}%',
                              style: theme.textTheme.labelLarge?.copyWith(color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: row.share.toDouble().clamp(2, 100) / 100),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, value, __) => LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              color: color,
                              backgroundColor: color.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.txn, required this.lang});

  final FinanceTransaction txn;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final income = txn.type == FinanceType.income;
    final color = income ? AppColors.emerald600 : theme.colorScheme.error;
    final meta = [
      txn.txnDate,
      if (txn.categoryLabel != null) txn.categoryLabel!,
      if (txn.referenceNo != null) txn.referenceNo!,
    ].join(' · ');
    final hasAttachment = txn.attachmentUrl != null;
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: hasAttachment
          ? () => showAttachmentViewer(context, rawPathOrUrl: txn.attachmentUrl!, title: txn.description)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeadingIcon(icon: income ? Icons.south_west : Icons.north_east, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                if (hasAttachment)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MetaChip(
                      icon: Icons.attach_file,
                      text: loc.memberFundTransparencyLedgerViewAttachment,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${income ? '+' : '−'} ${formatTaka(txn.amount, lang)}',
            style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
