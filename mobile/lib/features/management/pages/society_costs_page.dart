import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/society_costs_bloc.dart';
import '../presentation/widgets/management_widgets.dart';

/// Society costs (Angular society-costs): filters + summary, cost CRUD with
/// receipt upload, split flow with live dry-run preview, share payment.
class SocietyCostsPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const SocietyCostsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<SocietyCostsPage> createState() => _SocietyCostsPageState();
}

class _SocietyCostsPageState extends State<SocietyCostsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => SocietyCostsBloc(
        adminRepository: AdminRepository(apiClient: sl<ApiClient>()),
        costRepository: SocietyCostRepository(apiClient: sl<ApiClient>()),
      )..init(),
      child: BlocConsumer<SocietyCostsBloc, SocietyCostsState>(
        listener: (context, state) {
          if (state.actionError != null) {
            showAppToast(context, loc.adminSocietyCostsErrorsSaveFailed,
                error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<SocietyCostsBloc>();
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminSocietyCostsTitle,
                  subtitle: loc.adminSocietyCostsSubtitle),
              // Summary.
              if (state.summary != null)
                AppCard(
                  title: loc.adminSocietyCostsSummaryTotal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(
                          label: loc.adminSocietyCostsSummaryTotal,
                          value: formatTaka(state.summary!.totalAmount,
                              decimals: 0)),
                      InfoRow(
                          label: loc.adminSocietyCostsSummarySocietyFund,
                          value: formatTaka(state.summary!.societyFundTotal,
                              decimals: 0)),
                      InfoRow(
                          label: loc.adminSocietyCostsSummaryOutstanding,
                          value: formatTaka(state.summary!.outstandingTotal,
                              decimals: 0)),
                    ],
                  ),
                ),
              // Filters.
              AppCard(
                title: loc.adminSocietyCostsFiltersCategory,
                child: Column(
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: state.categoryFilter,
                      decoration: InputDecoration(
                        labelText: loc.adminSocietyCostsFiltersCategory,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child:
                              Text(loc.adminSocietyCostsFiltersAllCategories),
                        ),
                        for (final c in state.categories)
                          DropdownMenuItem<String?>(
                              value: c.id, child: Text(c.label)),
                      ],
                      onChanged: (v) => bloc.add(FinanceFiltersChanged(categoryFilter: v)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CostPaymentSource?>(
                      initialValue: state.sourceFilter,
                      decoration: InputDecoration(
                        labelText: loc.adminSocietyCostsFiltersSource,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<CostPaymentSource?>(
                          value: null,
                          child: Text(loc.adminSocietyCostsFiltersAllSources),
                        ),
                        DropdownMenuItem<CostPaymentSource?>(
                          value: CostPaymentSource.societyFund,
                          child: Text(loc.adminSocietyCostsSourceSocietyFund),
                        ),
                        DropdownMenuItem<CostPaymentSource?>(
                          value: CostPaymentSource.memberBilled,
                          child: Text(loc.adminSocietyCostsSourceMemberBilled),
                        ),
                      ],
                      onChanged: (v) => bloc.add(FinanceFiltersChanged(sourceFilter: v)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<bool?>(
                      initialValue: state.billedFilter,
                      decoration: InputDecoration(
                        labelText: loc.adminSocietyCostsFiltersBilled,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<bool?>(
                          value: null,
                          child: Text(loc.adminSocietyCostsFiltersAll),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Text(loc.adminSocietyCostsFiltersBilledOnly),
                        ),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text(loc.adminSocietyCostsFiltersUnbilledOnly),
                        ),
                      ],
                      onChanged: (v) => bloc.add(FinanceFiltersChanged(billedFilter: v)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DateField(
                            label: loc.adminSocietyCostsFiltersDateRange,
                            value: state.dateFrom,
                            onChanged: (v) => bloc.add(FinanceFiltersChanged(dateFrom: v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DateField(
                            label: loc.adminSocietyCostsTableDate,
                            value: state.dateTo,
                            onChanged: (v) => bloc.add(FinanceFiltersChanged(dateTo: v)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: loc.adminSocietyCostsFiltersSearch,
                        border: const OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (v) => bloc.add(FinanceFiltersChanged(search: v)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: loc.adminSocietyCostsCreate,
                            onPressed: () => _openCostForm(context, loc, bloc),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: loc.adminSocietyCostsFiltersReset,
                            variant: AppButtonVariant.secondary,
                            onPressed: () {
                              _searchController.clear();
                              bloc.add(FinanceFiltersReset());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 5)
              else if (state.error != null)
                InlineError(
                    message: loc.adminSocietyCostsErrorsLoadFailed,
                    onRetry: () => bloc.add(const FinanceRefreshRequested()))
              else if (state.costs.isEmpty)
                EmptyState(message: loc.adminSocietyCostsEmptyState)
              else
                AppDataTableCards<SocietyCost>(
                  items: state.costs,
                  rowBuilder: (context, cost) =>
                      _costRow(context, loc, bloc, state, cost),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _costRow(BuildContext context, AppLocalizations loc,
      SocietyCostsBloc bloc, SocietyCostsState state, SocietyCost cost) {
    final expanded = state.expandedId == cost.id;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => bloc.add(FinanceRowToggled(id: cost.id)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cost.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatTaka(cost.totalAmount, decimals: 0),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            const SizedBox(height: 6),
            InfoRow(
                label: loc.adminSocietyCostsTableCategory,
                value: cost.categoryLabel ?? '—'),
            InfoRow(
                label: loc.adminSocietyCostsTableDate,
                value: cost.incurredDate),
            InfoRow(
              label: loc.adminSocietyCostsTableSource,
              value: cost.paymentSource == CostPaymentSource.memberBilled
                  ? loc.adminSocietyCostsSourceMemberBilled
                  : loc.adminSocietyCostsSourceSocietyFund,
            ),
            InfoRow(
              label: loc.adminSocietyCostsTableSplit,
              value: cost.split == null
                  ? loc.adminSocietyCostsNotBilled
                  : '${_methodLabel(loc, cost.split!.splitMethod)} (${cost.split!.shares.length})',
            ),
            if (expanded) ...[
              if (cost.receiptFileUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AppButton(
                    label: loc.adminSocietyCostsViewReceipt,
                    variant: AppButtonVariant.ghost,
                    icon: Icons.receipt_outlined,
                    onPressed: () => showImagePreview(
                        context, cost.receiptFileUrl!, cost.title),
                  ),
                ),
              if (cost.notes != null && cost.notes!.isNotEmpty)
                InfoRow(
                    label: loc.adminSocietyCostsFormNotes, value: cost.notes!),
              // Per-cost shares + record payment.
              if (cost.split != null)
                for (final share in cost.split!.shares)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(share.memberName ?? '#${share.memberId}'),
                    subtitle: Text(
                      '${formatAmount(share.amountDue)} — ${formatAmount(share.amountPaid)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          kind: switch (share.status) {
                            ShareStatus.paid => StatusKind.approved,
                            ShareStatus.partial => StatusKind.pending,
                            _ => StatusKind.neutral,
                          },
                          label: _shareLabel(loc, share.status),
                        ),
                        IconButton(
                          icon: const Icon(Icons.payments_outlined),
                          tooltip: loc.adminSocietyCostsRecordPayment,
                          onPressed: () =>
                              _openPaymentDialog(context, loc, bloc, share),
                        ),
                      ],
                    ),
                  ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cost.paymentSource == CostPaymentSource.memberBilled)
                    AppButton(
                      label: loc.adminSocietyCostsSplitAction,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          _openSplitDialog(context, loc, bloc, cost),
                    ),
                  AppButton(
                    label: loc.commonEdit,
                    variant: AppButtonVariant.ghost,
                    onPressed: () =>
                        _openCostForm(context, loc, bloc, editing: cost),
                  ),
                  AppButton(
                    label: loc.commonDelete,
                    variant: AppButtonVariant.ghost,
                    onPressed: () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: loc.adminSocietyCostsDeleteTitle,
                        message: loc.adminSocietyCostsDeleteMessage,
                        destructive: true,
                      );
                      if (confirmed && context.mounted) {
                        bloc.add(SocietyCostDeleted(cost: cost));
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _methodLabel(AppLocalizations loc, CostSplitMethod method) =>
      switch (method) {
        CostSplitMethod.equal => loc.adminSocietyCostsSplitMethodEqual,
        CostSplitMethod.byLandQuantity =>
          loc.adminSocietyCostsSplitMethodByLandQuantity,
        CostSplitMethod.manual => loc.adminSocietyCostsSplitMethodManual,
        _ => '—',
      };

  String _shareLabel(AppLocalizations loc, ShareStatus status) =>
      switch (status) {
        ShareStatus.paid => loc.adminSocietyCostsShareStatusPaid,
        ShareStatus.partial => loc.adminSocietyCostsShareStatusPartial,
        ShareStatus.unpaid => loc.adminSocietyCostsShareStatusUnpaid,
        _ => '—',
      };

  // ----- Create / edit form -----

  Future<void> _openCostForm(
      BuildContext context, AppLocalizations loc, SocietyCostsBloc bloc,
      {SocietyCost? editing}) async {
    final titleController = TextEditingController(text: editing?.title ?? '');
    final descriptionController =
        TextEditingController(text: editing?.description ?? '');
    final notesController = TextEditingController(text: editing?.notes ?? '');
    final amountController = TextEditingController(
        text: editing == null ? '' : '${editing.totalAmount}');
    var categoryId = editing?.categoryId?.toString() ?? '';
    var incurredDate = editing?.incurredDate ??
        DateTime.now().toIso8601String().substring(0, 10);
    var source = editing?.paymentSource ?? CostPaymentSource.societyFund;
    String? newCategoryValue;
    String? pickedReceipt;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editing == null
                      ? loc.adminSocietyCostsCreateTitle
                      : loc.adminSocietyCostsEditTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.adminSocietyCostsFormTitle,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: newCategoryValue ??
                      (categoryId.isEmpty ? null : categoryId),
                  decoration: InputDecoration(
                    labelText: loc.adminSocietyCostsFormCategory,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(loc.adminSocietyCostsFormNoCategory),
                    ),
                    for (final c in bloc.state.categories)
                      DropdownMenuItem<String>(
                          value: c.id, child: Text(c.label)),
                  ],
                  onChanged: (v) => setSheetState(() => categoryId = v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.adminSocietyCostsFormAmount,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DateField(
                  label: loc.adminSocietyCostsFormDate,
                  value: incurredDate,
                  onChanged: (v) => setSheetState(() => incurredDate = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CostPaymentSource>(
                  initialValue: source,
                  decoration: InputDecoration(
                    labelText: loc.adminSocietyCostsFormSource,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<CostPaymentSource>(
                      value: CostPaymentSource.societyFund,
                      child: Text(loc.adminSocietyCostsSourceSocietyFund),
                    ),
                    DropdownMenuItem<CostPaymentSource>(
                      value: CostPaymentSource.memberBilled,
                      child: Text(loc.adminSocietyCostsSourceMemberBilled),
                    ),
                  ],
                  onChanged: (v) => setSheetState(
                      () => source = v ?? CostPaymentSource.societyFund),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: loc.adminSocietyCostsFormDescription,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: loc.adminSocietyCostsFormNotes,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Optional new receipt.
                Row(
                  children: [
                    Expanded(
                      child: Text(pickedReceipt == null
                          ? loc.adminSocietyCostsFormReceipt
                          : pickedReceipt!.split('/').last),
                    ),
                    AppButton(
                      label: loc.adminSocietyCostsFormReceipt,
                      variant: AppButtonVariant.secondary,
                      icon: Icons.attach_file,
                      onPressed: () async {
                        final result = await FilePicker.platform
                            .pickFiles(type: FileType.any);
                        if (result != null) {
                          setSheetState(
                              () => pickedReceipt = result.files.single.path);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: loc.commonSave,
                    onPressed: () async {
                      final errors = <String>[];
                      if (titleController.text.trim().isEmpty) {
                        errors.add(loc.adminSocietyCostsErrorsTitleRequired);
                      }
                      final amount = num.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        errors.add(loc.adminSocietyCostsErrorsAmountRequired);
                      }
                      if (incurredDate.isEmpty) {
                        errors.add(loc.adminSocietyCostsErrorsDateRequired);
                      }
                      if (errors.isNotEmpty) {
                        showAppToast(sheetContext, errors.first, error: true);
                        return;
                      }
                      final ok = bloc.add(SocietyCostSaved(editingId: editing?.id, receiptPath: pickedReceipt, input: SocietyCostInput(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          categoryId: categoryId.isEmpty
                              ? null
                              : int.tryParse(categoryId),
                          totalAmount: amount!,
                          incurredDate: incurredDate,
                          paymentSource: source,
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        )));
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop(ok);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----- Split flow with live preview -----

  Future<void> _openSplitDialog(BuildContext context, AppLocalizations loc,
      SocietyCostsBloc bloc, SocietyCost cost) async {
    bloc.add(SocietySplitOpened(cost: cost));
    if (!context.mounted) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<SocietyCostsBloc, SocietyCostsState>(
          builder: (sheetContext, state) {
            final splitCost = state.splitCost;
            if (splitCost == null) return const SizedBox.shrink();
            final mismatch = bloc.manualMismatch;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.adminSocietyCostsSplitTitle}: ${splitCost.title}',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    Text(loc.adminSocietyCostsSplitSummaryLine(
                      splitCost.totalAmount,
                      _methodLabel(loc, state.splitMethod),
                    )),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CostSplitMethod>(
                      initialValue: state.splitMethod,
                      decoration: InputDecoration(
                        labelText: loc.adminSocietyCostsSplitMethod,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<CostSplitMethod>(
                          value: CostSplitMethod.equal,
                          child: Text(loc.adminSocietyCostsSplitMethodEqual),
                        ),
                        DropdownMenuItem<CostSplitMethod>(
                          value: CostSplitMethod.byLandQuantity,
                          child: Text(
                              loc.adminSocietyCostsSplitMethodByLandQuantity),
                        ),
                        DropdownMenuItem<CostSplitMethod>(
                          value: CostSplitMethod.manual,
                          child: Text(loc.adminSocietyCostsSplitMethodManual),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) bloc.add(SocietySplitMethodChanged(method: v));
                      },
                    ),
                    const SizedBox(height: 12),
                    if (state.splitLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.splitError != null)
                      InlineError(
                        message: loc.adminSocietyCostsErrorsSplitPreviewFailed,
                        onRetry: () => bloc.add(const SocietySplitPreviewRefreshed()),
                      )
                    else if (state.splitMethod == CostSplitMethod.manual &&
                        state.manualAmounts.isNotEmpty) ...[
                      for (final m in state.manualAmounts)
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: m.memberName,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) => bloc.add(SocietyManualAmountChanged(memberId: m.memberId, amount: num.tryParse(v))),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${loc.adminSocietyCostsSplitRunningTotal}: ${formatAmount(bloc.manualTotal)}',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                      if (mismatch)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            loc.adminSocietyCostsSplitMismatchWarning,
                            style: TextStyle(
                                color:
                                    Theme.of(sheetContext).colorScheme.error),
                          ),
                        ),
                    ] else ...[
                      // Live preview rows (equal / by-land-quantity).
                      for (final row in state.splitPreview)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(row.memberName),
                          trailing: Text(formatAmount(row.amountDue)),
                        ),
                      if (state.splitPreview.isEmpty)
                        Text(loc.adminSocietyCostsSplitNoMembers),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: loc.commonCancel,
                            variant: AppButtonVariant.secondary,
                            onPressed: () {
                              bloc.add(SocietySplitClosed());
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: loc.adminSocietyCostsSplitConfirm,
                            onPressed: state.busy
                                ? null
                                : () async {
                                    final ok = bloc.add(SocietySplitConfirmed(allowMismatch: mismatch));
                                    if (sheetContext.mounted && ok) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ----- Record share payment -----

  Future<void> _openPaymentDialog(BuildContext context, AppLocalizations loc,
      SocietyCostsBloc bloc, CostSplitShare share) async {
    final remaining = share.amountDue - share.amountPaid;
    final amountController =
        TextEditingController(text: '${remaining > 0 ? remaining : 0}');
    final receiptController =
        TextEditingController(text: share.receiptNo ?? '');

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.adminSocietyCostsPaymentTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${share.memberName ?? '#${share.memberId}'} · ${loc.adminSocietyCostsPaymentRemaining}: ${formatAmount(remaining)}',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.adminSocietyCostsPaymentAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: receiptController,
              decoration: InputDecoration(
                labelText: loc.adminPicnicPaymentsReceiptColumn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: loc.adminSocietyCostsRecordPayment,
                onPressed: () async {
                  final amount = num.tryParse(amountController.text);
                  if (amount == null || amount < 0) return;
                  final ok = bloc.add(SocietySharePaymentRecorded(share: share, additionalAmount: amount, receiptNo: receiptController.text.trim().isEmpty
                        ? null
                        : receiptController.text.trim()));
                  if (sheetContext.mounted && ok) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
