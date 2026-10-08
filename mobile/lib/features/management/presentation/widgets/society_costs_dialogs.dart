import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/finance_entities.dart';
import '../bloc/bloc_actions.dart';
import '../bloc/society_costs_bloc.dart';
import 'management_page_kit.dart';
import 'management_widgets.dart';
import 'society_costs_widgets.dart';

/// Create / edit cost, split-with-preview and record-share-payment sheets.

final _amountFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

Future<void> showSocietyCostSheet(
  BuildContext context, {
  required SocietyCostsBloc bloc,
  SocietyCost? editing,
}) {
  return showFormSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _SocietyCostForm(editing: editing),
    ),
  );
}

class _SocietyCostForm extends StatefulWidget {
  const _SocietyCostForm({this.editing});

  final SocietyCost? editing;

  @override
  State<_SocietyCostForm> createState() => _SocietyCostFormState();
}

class _SocietyCostFormState extends State<_SocietyCostForm> {
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late final _notes = TextEditingController(text: widget.editing?.notes ?? '');
  late final _amount = TextEditingController(
      text: widget.editing == null ? '' : '${widget.editing!.totalAmount}');
  late String? _categoryId = widget.editing?.categoryId?.toString();
  late String _date =
      widget.editing?.incurredDate ?? DateTime.now().toIso8601String().substring(0, 10);
  late CostPaymentSource _source =
      widget.editing?.paymentSource ?? CostPaymentSource.societyFund;
  String? _receiptPath;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<SocietyCostsBloc, SocietyCostsState>(
      builder: (context, state) => FormSheet(
        icon: Icons.receipt_outlined,
        title: widget.editing == null
            ? loc.adminSocietyCostsCreateTitle
            : loc.adminSocietyCostsEditTitle,
        actions: [
          AppButton(label: loc.commonSave, loading: state.busy, onPressed: _save),
        ],
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: loc.adminSocietyCostsFormTitle),
          ),
          FieldPair(
            first: TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_amountFormatter],
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                labelText: loc.adminSocietyCostsFormAmount,
                prefixText: '৳ ',
              ),
            ),
            second: DateField(
              label: loc.adminSocietyCostsFormDate,
              value: _date,
              onChanged: (v) => setState(() => _date = v),
            ),
          ),
          LabeledDropdown<String>(
            label: loc.adminSocietyCostsFormCategory,
            value: state.categories.any((c) => c.id == _categoryId) ? _categoryId : null,
            prefixIcon: Icons.sell_outlined,
            options: [
              (null, loc.adminSocietyCostsFormNoCategory),
              for (final c in state.categories) (c.id, c.label),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          _sourceSelector(loc),
          TextField(
            controller: _description,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(labelText: loc.adminSocietyCostsFormDescription),
          ),
          TextField(
            controller: _notes,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(labelText: loc.adminSocietyCostsFormNotes),
          ),
          _receiptPicker(loc),
        ],
      ),
    );
  }

  Widget _sourceSelector(AppLocalizations loc) {
    return LabeledDropdown<CostPaymentSource>(
      label: loc.adminSocietyCostsFormSource,
      value: _source,
      prefixIcon: Icons.account_tree_outlined,
      options: [
        for (final s in const [
          CostPaymentSource.societyFund,
          CostPaymentSource.memberBilled,
        ])
          (s, societySourceLabel(loc, s)),
      ],
      onChanged: (v) => setState(() => _source = v ?? CostPaymentSource.societyFund),
    );
  }

  Widget _receiptPicker(AppLocalizations loc) {
    return OutlinedButton.icon(
      icon: Icon(_receiptPath == null ? Icons.attach_file : Icons.check_circle_outline),
      label: Text(
        _receiptPath?.split(RegExp(r'[/\\]')).last ?? loc.adminSocietyCostsFormReceipt,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        if (result != null && mounted) {
          setState(() => _receiptPath = result.files.single.path);
        }
      },
    );
  }

  String? _validate(AppLocalizations loc, num? amount) {
    if (_title.text.trim().isEmpty) return loc.adminSocietyCostsErrorsTitleRequired;
    if (amount == null || amount <= 0) return loc.adminSocietyCostsErrorsAmountRequired;
    if (_date.isEmpty) return loc.adminSocietyCostsErrorsDateRequired;
    return null;
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final amount = num.tryParse(_amount.text);
    final error = _validate(loc, amount);
    if (error != null) {
      showAppToast(context, error, error: true);
      return;
    }
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final category = _categoryId;
    final ok = await dispatchForBool(
      context.read<SocietyCostsBloc>(),
      (c) => SocietyCostSaved(
        completer: c,
        editingId: widget.editing?.id,
        receiptPath: _receiptPath,
        input: SocietyCostInput(
          title: _title.text.trim(),
          description: optional(_description),
          categoryId: category == null || category.isEmpty ? null : int.tryParse(category),
          totalAmount: amount!,
          incurredDate: _date,
          paymentSource: _source,
          notes: optional(_notes),
        ),
      ),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }
}

// ----- Split flow with live preview -----

Future<void> showSocietySplitSheet(
  BuildContext context, {
  required SocietyCostsBloc bloc,
  required SocietyCost cost,
}) async {
  bloc.add(SocietySplitOpened(cost: cost));
  await showFormSheet<void>(
    context,
    builder: (_) => BlocProvider.value(value: bloc, child: const _SplitSheet()),
  );
  if (!bloc.isClosed) bloc.add(const SocietySplitClosed());
}

