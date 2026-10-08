import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/finance_entities.dart';
import 'management_page_kit.dart';
import 'management_widgets.dart';

/// Sections of the finance management page: KPI tiles, filter panel and the
/// expandable ledger card.

StatusKind financeStatusKind(FinanceStatus status) => switch (status) {
      FinanceStatus.approved => StatusKind.approved,
      FinanceStatus.pending => StatusKind.pending,
      FinanceStatus.rejected => StatusKind.rejected,
      _ => StatusKind.neutral,
    };

String financeStatusLabel(AppLocalizations loc, FinanceStatus status) =>
    switch (status) {
      FinanceStatus.approved => loc.adminFinanceManagementStatusApproved,
      FinanceStatus.pending => loc.adminFinanceManagementStatusPending,
      FinanceStatus.rejected => loc.adminFinanceManagementStatusRejected,
      _ => loc.adminFinanceManagementStatusDraft,
    };

String financeSourceLabel(AppLocalizations loc, PaymentSourceType source) =>
    switch (source) {
      PaymentSourceType.installment =>
        loc.adminFinanceManagementSourceInstallment,
      PaymentSourceType.picnicPayment =>
        loc.adminFinanceManagementSourcePicnicPayment,
      PaymentSourceType.costShare => loc.adminFinanceManagementSourceCostShare,
      _ => '—',
    };

/// Income in brand green, expense in the error tone.
Color financeTypeColor(BuildContext context, FinanceType type) =>
    type == FinanceType.expense
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

/// Pending / month net / balance as KPI tiles (1–3 columns).
class FinanceOverviewTiles extends StatelessWidget {
  const FinanceOverviewTiles({super.key, required this.overview});

  final FinanceOverview overview;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      child: ResponsiveGrid(
        minItemWidth: 200,
        maxColumns: 3,
        children: [
          StatTile(
            label: loc.adminFinanceManagementOverviewPending,
            value: '${overview.pendingCount}',
            icon: Icons.hourglass_top_rounded,
            accent: scheme.secondary,
          ),
          StatTile(
            label: loc.adminFinanceManagementOverviewMonthNet,
            value: formatTaka(overview.monthNet),
            icon: Icons.trending_up_rounded,
            accent: overview.monthNet < 0 ? scheme.error : scheme.primary,
          ),
          StatTile(
            label: loc.adminFinanceManagementOverviewBalance,
            value: formatTaka(overview.balance),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }
}

/// Status / type / date range / search filters that wrap into columns.
class FinanceFilterPanel extends StatelessWidget {
  const FinanceFilterPanel({
    super.key,
    required this.statusFilter,
    required this.typeFilter,
    required this.dateFrom,
    required this.dateTo,
    required this.searchController,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.onSearch,
    required this.onReset,
  });

  final FinanceStatus? statusFilter;
  final FinanceType? typeFilter;
  final String dateFrom;
  final String dateTo;
  final TextEditingController searchController;
  final ValueChanged<FinanceStatus?> onStatusChanged;
  final ValueChanged<FinanceType?> onTypeChanged;
  final ValueChanged<String> onDateFromChanged;
  final ValueChanged<String> onDateToChanged;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return FilterPanel(
      fields: [
        LabeledDropdown<FinanceStatus>(
          label: loc.adminFinanceManagementLedgerStatus,
          value: statusFilter,
          prefixIcon: Icons.flag_outlined,
          options: [
            (null, loc.adminFinanceManagementStatusAll),
            for (final s in const [
              FinanceStatus.pending,
              FinanceStatus.draft,
              FinanceStatus.approved,
              FinanceStatus.rejected,
            ])
              (s, financeStatusLabel(loc, s)),
          ],
          onChanged: onStatusChanged,
        ),
        LabeledDropdown<FinanceType>(
          label: loc.adminFinanceManagementFiltersType,
          value: typeFilter,
          prefixIcon: Icons.swap_vert_rounded,
          options: [
            (null, loc.adminFinanceManagementFiltersAllTypes),
            (FinanceType.income, loc.adminFinanceManagementTypeIncome),
            (FinanceType.expense, loc.adminFinanceManagementTypeExpense),
          ],
          onChanged: onTypeChanged,
        ),
        DateField(
          label: loc.adminAuditLogFiltersDateFrom,
          value: dateFrom,
          onChanged: onDateFromChanged,
        ),
        DateField(
          label: loc.adminAuditLogFiltersDateTo,
          value: dateTo,
          onChanged: onDateToChanged,
        ),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: loc.adminFinanceManagementFiltersSearch,
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (_) => onSearch(),
        ),
      ],
      actions: [
        AppButton(
          label: loc.adminFinanceManagementFiltersReset,
          variant: AppButtonVariant.ghost,
          icon: Icons.restart_alt,
          onPressed: onReset,
        ),
        AppButton(
          label: loc.adminFinanceManagementFiltersApply,
          variant: AppButtonVariant.secondary,
          icon: Icons.filter_alt_outlined,
          onPressed: onSearch,
        ),
      ],
    );
  }
}

