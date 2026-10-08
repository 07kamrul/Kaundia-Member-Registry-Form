import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/registration_form.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 4: admission fee (read-only, from GET /public/fee-settings), চাঁদা
/// (read-only, backend-quoted), receipt no + image, payment method
/// (payment-info.component).
class PaymentStep extends StatelessWidget {
  const PaymentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final f = state.form;

    String? err(RegErrorKind kind) {
      final e = findError(state.stepErrors, kind);
      return e == null ? null : regErrorMessage(l10n, e);
    }

    // The fee is rendered only from the live fee settings (never from the
    // form or a restored draft).
    final feeText = state.feeStatus == FeeStatus.loaded && state.hasAdmissionFee
        ? (state.admissionFee! % 1 == 0
            ? state.admissionFee!.toStringAsFixed(0)
            : state.admissionFee.toString())
        : '';
    final subscriptionText = state.hasSubscription ? _fmt(state.quote!.total) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesPayment),
        RegSectionCard(
          child: RegFieldPair(
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegReadOnlyAmountField(
                  key: const Key('admissionFeeField'),
                  label: l10n.registrationPaymentAdmissionFeeLabel,
                  text: feeText,
                  hint: '',
                ),
                const SizedBox(height: 4),
                _FeeHint(state: state),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegReadOnlyAmountField(
                  key: const Key('subscriptionField'),
                  label: l10n.registrationPaymentSubscriptionLabel,
                  text: subscriptionText,
                  hint: '',
                ),
                const SizedBox(height: 4),
                _SubscriptionHint(state: state),
              ],
            ),
          ),
        ),
        RegSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegTextField(
                label: l10n.registrationPaymentReceiptNoLabel,
                value: f.receiptNo,
                prefixIcon: Icons.receipt_long_outlined,
                textInputAction: TextInputAction.done,
                onChanged: (v) => bloc.add(ReceiptNoChanged(v)),
              ),
              const SizedBox(height: 16),
              _ReceiptField(state: state),
              if (state.fileError?.isReceipt ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.fileError!.kind == FileErrorKind.type
                        ? l10n.registrationPaymentFileTypeError
                        : l10n.registrationPaymentFileSizeError(5),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        RegSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegLabel(
                required: true,
                text: l10n.registrationPaymentMethodLabel,
                error: err(RegErrorKind.paymentMethodRequired),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in PaymentMethod.values)
                    if (m != PaymentMethod.unknown)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: RegCheckboxRow(
                          value: f.paymentMethod == m,
                          label: m.apiValue,
                          onChanged: (_) => bloc.add(PaymentMethodSelected(m)),
                        ),
                      ),
                ],
              ),
              if (f.paymentMethod == PaymentMethod.bank) const _BankInfo(),
              if (f.paymentMethod == PaymentMethod.mfs) const _MfsInfo(),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
}

/// Loading / error-with-retry / default hint under the admission fee.
class _FeeHint extends StatelessWidget {
  const _FeeHint({required this.state});

  final RegistrationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    return switch (state.feeStatus) {
      FeeStatus.loading => _HintText(l10n.registrationPaymentAdmissionFeeLoading, loading: true),
      FeeStatus.error => _RetryHint(
          message: l10n.registrationPaymentAdmissionFeeLoadFailed,
          retryLabel: l10n.registrationPaymentAdmissionFeeRetry,
          onRetry: () => bloc.add(FeeRetryRequested()),
        ),
      _ => _HintText(l10n.registrationPaymentAdmissionFeeHint),
    };
  }
}

/// Loading / error-with-retry / quote summary under the subscription.
class _SubscriptionHint extends StatelessWidget {
  const _SubscriptionHint({required this.state});

  final RegistrationState state;

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    if (state.quoteStatus == QuoteStatus.loading) {
      return _HintText(l10n.registrationPaymentSubscriptionLoading, loading: true);
    }
    if (state.quoteStatus == QuoteStatus.error) {
      return _RetryHint(
        message: l10n.registrationPaymentSubscriptionLoadFailed,
        retryLabel: l10n.registrationPaymentSubscriptionRetry,
        onRetry: () => bloc.add(SubscriptionRetryRequested()),
      );
    }
    if (!state.hasSubscription) return _HintText(l10n.registrationPaymentSubscriptionHint);
    final q = state.quote!;
    var summary = l10n.registrationPaymentSubscriptionBaseSummary(_fmt(q.base));
    if (q.extraUnits > 0) {
      summary +=
          ' ${l10n.registrationPaymentSubscriptionExtraSummary(q.extraUnits, _fmt(q.extraAmount))}';
    }
    summary += ' ${l10n.registrationPaymentTotalAmountSummary(_fmt(q.total))}';
    return _HintText(summary);
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text, {this.loading = false});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    if (!loading) return Text(text, style: style);
    return Row(
      children: [
        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

class _RetryHint extends StatelessWidget {
  const _RetryHint({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
        ),
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: onRetry,
          label: Text(retryLabel),
        ),
      ],
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({required this.state});

  final RegistrationState state;

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<RegistrationBloc>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = result?.files.single;
    if (file == null || file.path == null) return;
    bloc.add(ReceiptFileAttached(file.path!, file.name));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final receipt = state.form.receiptFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegLabel(text: l10n.registrationPaymentReceiptImageLabel),
        const SizedBox(height: 6),
        if (receipt?.hasFile ?? false)
          RegFileChip(
            fileName: receipt!.fileName ?? '',
            removeLabel: l10n.registrationPaymentRemoveFile,
            onRemove: () => bloc.add(ReceiptFileRemoved()),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(l10n.registrationPaymentAttachReceipt),
            onPressed: () => _pick(context),
          ),
        const SizedBox(height: 4),
        Text(
          l10n.registrationPaymentMaxFileSizeHint(5),
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

/// Tinted box listing the organisation's payment account details.
class _AccountInfoBox extends StatelessWidget {
  const _AccountInfoBox({required this.icon, required this.rows});

  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: Icon(icon, size: 20, color: theme.colorScheme.onSecondaryContainer),
          ),
          Expanded(
            child: SelectionArea(
              child: Column(
                children: [
                  for (final (label, value) in rows) DetailRow(label: label, value: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankInfo extends StatelessWidget {
  const _BankInfo();

  // Mirrors ORG_BANK_INFO (registration.model.ts).
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AccountInfoBox(
      icon: Icons.account_balance_outlined,
      rows: [
        (l10n.registrationPaymentBankNameLabel, 'ব্র্যাক ব্যাংক পিএলসি'),
        (l10n.registrationPaymentBranchLabel, 'শ্যামপুর এসএমই/কৃষি শাখা'),
        (l10n.registrationPaymentAccountNameLabel, 'Md Kamrul Hasan'),
        (l10n.registrationPaymentAccountNumberLabel, '1071193760001'),
        (l10n.registrationPaymentRoutingNumberLabel, '060276537'),
      ],
    );
  }
}

class _MfsInfo extends StatelessWidget {
  const _MfsInfo();

  // Mirrors ORG_MFS_INFO (registration.model.ts).
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AccountInfoBox(
      icon: Icons.phone_android_outlined,
      rows: [(l10n.registrationPaymentMfsNumberLabel, '01758290421 (পার্সোনাল)')],
    );
  }
}
