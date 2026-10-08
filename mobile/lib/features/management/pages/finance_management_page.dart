import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/finance_cubit.dart';
import '../presentation/widgets/management_widgets.dart';

/// Finance management (Angular finance-management): overview cards, filters,
/// ledger with pagination, transaction CRUD + workflow actions, unlinked
/// payment linking, report notice publishing.
class FinanceManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const FinanceManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<FinanceManagementPage> createState() => _FinanceManagementPageState();
}

class _FinanceManagementPageState extends State<FinanceManagementPage> {
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
      create: (_) => FinanceCubit(
        adminRepository: AdminRepository(apiClient: sl<ApiClient>()),
        financeRepository: FinanceRepository(apiClient: sl<ApiClient>()),
      )..init(),
      child: BlocConsumer<FinanceCubit, FinanceState>(
        listener: (context, state) {
          if (state.actionError != null) {
            showAppToast(context, describeApiError(context, state.actionError),
                error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<FinanceCubit>();
          final ledger = state.ledger;
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminFinanceManagementTitle,
                  subtitle: loc.adminFinanceManagementSubtitle),
              // Overview.
              if (state.overview != null)
                AppCard(
                  title: loc.adminFinanceManagementOverviewRecent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.adminFinanceManagementOverviewPending,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text('${state.overview!.pendingCount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.adminFinanceManagementOverviewMonthNet,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text(
                                  formatTaka(state.overview!.monthNet,
                                      decimals: 0),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.adminFinanceManagementOverviewBalance,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text(
                                  formatTaka(state.overview!.balance,
                                      decimals: 0),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Filters.
              AppCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<FinanceStatus?>(
                      initialValue: state.statusFilter,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementStatusAll,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<FinanceStatus?>(
                          value: null,
                          child: Text(loc.adminFinanceManagementStatusAll),
                        ),
                        DropdownMenuItem<FinanceStatus?>(
                          value: FinanceStatus.pending,
                          child: Text(loc.adminFinanceManagementStatusPending),
                        ),
                        DropdownMenuItem<FinanceStatus?>(
                          value: FinanceStatus.draft,
                          child: Text(loc.adminFinanceManagementStatusDraft),
                        ),
                        DropdownMenuItem<FinanceStatus?>(
                          value: FinanceStatus.approved,
                          child: Text(loc.adminFinanceManagementStatusApproved),
                        ),
                        DropdownMenuItem<FinanceStatus?>(
                          value: FinanceStatus.rejected,
                          child: Text(loc.adminFinanceManagementStatusRejected),
                        ),
                      ],
                      onChanged: (v) => cubit.setFilters(statusFilter: v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FinanceType?>(
                      initialValue: state.typeFilter,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFiltersType,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<FinanceType?>(
                          value: null,
                          child:
                              Text(loc.adminFinanceManagementFiltersAllTypes),
                        ),
                        DropdownMenuItem<FinanceType?>(
                          value: FinanceType.income,
                          child: Text(loc.adminFinanceManagementTypeIncome),
                        ),
                        DropdownMenuItem<FinanceType?>(
                          value: FinanceType.expense,
                          child: Text(loc.adminFinanceManagementTypeExpense),
                        ),
                      ],
                      onChanged: (v) => cubit.setFilters(typeFilter: v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DateField(
                            label: loc.adminFinanceManagementLedgerDate,
                            value: state.dateFrom,
                            onChanged: (v) {
                              cubit.setDateRange(from: v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DateField(
                            label: loc.adminFinanceManagementLedgerDate,
                            value: state.dateTo,
                            onChanged: (v) {
                              cubit.setDateRange(to: v);
                              cubit.refresh();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFiltersSearch,
                        border: const OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (v) => cubit.setFilters(search: v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: loc.adminFinanceManagementCreate,
                            onPressed: () => _openForm(context, loc, cubit),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: loc.adminFinanceManagementFiltersReset,
                            variant: AppButtonVariant.secondary,
                            onPressed: () {
                              _searchController.clear();
                              cubit.resetFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Publish report notice.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: state.noticeDone
                            ? loc.adminFinanceManagementNoticeDone
                            : loc.adminFinanceManagementNoticePublish,
                        variant: AppButtonVariant.secondary,
                        onPressed: state.busy
                            ? null
                            : () => cubit.publishReportNotice(),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 6)
              else if (state.error != null)
                InlineError(
                    message: loc.adminFinanceManagementErrorsLoadFailed,
                    onRetry: cubit.refresh)
              else if (ledger == null || ledger.items.isEmpty)
                EmptyState(message: loc.adminFinanceManagementLedgerEmpty)
              else ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                      loc.adminFinanceManagementLedgerCount(ledger.total),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                for (final txn in ledger.items)
                  _txnCard(context, loc, cubit, txn),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed:
                          state.page > 1 ? () => cubit.changePage(-1) : null,
                    ),
                    Text(loc.adminFinanceManagementLedgerPage(
                        state.page, cubit.totalPages)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: state.page < cubit.totalPages
                          ? () => cubit.changePage(1)
                          : null,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _txnCard(BuildContext context, AppLocalizations loc,
      FinanceCubit cubit, FinanceTransaction txn) {
    final expanded = cubit.state.expandedId == txn.id;
    final sign = txn.type == FinanceType.income ? '+' : '−';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => cubit.toggleExpanded(txn.id),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.description,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${txn.txnDate} · ${txn.categoryLabel ?? '—'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$sign ${formatTaka(txn.amount, decimals: 0)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            const SizedBox(height: 6),
            StatusBadge(
              kind: switch (txn.status) {
                FinanceStatus.approved => StatusKind.approved,
                FinanceStatus.pending => StatusKind.pending,
                FinanceStatus.rejected => StatusKind.rejected,
                _ => StatusKind.neutral,
              },
              label: switch (txn.status) {
                FinanceStatus.approved =>
                  loc.adminFinanceManagementStatusApproved,
                FinanceStatus.pending =>
                  loc.adminFinanceManagementStatusPending,
                FinanceStatus.rejected =>
                  loc.adminFinanceManagementStatusRejected,
                _ => loc.adminFinanceManagementStatusDraft,
              },
            ),
            if (expanded) ...[
              InfoRow(
                  label: loc.adminFinanceManagementLedgerReference,
                  value: txn.referenceNo ?? '—'),
              if (txn.internalNotes != null)
                InfoRow(
                    label: loc.adminFinanceManagementLedgerInternalNotes,
                    value: txn.internalNotes!),
              if (txn.rejectionReason != null)
                InfoRow(
                    label: loc.adminFinanceManagementLedgerRejectionReason,
                    value: txn.rejectionReason!),
              if (txn.approvedByName != null)
                InfoRow(
                    label: loc.adminFinanceManagementLedgerApprovedBy,
                    value: '${txn.approvedByName} · ${txn.approvedAt ?? ''}'),
              if (txn.createdByName != null)
                InfoRow(
                    label: loc.adminFinanceManagementLedgerCreatedBy,
                    value: txn.createdByName!),
              if (txn.linkedPaymentType != null)
                InfoRow(
                  label: loc.adminFinanceManagementLedgerLinkedPayment,
                  value:
                      '${_sourceLabel(loc, txn.linkedPaymentType!)} #${txn.linkedPaymentId}',
                ),
              if (txn.attachmentUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: AppButton(
                    label: loc.adminFinanceManagementLedgerViewAttachment,
                    variant: AppButtonVariant.ghost,
                    icon: Icons.attach_file,
                    onPressed: () => showImagePreview(
                        context, txn.attachmentUrl!, txn.description),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (txn.status == FinanceStatus.draft)
                    AppButton(
                      label: loc.adminFinanceManagementActionsSubmit,
                      variant: AppButtonVariant.ghost,
                      onPressed: cubit.state.busy
                          ? null
                          : () => cubit.submitDraft(txn),
                    ),
                  if (txn.status == FinanceStatus.pending)
                    AppButton(
                      label: loc.adminFinanceManagementActionsApprove,
                      variant: AppButtonVariant.ghost,
                      onPressed: cubit.state.busy
                          ? null
                          : () async {
                              final confirmed = await confirmDialog(
                                context,
                                title: loc
                                    .adminFinanceManagementModalsApproveTitle,
                                message: loc
                                    .adminFinanceManagementModalsApproveConfirm,
                              );
                              if (confirmed && context.mounted) {
                                await cubit.approve(txn);
                              }
                            },
                    ),
                  if (txn.status == FinanceStatus.pending ||
                      txn.status == FinanceStatus.approved)
                    AppButton(
                      label: loc.adminFinanceManagementActionsReject,
                      variant: AppButtonVariant.ghost,
                      onPressed: cubit.state.busy
                          ? null
                          : () => _reasonDialog(
                              context, loc, cubit, txn, _FinanceAction.reject),
                    ),
                  if (txn.status == FinanceStatus.approved)
                    AppButton(
                      label: loc.adminFinanceManagementActionsReverse,
                      variant: AppButtonVariant.ghost,
                      onPressed: cubit.state.busy
                          ? null
                          : () => _reasonDialog(
                              context, loc, cubit, txn, _FinanceAction.reverse),
                    ),
                  AppButton(
                    label: loc.commonEdit,
                    variant: AppButtonVariant.ghost,
                    onPressed: cubit.state.busy
                        ? null
                        : () => _openForm(context, loc, cubit, editing: txn),
                  ),
                  AppButton(
                    label: loc.commonDelete,
                    variant: AppButtonVariant.ghost,
                    onPressed: cubit.state.busy
                        ? null
                        : () => _reasonDialog(
                            context, loc, cubit, txn, _FinanceAction.delete),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sourceLabel(AppLocalizations loc, PaymentSourceType source) =>
      switch (source) {
        PaymentSourceType.installment =>
          loc.adminFinanceManagementSourceInstallment,
        PaymentSourceType.picnicPayment =>
          loc.adminFinanceManagementSourcePicnicPayment,
        PaymentSourceType.costShare =>
          loc.adminFinanceManagementSourceCostShare,
        _ => '—',
      };

  Future<void> _reasonDialog(BuildContext context, AppLocalizations loc,
      FinanceCubit cubit, FinanceTransaction txn, _FinanceAction action) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (action) {
          _FinanceAction.reject => loc.adminFinanceManagementModalsRejectTitle,
          _FinanceAction.reverse =>
            loc.adminFinanceManagementModalsReverseTitle,
          _FinanceAction.delete => loc.adminFinanceManagementModalsDeleteTitle,
        }),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: switch (action) {
              _FinanceAction.reject =>
                loc.adminFinanceManagementModalsRejectReason,
              _FinanceAction.reverse =>
                loc.adminFinanceManagementModalsReverseReason,
              _FinanceAction.delete =>
                loc.adminFinanceManagementModalsDeleteReason,
            },
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.commonConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final reason = controller.text.trim();
    if (reason.isEmpty) {
      showAppToast(context, loc.adminFinanceManagementErrorsReasonRequired,
          error: true);
      return;
    }
    final ok = switch (action) {
      _FinanceAction.reject => await cubit.reject(txn, reason),
      _FinanceAction.reverse => await cubit.reverse(txn, reason),
      _FinanceAction.delete => await cubit.delete(txn, reason),
    };
    if (ok && context.mounted) showAppToast(context, loc.commonSave);
  }

  // ----- Create / edit -----

  Future<void> _openForm(
      BuildContext context, AppLocalizations loc, FinanceCubit cubit,
      {FinanceTransaction? editing}) async {
    final type = editing?.type ?? FinanceType.income;
    final dateController = TextEditingController(
        text: editing?.txnDate ??
            DateTime.now().toIso8601String().substring(0, 10));
    final amountController =
        TextEditingController(text: editing == null ? '' : '${editing.amount}');
    final descriptionController =
        TextEditingController(text: editing?.description ?? '');
    final referenceController =
        TextEditingController(text: editing?.referenceNo ?? '');
    final notesController =
        TextEditingController(text: editing?.internalNotes ?? '');
    var categoryId = editing?.categoryId;
    String? pickedAttachment;
    // Payment linking (income only, create only).
    var linkPayment = false;
    UnlinkedPayment? selectedPayment;
    PaymentSourceType? sourceFilter;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            var currentType = type;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing == null
                          ? loc.adminFinanceManagementCreateTitle
                          : loc.adminFinanceManagementEditTitle,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<FinanceType>(
                      segments: [
                        ButtonSegment(
                          value: FinanceType.income,
                          label: Text(loc.adminFinanceManagementTypeIncome),
                        ),
                        ButtonSegment(
                          value: FinanceType.expense,
                          label: Text(loc.adminFinanceManagementTypeExpense),
                        ),
                      ],
                      selected: {currentType},
                      onSelectionChanged: (selection) => setSheetState(() {
                        currentType = selection.first;
                        categoryId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFormDate,
                        border: const OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: DateTime.tryParse(dateController.text) ??
                              DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          dateController.text =
                              picked.toIso8601String().substring(0, 10);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFormCategory,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in cubit.state.categories)
                          if (c.type == currentType && c.isActive)
                            DropdownMenuItem<int>(
                                value: c.id, child: Text(c.label)),
                      ],
                      onChanged: (v) => setSheetState(() => categoryId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFormAmount,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFormDescription,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: referenceController,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFormReference,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: loc.adminFinanceManagementFormInternalNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Attachment.
                    Row(
                      children: [
                        Expanded(
                          child: Text(pickedAttachment == null
                              ? loc.adminFinanceManagementFormAttachment
                              : pickedAttachment!.split('/').last),
                        ),
                        AppButton(
                          label: loc.adminFinanceManagementFormAttachment,
                          variant: AppButtonVariant.secondary,
                          icon: Icons.attach_file,
                          onPressed: () async {
                            final result = await FilePicker.platform
                                .pickFiles(type: FileType.any);
                            if (result != null) {
                              setSheetState(() =>
                                  pickedAttachment = result.files.single.path);
                            }
                          },
                        ),
                      ],
                    ),
                    // Payment linking for incomes (create only).
                    if (editing == null &&
                        currentType == FinanceType.income) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: linkPayment,
                        title: Text(loc.adminFinanceManagementPaymentLinkTitle),
                        onChanged: (v) {
                          setSheetState(() => linkPayment = v ?? false);
                          if (linkPayment) {
                            cubit.loadUnlinkedPayments();
                          }
                        },
                      ),
                      if (linkPayment) ...[
                        DropdownButtonFormField<PaymentSourceType?>(
                          initialValue: sourceFilter,
                          decoration: InputDecoration(
                            labelText:
                                loc.adminFinanceManagementPaymentLinkAllSources,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<PaymentSourceType?>(
                              value: null,
                              child: Text(loc
                                  .adminFinanceManagementPaymentLinkAllSources),
                            ),
                            DropdownMenuItem<PaymentSourceType?>(
                              value: PaymentSourceType.installment,
                              child: Text(
                                  loc.adminFinanceManagementSourceInstallment),
                            ),
                            DropdownMenuItem<PaymentSourceType?>(
                              value: PaymentSourceType.picnicPayment,
                              child: Text(loc
                                  .adminFinanceManagementSourcePicnicPayment),
                            ),
                            DropdownMenuItem<PaymentSourceType?>(
                              value: PaymentSourceType.costShare,
                              child: Text(
                                  loc.adminFinanceManagementSourceCostShare),
                            ),
                          ],
                          onChanged: (v) {
                            setSheetState(() => sourceFilter = v);
                            cubit.loadUnlinkedPayments(sourceType: v);
                          },
                        ),
                        if (cubit.state.unlinkedLoading)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (cubit.state.unlinkedPayments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                                loc.adminFinanceManagementPaymentLinkEmpty),
                          )
                        else
                          for (final payment
                              in cubit.state.unlinkedPayments)
                            ListTile(
                              dense: true,
                              leading: Icon(selectedPayment == payment
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked),
                              title: Text(
                                  '${payment.memberName ?? '—'} · ${formatTaka(payment.amount, decimals: 0)}'),
                              subtitle: Text(payment.detail),
                              onTap: () => setSheetState(() {
                                selectedPayment = payment;
                                amountController.text = '${payment.amount}';
                                dateController.text =
                                    payment.paidOn.substring(0, 10);
                                descriptionController.text = payment.detail;
                              }),
                            ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: loc.adminFinanceManagementActionsSaveDraft,
                            variant: AppButtonVariant.secondary,
                            onPressed: cubit.state.busy
                                ? null
                                : () => _submit(sheetContext, loc, cubit,
                                    editing: editing,
                                    type: currentType,
                                    dateController: dateController,
                                    amountController: amountController,
                                    descriptionController:
                                        descriptionController,
                                    referenceController: referenceController,
                                    notesController: notesController,
                                    categoryId: categoryId,
                                    attachmentPath: pickedAttachment,
                                    selectedPayment: selectedPayment,
                                    saveAsPending: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: loc.adminFinanceManagementActionsSavePending,
                            onPressed: cubit.state.busy
                                ? null
                                : () => _submit(sheetContext, loc, cubit,
                                    editing: editing,
                                    type: currentType,
                                    dateController: dateController,
                                    amountController: amountController,
                                    descriptionController:
                                        descriptionController,
                                    referenceController: referenceController,
                                    notesController: notesController,
                                    categoryId: categoryId,
                                    attachmentPath: pickedAttachment,
                                    selectedPayment: selectedPayment,
                                    saveAsPending: true),
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

  Future<void> _submit(
    BuildContext sheetContext,
    AppLocalizations loc,
    FinanceCubit cubit, {
    required FinanceTransaction? editing,
    required FinanceType type,
    required TextEditingController dateController,
    required TextEditingController amountController,
    required TextEditingController descriptionController,
    required TextEditingController referenceController,
    required TextEditingController notesController,
    required int? categoryId,
    required String? attachmentPath,
    required UnlinkedPayment? selectedPayment,
    required bool saveAsPending,
  }) async {
    final amount = num.tryParse(amountController.text);
    final errors = <String>[];
    if (dateController.text.isEmpty)
      errors.add(loc.adminFinanceManagementErrorsDateRequired);
    if (amount == null || amount <= 0)
      errors.add(loc.adminFinanceManagementErrorsAmountRequired);
    if (descriptionController.text.trim().isEmpty) {
      errors.add(loc.adminFinanceManagementErrorsDescriptionRequired);
    }
    if (categoryId == null)
      errors.add(loc.adminFinanceManagementErrorsCategoryRequired);
    if (errors.isNotEmpty) {
      showAppToast(sheetContext, errors.first, error: true);
      return;
    }
    final ok = await cubit.saveTransaction(
      editingId: editing?.id,
      attachmentPath: attachmentPath,
      input: FinanceTransactionInput(
        txnDate: dateController.text,
        type: type,
        categoryId: categoryId!,
        amount: amount!,
        description: descriptionController.text.trim(),
        referenceNo: referenceController.text.trim().isEmpty
            ? null
            : referenceController.text.trim(),
        internalNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        status: editing == null
            ? (saveAsPending ? FinanceStatus.pending : FinanceStatus.draft)
            : null,
        linkedPaymentType: editing == null &&
                type == FinanceType.income &&
                selectedPayment != null
            ? selectedPayment.sourceType
            : null,
        linkedPaymentId: editing == null &&
                type == FinanceType.income &&
                selectedPayment != null
            ? selectedPayment.sourceId
            : null,
      ),
    );
    if (sheetContext.mounted && ok) Navigator.of(sheetContext).pop();
  }
}

enum _FinanceAction { reject, reverse, delete }
