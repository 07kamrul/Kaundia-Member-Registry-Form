import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/payment_entities.dart';
import '../bloc/installments_bloc.dart';

String monthLabel(int month, AppLocalizations loc) => switch (month) {
      1 => loc.commonMonthsJanuary,
      2 => loc.commonMonthsFebruary,
      3 => loc.commonMonthsMarch,
      4 => loc.commonMonthsApril,
      5 => loc.commonMonthsMay,
      6 => loc.commonMonthsJune,
      7 => loc.commonMonthsJuly,
      8 => loc.commonMonthsAugust,
      9 => loc.commonMonthsSeptember,
      10 => loc.commonMonthsOctober,
      11 => loc.commonMonthsNovember,
      _ => loc.commonMonthsDecember,
    };


/// Three-step "pay dues" flow rendered as a modal sheet (pick months -> send
/// money to a society account -> report the transaction). Mirrors the Angular
/// PayDuesDialogComponent; state lives in [InstallmentsBloc].
class PayDuesDialog extends StatefulWidget {
  const PayDuesDialog({super.key, required this.summary});

  final PayableSummary summary;

  @override
  State<PayDuesDialog> createState() => _PayDuesDialogState();
}

class _PayDuesDialogState extends State<PayDuesDialog> {
  int _step = 1;
  final Set<String> _selectedIds = {};
  String _method = '';
  final _transactionRef = TextEditingController();
  final _senderAccount = TextEditingController();
  final _note = TextEditingController();
  DateTime _paidOn = DateTime.now();
  String? _proofPath;
  String? _proofError;

  static final RegExp _refPattern = RegExp(r'^[A-Za-z0-9\-_/ ]{4,64}$');

  @override
  void initState() {
    super.initState();
    final pending = widget.summary.pendingInstallmentIds;
    for (final i in widget.summary.due) {
      if (!pending.contains(i.id)) _selectedIds.add(i.id);
    }
    _method = widget.summary.accounts.first.method;
  }

  @override
  void dispose() {
    _transactionRef.dispose();
    _senderAccount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<PayableInstallment> get _payable {
    final pending = widget.summary.pendingInstallmentIds;
    return widget.summary.due.where((i) => !pending.contains(i.id)).toList();
  }

  num get _selectedTotal => _payable
      .where((i) => _selectedIds.contains(i.id))
      .fold<num>(0, (s, i) => s + i.amount);

  bool get _refValid => _refPattern.hasMatch(_transactionRef.text.trim());

  bool get _canSubmit => _refValid && !(_proofError?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(loc.memberPayDuesTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text('${loc.memberPayDuesTotalLabel}: ৳ $_selectedTotal'),
                    const SizedBox(height: 12),
                    if (_step == 1) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _selectedIds.length == _payable.length &&
                                _payable.isNotEmpty,
                            onChanged: (_) => setState(() {
                              if (_selectedIds.length == _payable.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds
                                  ..clear()
                                  ..addAll(_payable.map((i) => i.id));
                              }
                            }),
                          ),
                          Expanded(child: Text(loc.memberPayDuesSelectAll)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final i in _payable)
                              CheckboxListTile(
                                dense: true,
                                title: Text(
                                    '${monthLabel(i.month, AppLocalizations.of(context))} ${i.year}'),
                                subtitle: Text('৳ ${i.amount}'),
                                value: _selectedIds.contains(i.id),
                                onChanged: (v) => setState(() =>
                                    v == true ? _selectedIds.add(i.id) : _selectedIds.remove(i.id)),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (_step == 2) ...[
                      Text(loc.memberPayDuesSendTo,
                          style: Theme.of(context).textTheme.titleSmall),
                      for (final account in widget.summary.accounts)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            account.method == _method
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          onTap: () => setState(() => _method = account.method),
                          title: Text(account.method),
                          subtitle: Text(account.details),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: loc.memberPayDuesCopy,
                            onPressed: () => showAppToast(context, loc.memberPayDuesCopied),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(loc.memberPayDuesMethodHint,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                    if (_step == 3) ...[
                      TextField(
                        controller: _transactionRef,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: loc.memberPayDuesTransactionRef,
                          errorText: _transactionRef.text.isNotEmpty && !_refValid
                              ? loc.memberPayDuesTransactionRefError
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                                '${loc.memberPayDuesPaidOn}: ${_paidOn.toIso8601String().substring(0, 10)}'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                initialDate: _paidOn,
                              );
                              if (picked != null) setState(() => _paidOn = picked);
                            },
                            child: Text(loc.commonSelect),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _senderAccount,
                        decoration: InputDecoration(
                          labelText: loc.memberPayDuesSenderAccount,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _note,
                        decoration: InputDecoration(
                          labelText: loc.memberPayDuesNote,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(_proofPath ?? loc.memberPayDuesProofHint,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                          AppButton(
                            label: loc.memberPayDuesProof,
                            variant: AppButtonVariant.ghost,
                            icon: Icons.attach_file,
                            onPressed: _pickProof,
                          ),
                        ],
                      ),
                      if (_proofError != null)
                        Text(_proofError!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label:
                                _step == 1 ? loc.commonCancel : loc.memberPayDuesBack,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => setState(() => _step == 1
                                ? context
                                    .read<InstallmentsBloc>()
                                    .add(const PayDuesDialogClosed())
                                : _step--),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BlocBuilder<InstallmentsBloc, InstallmentsState>(
                            builder: (context, state) {
                              final submitting = state.submitting;
                              return AppButton(
                                label: _step == 3
                                    ? (submitting
                                        ? loc.memberPayDuesSubmitting
                                        : loc.memberPayDuesSubmit)
                                    : loc.memberPayDuesContinue,
                                onPressed: submitting
                                    ? null
                                    : () {
                                        if (_step < 3) {
                                          setState(() => _step++);
                                          return;
                                        }
                                        if (!_canSubmit) return;
                                        context.read<InstallmentsBloc>().add(
                                              InstallmentPaymentSubmitted(
                                                proofPath: _proofPath,
                                                submission: PaymentSubmission(
                                                  installmentIds:
                                                      _selectedIds.toList(),
                                                  method: _method,
                                                  transactionRef:
                                                      _transactionRef.text,
                                                  paidOn: _paidOn
                                                      .toIso8601String()
                                                      .substring(0, 10),
                                                  senderAccount:
                                                      _senderAccount.text,
                                                  note: _note.text,
                                                ),
                                              ),
                                            );
                                      },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    if (file.size > 5 * 1024 * 1024) {
      setState(() {
        _proofPath = null;
        _proofError = loc.memberPayDuesProofSizeError;
      });
      return;
    }
    setState(() {
      _proofPath = file.path;
      _proofError = null;
    });
  }
}
