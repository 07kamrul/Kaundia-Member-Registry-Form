import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/finance_entities.dart';
import '../bloc/society_costs_bloc.dart';
import 'management_page_kit.dart';
import 'management_widgets.dart';

/// Sections of the society costs page: summary tiles, filters and the
/// expandable cost card with its member shares.

String societySplitMethodLabel(AppLocalizations loc, CostSplitMethod method) =>
    switch (method) {
      CostSplitMethod.equal => loc.adminSocietyCostsSplitMethodEqual,
      CostSplitMethod.byLandQuantity =>
        loc.adminSocietyCostsSplitMethodByLandQuantity,
      CostSplitMethod.manual => loc.adminSocietyCostsSplitMethodManual,
      _ => '—',
    };

String societyShareLabel(AppLocalizations loc, ShareStatus status) =>
    switch (status) {
      ShareStatus.paid => loc.adminSocietyCostsShareStatusPaid,
      ShareStatus.partial => loc.adminSocietyCostsShareStatusPartial,
      ShareStatus.unpaid => loc.adminSocietyCostsShareStatusUnpaid,
      _ => '—',
    };

String societySourceLabel(AppLocalizations loc, CostPaymentSource source) =>
    source == CostPaymentSource.memberBilled
        ? loc.adminSocietyCostsSourceMemberBilled
        : loc.adminSocietyCostsSourceSocietyFund;

/// Total / society fund / member billed / outstanding KPI tiles.
class SocietySummaryTiles extends StatelessWidget {
  const SocietySummaryTiles({super.key, required this.summary});

  final SocietyCostSummary summary;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      child: ResponsiveGrid(
        minItemWidth: 180,
        maxColumns: 4,
        children: [
          StatTile(
            label: loc.adminSocietyCostsSummaryTotal,
            value: formatTaka(summary.totalAmount),
            icon: Icons.summarize_outlined,
          ),
          StatTile(
            label: loc.adminSocietyCostsSummarySocietyFund,
            value: formatTaka(summary.societyFundTotal),
            icon: Icons.account_balance_outlined,
            accent: scheme.tertiary,
          ),
          StatTile(
            label: loc.adminSocietyCostsSummaryMemberBilled,
            value: formatTaka(summary.memberBilledTotal),
            icon: Icons.groups_outlined,
            accent: scheme.secondary,
          ),
          StatTile(
            label: loc.adminSocietyCostsSummaryOutstanding,
            value: formatTaka(summary.outstandingTotal),
            icon: Icons.pending_actions_outlined,
            accent: scheme.error,
          ),
        ],
      ),
    );
  }
}

/// Category / source / billing / date / search filters.
class SocietyFilterPanel extends StatelessWidget {
  const SocietyFilterPanel({
    super.key,
    required this.state,
    required this.searchController,
    required this.onChanged,
    required this.onSearch,
    required this.onReset,
  });

  final SocietyCostsState state;
  final TextEditingController searchController;

  /// Emits a fully-populated filter event so other filters are preserved.
  final ValueChanged<SocietyFiltersChanged> onChanged;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  SocietyFiltersChanged _with({
    String? Function()? category,
    CostPaymentSource? Function()? source,
    bool? Function()? billed,
    String? dateFrom,
    String? dateTo,
  }) =>
      SocietyFiltersChanged(
        categoryFilter: category == null ? state.categoryFilter : category(),
        sourceFilter: source == null ? state.sourceFilter : source(),
        billedFilter: billed == null ? state.billedFilter : billed(),
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return FilterPanel(
      fields: [
        LabeledDropdown<String>(
          label: loc.adminSocietyCostsFiltersCategory,
          value: state.categoryFilter,
          prefixIcon: Icons.sell_outlined,
          options: [
            (null, loc.adminSocietyCostsFiltersAllCategories),
            for (final c in state.categories) (c.id, c.label),
          ],
          onChanged: (v) => onChanged(_with(category: () => v)),
        ),
        LabeledDropdown<CostPaymentSource>(
          label: loc.adminSocietyCostsFiltersSource,
          value: state.sourceFilter,
          prefixIcon: Icons.account_tree_outlined,
          options: [
            (null, loc.adminSocietyCostsFiltersAllSources),
            for (final s in const [
              CostPaymentSource.societyFund,
              CostPaymentSource.memberBilled,
            ])
              (s, societySourceLabel(loc, s)),
          ],
          onChanged: (v) => onChanged(_with(source: () => v)),
        ),
        LabeledDropdown<bool>(
          label: loc.adminSocietyCostsFiltersBilled,
          value: state.billedFilter,
          prefixIcon: Icons.request_quote_outlined,
          options: [
            (null, loc.adminSocietyCostsFiltersAll),
            (true, loc.adminSocietyCostsFiltersBilledOnly),
            (false, loc.adminSocietyCostsFiltersUnbilledOnly),
          ],
          onChanged: (v) => onChanged(_with(billed: () => v)),
        ),
        DateField(
          label: loc.adminAuditLogFiltersDateFrom,
          value: state.dateFrom,
          onChanged: (v) => onChanged(_with(dateFrom: v)),
        ),
        DateField(
          label: loc.adminAuditLogFiltersDateTo,
          value: state.dateTo,
          onChanged: (v) => onChanged(_with(dateTo: v)),
        ),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: loc.adminSocietyCostsFiltersSearch,
            hintText: loc.adminSocietyCostsFiltersSearchPlaceholder,
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (_) => onSearch(),
        ),
      ],
      actions: [
        AppButton(
          label: loc.adminSocietyCostsFiltersReset,
          variant: AppButtonVariant.ghost,
          icon: Icons.restart_alt,
          onPressed: onReset,
        ),
      ],
    );
  }
}