class _SplitSheet extends StatelessWidget {
  const _SplitSheet();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<SocietyCostsBloc>();
    return BlocBuilder<SocietyCostsBloc, SocietyCostsState>(
      builder: (context, state) {
        final cost = state.splitCost;
        if (cost == null) return const SizedBox(height: 120);
        final mismatch = bloc.manualMismatch;
        return FormSheet(
          icon: Icons.call_split_rounded,
          title: loc.adminSocietyCostsSplitTitle,
          subtitle: cost.title,
          actions: [
            AppButton(
              label: loc.commonCancel,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppButton(
              label: loc.adminSocietyCostsSplitConfirm,
              loading: state.busy,
              onPressed: () => _confirm(context, bloc, mismatch),
            ),
          ],
          children: [
            Text(
              loc.adminSocietyCostsSplitSummaryLine(
                societySplitMethodLabel(loc, state.splitMethod),
                formatAmount(cost.totalAmount),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            _MethodChips(selected: state.splitMethod),
            _SplitBody(state: state, mismatch: mismatch),
          ],
        );
      },
    );
  }

  Future<void> _confirm(
      BuildContext context, SocietyCostsBloc bloc, bool mismatch) async {
    final ok = await dispatchForBool(
      bloc,
      (c) => SocietySplitConfirmed(allowMismatch: mismatch, completer: c),
    );
    if (ok && context.mounted) Navigator.of(context).pop();
  }
}

class _MethodChips extends StatelessWidget {
  const _MethodChips({required this.selected});

  final CostSplitMethod selected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<SocietyCostsBloc>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final method in const [
          CostSplitMethod.equal,
          CostSplitMethod.byLandQuantity,
          CostSplitMethod.manual,
        ])
          ChoiceChip(
            label: Text(societySplitMethodLabel(loc, method)),
            selected: selected == method,
            onSelected: (_) => bloc.add(SocietySplitMethodChanged(method: method)),
          ),
      ],
    );
  }
}

class _SplitBody extends StatelessWidget {
  const _SplitBody({required this.state, required this.mismatch});

  final SocietyCostsState state;
  final bool mismatch;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<SocietyCostsBloc>();
    if (state.splitLoading) return const LinearProgressIndicator();
    if (state.splitError != null) {
      return InlineError(
        message: loc.adminSocietyCostsErrorsSplitPreviewFailed,
        onRetry: () => bloc.add(const SocietySplitPreviewRefreshed()),
      );
    }
    if (state.splitMethod == CostSplitMethod.manual && state.manualAmounts.isNotEmpty) {
      return _ManualAmounts(state: state, mismatch: mismatch);
    }
    if (state.splitPreview.isEmpty) return Text(loc.adminSocietyCostsSplitNoMembers);
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final row in state.splitPreview)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(row.memberName, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  formatAmount(row.amountDue),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ManualAmounts extends StatelessWidget {
  const _ManualAmounts({required this.state, required this.mismatch});

  final SocietyCostsState state;
  final bool mismatch;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<SocietyCostsBloc>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final m in state.manualAmounts)
          TextFormField(
            key: ValueKey(m.memberId),
            initialValue: m.amount?.toString() ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_amountFormatter],
            textAlign: TextAlign.end,
            decoration: InputDecoration(labelText: m.memberName, prefixText: '৳ '),
            onChanged: (v) => bloc.add(
                SocietyManualAmountChanged(memberId: m.memberId, amount: num.tryParse(v))),
          ),
        Text(
          '${loc.adminSocietyCostsSplitRunningTotal}: ${formatAmount(bloc.manualTotal)}',
          textAlign: TextAlign.end,
          style: theme.textTheme.titleSmall,
        ),
        if (mismatch)
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.adminSocietyCostsSplitMismatchWarning,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ----- Record share payment -----

Future<void> showSocietyPaymentSheet(
  BuildContext context, {
  required SocietyCostsBloc bloc,
  required CostSplitShare share,
}) {
  return showFormSheet<void>(
    context,
    builder: (_) => BlocProvider.value(value: bloc, child: _PaymentForm(share: share)),
  );
}

class _PaymentForm extends StatefulWidget {
  const _PaymentForm({required this.share});

  final CostSplitShare share;

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  late final num _remaining = widget.share.amountDue - widget.share.amountPaid;
  late final _amount = TextEditingController(text: '${_remaining > 0 ? _remaining : 0}');
  late final _receipt = TextEditingController(text: widget.share.receiptNo ?? '');
  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    _receipt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final share = widget.share;
    return BlocBuilder<SocietyCostsBloc, SocietyCostsState>(
      builder: (context, state) => FormSheet(
        icon: Icons.payments_outlined,
        title: loc.adminSocietyCostsPaymentTitle,
        subtitle:
            '${share.memberName ?? '#${share.memberId}'} · ${loc.adminSocietyCostsPaymentRemaining}: ${formatAmount(_remaining)}',
        actions: [
          AppButton(
            label: loc.adminSocietyCostsRecordPayment,
            loading: state.busy,
            onPressed: _submit,
          ),
        ],
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_amountFormatter],
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              labelText: loc.adminSocietyCostsPaymentAmount,
              prefixText: '৳ ',
              errorText: _amountError,
            ),
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          TextField(
            controller: _receipt,
            decoration: InputDecoration(labelText: loc.adminPicnicPaymentsReceiptColumn),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amount.text);
    if (amount == null || amount < 0) {
      setState(() => _amountError = AppLocalizations.of(context).adminSocietyCostsErrorsAmountRequired);
      return;
    }
    final receipt = _receipt.text.trim();
    final ok = await dispatchForBool(
      context.read<SocietyCostsBloc>(),
      (c) => SocietySharePaymentRecorded(
        completer: c,
        share: widget.share,
        additionalAmount: amount,
        receiptNo: receipt.isEmpty ? null : receipt,
      ),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }
}
