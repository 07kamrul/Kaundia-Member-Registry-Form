import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/finance_entities.dart';
import '../bloc/bloc_actions.dart';
import '../bloc/finance_bloc.dart';
import 'finance_management_widgets.dart';
import 'management_page_kit.dart';
import 'management_widgets.dart';

/// Opens the create / edit transaction sheet.
Future<void> showFinanceTransactionSheet(
  BuildContext context, {
  required FinanceBloc bloc,
  FinanceTransaction? editing,
}) {
  return showFormSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: FinanceTransactionSheet(editing: editing),
    ),
  );
}

class FinanceTransactionSheet extends StatefulWidget {
  const FinanceTransactionSheet({super.key, this.editing});

  final FinanceTransaction? editing;

  @override
  State<FinanceTransactionSheet> createState() => _FinanceTransactionSheetState();
}

class _FinanceTransactionSheetState extends State<FinanceTransactionSheet> {
  late FinanceType _type = widget.editing?.type ?? FinanceType.income;
  late String _date =
      widget.editing?.txnDate ?? DateTime.now().toIso8601String().substring(0, 10);
  late final _amount = TextEditingController(
      text: widget.editing == null ? '' : '${widget.editing!.amount}');
  late final _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late final _reference = TextEditingController(text: widget.editing?.referenceNo ?? '');
  late final _notes = TextEditingController(text: widget.editing?.internalNotes ?? '');
  late int? _categoryId = widget.editing?.categoryId;
  String? _attachmentPath;
  bool _linkPayment = false;
  UnlinkedPayment? _selectedPayment;
  PaymentSourceType? _sourceFilter;