/// Callbacks for a cost card's actions.
class SocietyCostActions {
  const SocietyCostActions({
    required this.onEdit,
    required this.onDelete,
    required this.onSplit,
    required this.onRecordPayment,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSplit;
  final ValueChanged<CostSplitShare> onRecordPayment;
}

class SocietyCostCard extends StatelessWidget {
  const SocietyCostCard({
    super.key,
    required this.cost,
    required this.expanded,
    required this.onToggle,
    required this.actions,
  });

  final SocietyCost cost;
  final bool expanded;
  final VoidCallback onToggle;
  final SocietyCostActions actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CostSummary(cost: cost, expanded: expanded),
                if (expanded) ...[
                  const Divider(height: 24),
                  _CostDetails(cost: cost, onRecordPayment: actions.onRecordPayment),
                  const SizedBox(height: 8),
                  _CostActionBar(cost: cost, actions: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostSummary extends StatelessWidget {
  const _CostSummary({required this.cost, required this.expanded});

  final SocietyCost cost;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final split = cost.split;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.receipt_outlined, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                cost.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FitBadge(
                    child: StatusBadge(
                      kind: cost.paymentSource == CostPaymentSource.memberBilled
                          ? StatusKind.pending
                          : StatusKind.neutral,
                      label: societySourceLabel(loc, cost.paymentSource),
                    ),
                  ),
                  MetaText(icon: Icons.event_outlined, text: cost.incurredDate),
                ],
              ),
              MetaText(icon: Icons.sell_outlined, text: cost.categoryLabel ?? '—'),
              MetaText(
                icon: Icons.call_split_rounded,
                text: split == null
                    ? loc.adminSocietyCostsNotBilled
                    : '${societySplitMethodLabel(loc, split.splitMethod)} (${split.shares.length})',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 6,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  formatTaka(cost.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

class _CostDetails extends StatelessWidget {
  const _CostDetails({required this.cost, required this.onRecordPayment});

  final SocietyCost cost;
  final ValueChanged<CostSplitShare> onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final notes = cost.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cost.description != null && cost.description!.isNotEmpty)
          DetailRow(label: loc.adminSocietyCostsFormDescription, value: cost.description!),
        if (notes != null && notes.isNotEmpty)
          DetailRow(label: loc.adminSocietyCostsFormNotes, value: notes),
        if (cost.receiptFileUrl != null)
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: loc.adminSocietyCostsViewReceipt,
              variant: AppButtonVariant.ghost,
              icon: Icons.receipt_long_outlined,
              onPressed: () => showImagePreview(context, cost.receiptFileUrl!, cost.title),
            ),
          ),
        if (cost.split != null)
          for (final share in cost.split!.shares)
            SocietyShareRow(share: share, onRecordPayment: () => onRecordPayment(share)),
      ],
    );
  }
}

/// One member's share: name, paid / due with progress, status, pay action.
class SocietyShareRow extends StatelessWidget {
  const SocietyShareRow({super.key, required this.share, required this.onRecordPayment});

  final CostSplitShare share;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = share.amountDue <= 0
        ? 1.0
        : (share.amountPaid / share.amountDue).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  share.memberName ?? '#${share.memberId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatAmount(share.amountPaid)} / ${formatAmount(share.amountDue)}',
                  style: theme.textTheme.bodySmall,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(value: progress, minHeight: 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            kind: switch (share.status) {
              ShareStatus.paid => StatusKind.approved,
              ShareStatus.partial => StatusKind.pending,
              _ => StatusKind.neutral,
            },
            label: societyShareLabel(loc, share.status),
          ),
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: loc.adminSocietyCostsRecordPayment,
            onPressed: onRecordPayment,
          ),
        ],
      ),
    );
  }
}

class _CostActionBar extends StatelessWidget {
  const _CostActionBar({required this.cost, required this.actions});

  final SocietyCost cost;
  final SocietyCostActions actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        DangerTextButton(label: loc.commonDelete, onPressed: actions.onDelete),
        AppButton(
          label: loc.commonEdit,
          variant: AppButtonVariant.ghost,
          icon: Icons.edit_outlined,
          onPressed: actions.onEdit,
        ),
        if (cost.paymentSource == CostPaymentSource.memberBilled)
          AppButton(
            label: loc.adminSocietyCostsSplitAction,
            icon: Icons.call_split_rounded,
            onPressed: actions.onSplit,
          ),
      ],
    );
  }
}