/// Workflow callbacks for a ledger row; null hides / disables the action.
class FinanceTxnActions {
  const FinanceTxnActions({
    this.onSubmit,
    this.onApprove,
    this.onReject,
    this.onReverse,
    this.onEdit,
    this.onDelete,
  });

  final VoidCallback? onSubmit;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReverse;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}

/// Ledger card: type icon, description, date/category meta, right-aligned
/// signed amount + status; tap to reveal details and workflow actions.
class FinanceTxnCard extends StatelessWidget {
  const FinanceTxnCard({
    super.key,
    required this.txn,
    required this.expanded,
    required this.busy,
    required this.onToggle,
    required this.actions,
  });

  final FinanceTransaction txn;
  final bool expanded;
  final bool busy;
  final VoidCallback onToggle;
  final FinanceTxnActions actions;

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
                _TxnSummary(txn: txn, expanded: expanded),
                if (expanded) ...[
                  const Divider(height: 24),
                  _TxnDetails(txn: txn),
                  const SizedBox(height: 8),
                  _TxnActionBar(txn: txn, busy: busy, actions: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TxnSummary extends StatelessWidget {
  const _TxnSummary({required this.txn, required this.expanded});

  final FinanceTransaction txn;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isIncome = txn.type != FinanceType.expense;
    final color = financeTypeColor(context, txn.type);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                txn.description,
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
                      kind: financeStatusKind(txn.status),
                      label: financeStatusLabel(loc, txn.status),
                    ),
                  ),
                  MetaText(icon: Icons.event_outlined, text: txn.txnDate),
                ],
              ),
              MetaText(icon: Icons.sell_outlined, text: txn.categoryLabel ?? '—'),
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
                  '${isIncome ? '+' : '−'} ${formatTaka(txn.amount)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
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

class _TxnDetails extends StatelessWidget {
  const _TxnDetails({required this.txn});

  final FinanceTransaction txn;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailRow(
          label: loc.adminFinanceManagementLedgerReference,
          value: txn.referenceNo ?? '—',
        ),
        if (txn.internalNotes != null)
          DetailRow(
            label: loc.adminFinanceManagementLedgerInternalNotes,
            value: txn.internalNotes!,
          ),
        if (txn.rejectionReason != null)
          DetailRow(
            label: loc.adminFinanceManagementLedgerRejectionReason,
            value: txn.rejectionReason!,
          ),
        if (txn.approvedByName != null)
          DetailRow(
            label: loc.adminFinanceManagementLedgerApprovedBy,
            value: '${txn.approvedByName} · ${txn.approvedAt ?? ''}',
          ),
        if (txn.createdByName != null)
          DetailRow(
            label: loc.adminFinanceManagementLedgerCreatedBy,
            value: txn.createdByName!,
          ),
        if (txn.linkedPaymentType != null)
          DetailRow(
            label: loc.adminFinanceManagementLedgerLinkedPayment,
            value:
                '${financeSourceLabel(loc, txn.linkedPaymentType!)} #${txn.linkedPaymentId}',
          ),
        if (txn.attachmentUrl != null)
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: loc.adminFinanceManagementLedgerViewAttachment,
              variant: AppButtonVariant.ghost,
              icon: Icons.attach_file,
              onPressed: () =>
                  showImagePreview(context, txn.attachmentUrl!, txn.description),
            ),
          ),
      ],
    );
  }
}

class _TxnActionBar extends StatelessWidget {
  const _TxnActionBar({required this.txn, required this.busy, required this.actions});

  final FinanceTransaction txn;
  final bool busy;
  final FinanceTxnActions actions;

  VoidCallback? _guard(VoidCallback? cb) => busy ? null : cb;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final status = txn.status;
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        DangerTextButton(
          label: loc.commonDelete,
          icon: Icons.delete_outline,
          onPressed: _guard(actions.onDelete),
        ),
        AppButton(
          label: loc.commonEdit,
          variant: AppButtonVariant.ghost,
          icon: Icons.edit_outlined,
          onPressed: _guard(actions.onEdit),
        ),
        if (status == FinanceStatus.approved)
          AppButton(
            label: loc.adminFinanceManagementActionsReverse,
            variant: AppButtonVariant.secondary,
            icon: Icons.undo_rounded,
            onPressed: _guard(actions.onReverse),
          ),
        if (status == FinanceStatus.pending || status == FinanceStatus.approved)
          AppButton(
            label: loc.adminFinanceManagementActionsReject,
            variant: AppButtonVariant.secondary,
            icon: Icons.block,
            onPressed: _guard(actions.onReject),
          ),
        if (status == FinanceStatus.pending)
          AppButton(
            label: loc.adminFinanceManagementActionsApprove,
            icon: Icons.check_circle_outline,
            loading: busy,
            onPressed: actions.onApprove,
          ),
        if (status == FinanceStatus.draft)
          AppButton(
            label: loc.adminFinanceManagementActionsSubmit,
            icon: Icons.send_outlined,
            loading: busy,
            onPressed: actions.onSubmit,
          ),
      ],
    );
  }
}