  bool get _isCreate => widget.editing == null;
  bool get _canLink => _isCreate && _type == FinanceType.income;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) => FormSheet(
        icon: Icons.receipt_long_outlined,
        title: _isCreate
            ? loc.adminFinanceManagementCreateTitle
            : loc.adminFinanceManagementEditTitle,
        actions: [
          AppButton(
            label: loc.adminFinanceManagementActionsSaveDraft,
            variant: AppButtonVariant.secondary,
            onPressed: state.busy ? null : () => _submit(saveAsPending: false),
          ),
          AppButton(
            label: loc.adminFinanceManagementActionsSavePending,
            loading: state.busy,
            onPressed: () => _submit(saveAsPending: true),
          ),
        ],
        children: [
          _typeSelector(loc),
          FieldPair(
            first: DateField(
              label: loc.adminFinanceManagementFormDate,
              value: _date,
              onChanged: (v) => setState(() => _date = v),
            ),
            second: _amountField(loc),
          ),
          _categoryField(loc, state),
          TextField(
            controller: _description,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                InputDecoration(labelText: loc.adminFinanceManagementFormDescription),
          ),
          TextField(
            controller: _reference,
            decoration: InputDecoration(
              labelText: loc.adminFinanceManagementFormReference,
              helperText: loc.adminFinanceManagementFormReferenceHint,
              helperMaxLines: 2,
            ),
          ),
          TextField(
            controller: _notes,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: loc.adminFinanceManagementFormInternalNotes,
              helperText: loc.adminFinanceManagementFormInternalNotesHint,
              helperMaxLines: 2,
            ),
          ),
          _attachmentPicker(loc),
          if (_canLink) ..._paymentLinking(loc, state),
        ],
      ),
    );
  }

  Widget _typeSelector(AppLocalizations loc) {
    return SegmentedButton<FinanceType>(
      segments: [
        ButtonSegment(
          value: FinanceType.income,
          icon: const Icon(Icons.south_west_rounded),
          label: Text(loc.adminFinanceManagementTypeIncome),
        ),
        ButtonSegment(
          value: FinanceType.expense,
          icon: const Icon(Icons.north_east_rounded),
          label: Text(loc.adminFinanceManagementTypeExpense),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (selection) => setState(() {
        _type = selection.first;
        _categoryId = null;
      }),
    );
  }

  Widget _amountField(AppLocalizations loc) {
    return TextField(
      controller: _amount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.end,
      decoration: InputDecoration(
        labelText: loc.adminFinanceManagementFormAmount,
        prefixText: '৳ ',
      ),
    );
  }

  Widget _categoryField(AppLocalizations loc, FinanceState state) {
    final options = [
      for (final c in state.categories)
        if (c.type == _type && c.isActive) (c.id, c.label),
    ];
    return LabeledDropdown<int>(
      label: loc.adminFinanceManagementFormCategory,
      value: options.any((o) => o.$1 == _categoryId) ? _categoryId : null,
      prefixIcon: Icons.sell_outlined,
      options: options,
      onChanged: (v) => setState(() => _categoryId = v),
    );
  }

  Widget _attachmentPicker(AppLocalizations loc) {
    return OutlinedButton.icon(
      icon: Icon(_attachmentPath == null ? Icons.attach_file : Icons.check_circle_outline),
      label: Text(
        _attachmentPath?.split(RegExp(r'[/\\]')).last ??
            loc.adminFinanceManagementFormAttachment,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        if (result != null && mounted) {
          setState(() => _attachmentPath = result.files.single.path);
        }
      },
    );
  }

  List<Widget> _paymentLinking(AppLocalizations loc, FinanceState state) {
    final bloc = context.read<FinanceBloc>();
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _linkPayment,
        title: Text(loc.adminFinanceManagementPaymentLinkTitle),
        onChanged: (v) {
          setState(() => _linkPayment = v);
          if (v) bloc.add(const FinanceUnlinkedPaymentsRequested());
        },
      ),
      if (_linkPayment) ...[
        LabeledDropdown<PaymentSourceType>(
          label: loc.adminFinanceManagementPaymentLinkAllSources,
          value: _sourceFilter,
          options: [
            (null, loc.adminFinanceManagementPaymentLinkAllSources),
            for (final s in const [
              PaymentSourceType.installment,
              PaymentSourceType.picnicPayment,
              PaymentSourceType.costShare,
            ])
              (s, financeSourceLabel(loc, s)),
          ],
          onChanged: (v) {
            setState(() => _sourceFilter = v);
            bloc.add(FinanceUnlinkedPaymentsRequested(sourceType: v));
          },
        ),
        _unlinkedList(loc, state),
      ],
    ];
  }

  Widget _unlinkedList(AppLocalizations loc, FinanceState state) {
    if (state.unlinkedLoading) return const LinearProgressIndicator();
    if (state.unlinkedPayments.isEmpty) {
      return Text(
        loc.adminFinanceManagementPaymentLinkEmpty,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final payment in state.unlinkedPayments)
          ListTile(
            dense: true,
            selected: _selectedPayment == payment,
            selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.5),
            leading: Icon(_selectedPayment == payment
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked),
            title: Text(
              payment.memberName ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(payment.detail, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Text(
              formatTaka(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: () => _selectPayment(payment),
          ),
      ],
    );
  }

  void _selectPayment(UnlinkedPayment payment) {
    setState(() {
      _selectedPayment = payment;
      _amount.text = '${payment.amount}';
      _date = payment.paidOn.substring(0, 10);
      _description.text = payment.detail;
    });
  }

  String? _validate(AppLocalizations loc, num? amount) {
    if (_date.isEmpty) return loc.adminFinanceManagementErrorsDateRequired;
    if (amount == null || amount <= 0) {
      return loc.adminFinanceManagementErrorsAmountRequired;
    }
    if (_description.text.trim().isEmpty) {
      return loc.adminFinanceManagementErrorsDescriptionRequired;
    }
    if (_categoryId == null) return loc.adminFinanceManagementErrorsCategoryRequired;
    return null;
  }

  Future<void> _submit({required bool saveAsPending}) async {
    final loc = AppLocalizations.of(context);
    final amount = num.tryParse(_amount.text);
    final error = _validate(loc, amount);
    if (error != null) {
      showAppToast(context, error, error: true);
      return;
    }
    final editing = widget.editing;
    final linked = _canLink ? _selectedPayment : null;
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final ok = await dispatchForBool(
      context.read<FinanceBloc>(),
      (c) => FinanceTransactionSaved(
        completer: c,
        editingId: editing?.id,
        attachmentPath: _attachmentPath,
        input: FinanceTransactionInput(
          txnDate: _date,
          type: _type,
          categoryId: _categoryId!,
          amount: amount!,
          description: _description.text.trim(),
          referenceNo: optional(_reference),
          internalNotes: optional(_notes),
          status: editing == null
              ? (saveAsPending ? FinanceStatus.pending : FinanceStatus.draft)
              : null,
          linkedPaymentType: linked?.sourceType,
          linkedPaymentId: linked?.sourceId,
        ),
      ),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }
}
