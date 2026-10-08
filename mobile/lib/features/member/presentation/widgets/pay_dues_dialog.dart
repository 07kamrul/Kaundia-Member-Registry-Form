import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/finance_entities.dart';
import '../../domain/payment_entities.dart';
import '../bloc/installments_bloc.dart';
import 'member_ui.dart';

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

const double _dialogMaxWidth = 520;
const int _maxProofBytes = 5 * 1024 * 1024;

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
  bool _submitAttempted = false;

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

  void _close() => context.read<InstallmentsBloc>().add(const PayDuesDialogClosed());

  void _back() => _step == 1 ? _close() : setState(() => _step--);

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _submitAttempted = true);
    if (!_canSubmit) return;
    context.read<InstallmentsBloc>().add(
          InstallmentPaymentSubmitted(
            proofPath: _proofPath,
            submission: PaymentSubmission(
              installmentIds: _selectedIds.toList(),
              method: _method,
              transactionRef: _transactionRef.text,
              paidOn: _paidOn.toIso8601String().substring(0, 10),
              senderAccount: _senderAccount.text,
              note: _note.text,
            ),
          ),
        );
  }

  void _toggleAll() => setState(() {
        if (_selectedIds.length == _payable.length) {
          _selectedIds.clear();
        } else {
          _selectedIds
            ..clear()
            ..addAll(_payable.map((i) => i.id));
        }
      });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Positioned.fill(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Material(
          color: Colors.black54,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(loc, theme),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: _stepBody(loc),
                        ),
                        _actions(loc),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations loc, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.memberPayDuesTitle,
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              IconButton(
                tooltip: loc.memberPayDuesClose,
                icon: const Icon(Icons.close),
                onPressed: _close,
              ),
            ],
          ),
          Text(
            loc.memberPayDuesTotalLabel(_selectedIds.length),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '৳ ${NumberFormatLike.enInGrouped(_selectedTotal.round())}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          _StepIndicator(step: _step),
        ],
      ),
    );
  }

  Widget _stepBody(AppLocalizations loc) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: switch (_step) {
        1 => _selectStep(loc),
        2 => _sendStep(loc),
        _ => _reportStep(loc),
      },
    );
  }

  Widget _selectStep(AppLocalizations loc) {
    final allSelected = _selectedIds.length == _payable.length && _payable.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.memberPayDuesSelectHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            loc.memberPayDuesSelectAll,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          value: allSelected,
          onChanged: (_) => _toggleAll(),
        ),
        const Divider(height: 1),
        for (final i in _payable)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('${monthLabel(i.month, loc)} ${i.year}'),
            secondary: Text(
              '৳ ${NumberFormatLike.enInGrouped(i.amount.round())}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _selectedIds.contains(i.id),
            onChanged: (v) => setState(
                () => v == true ? _selectedIds.add(i.id) : _selectedIds.remove(i.id)),
          ),
      ],
    );
  }

  Widget _sendStep(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.memberPayDuesMethodHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Text(loc.memberPayDuesSendTo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final account in widget.summary.accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AccountOption(
              account: account,
              selected: account.method == _method,
              onSelect: () => setState(() => _method = account.method),
            ),
          ),
        NoticeBanner(
          margin: EdgeInsets.zero,
          tone: NoticeTone.warning,
          message: loc.memberPayDuesKeepReceipt,
        ),
      ],
    );
  }

  Widget _reportStep(AppLocalizations loc) {
    final showRefError =
        (_submitAttempted || _transactionRef.text.isNotEmpty) && !_refValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _transactionRef,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: loc.memberPayDuesTransactionRef,
            hintText: loc.memberPayDuesTransactionRefPlaceholder,
            prefixIcon: const Icon(Icons.tag),
            errorText: showRefError ? loc.memberPayDuesTransactionRefError : null,
            errorMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        DatePickerField(
          label: loc.memberPayDuesPaidOn,
          value: _paidOn.toIso8601String().substring(0, 10),
          lastDate: DateTime.now(),
          onPicked: (v) => setState(() => _paidOn = DateTime.parse(v)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _senderAccount,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: loc.memberPayDuesSenderAccount,
            prefixIcon: const Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: loc.memberPayDuesNote,
            prefixIcon: const Icon(Icons.notes_outlined),
          ),
        ),
        const SizedBox(height: 12),
        _ProofPicker(
          fileName: _proofPath?.split(RegExp(r'[\\/]')).last,
          error: _proofError,
          onPick: _pickProof,
          onClear: () => setState(() {
            _proofPath = null;
            _proofError = null;
          }),
        ),
      ],
    );
  }

  Widget _actions(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: _step == 1 ? loc.commonCancel : loc.memberPayDuesBack,
              variant: AppButtonVariant.secondary,
              icon: _step == 1 ? null : Icons.arrow_back,
              onPressed: _back,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<InstallmentsBloc, InstallmentsState>(
              buildWhen: (a, b) => a.submitting != b.submitting,
              builder: (context, state) {
                final submitting = state.submitting;
                return AppButton(
                  label: _step == 3
                      ? (submitting ? loc.memberPayDuesSubmitting : loc.memberPayDuesSubmit)
                      : loc.memberPayDuesContinue,
                  icon: _step == 3 ? Icons.send_outlined : Icons.arrow_forward,
                  loading: submitting,
                  onPressed: _step == 1 && _selectedIds.isEmpty ? null : _next,
                );
              },
            ),
          ),
        ],
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
    if (file.size > _maxProofBytes) {
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? scheme.primary : scheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.account,
    required this.selected,
    required this.onSelect,
  });

  final PaymentAccount account;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: selected ? scheme.primary : scheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.method, style: const TextStyle(fontWeight: FontWeight.w600)),
                    SelectableText(account.details),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: loc.memberPayDuesCopy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: account.details));
                  if (context.mounted) showAppToast(context, loc.memberPayDuesCopied);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofPicker extends StatelessWidget {
  const _ProofPicker({
    required this.fileName,
    required this.error,
    required this.onPick,
    required this.onClear,
  });

  final String? fileName;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.attach_file),
          label: Text(
            fileName ?? loc.memberPayDuesProof,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  error ?? loc.memberPayDuesProofHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: error == null ? null : theme.colorScheme.error,
                  ),
                ),
              ),
              if (fileName != null)
                TextButton(onPressed: onClear, child: Text(loc.registrationPropertyRemoveFileButton)),
            ],
          ),
        ),
      ],
    );
  }
}
