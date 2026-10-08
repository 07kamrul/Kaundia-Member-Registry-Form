import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/registration_form.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';
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

    Widget feeHint;
    if (state.feeStatus == FeeStatus.loading) {
      feeHint = Text(l10n.registrationPaymentAdmissionFeeLoading, style: Theme.of(context).textTheme.bodySmall);
    } else if (state.feeStatus == FeeStatus.error) {
      feeHint = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.registrationPaymentAdmissionFeeLoadFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
          TextButton(
            onPressed: () => bloc.add(FeeRetryRequested()),
            child: Text(l10n.registrationPaymentAdmissionFeeRetry),
          ),
        ],
      );
    } else {
      feeHint = Text(l10n.registrationPaymentAdmissionFeeHint, style: Theme.of(context).textTheme.bodySmall);
    }

    String subscriptionText = '';
    Widget subscriptionHint;
    if (state.quoteStatus == QuoteStatus.loading) {
      subscriptionHint = Text(l10n.registrationPaymentSubscriptionLoading, style: Theme.of(context).textTheme.bodySmall);
    } else if (state.quoteStatus == QuoteStatus.error) {
      subscriptionHint = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.registrationPaymentSubscriptionLoadFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
          TextButton(
            onPressed: () => bloc.add(SubscriptionRetryRequested()),
            child: Text(l10n.registrationPaymentSubscriptionRetry),
          ),
        ],
      );
    } else if (state.hasSubscription) {
      final q = state.quote!;
      var summary = l10n.registrationPaymentSubscriptionBaseSummary(_fmt(q.base));
      if (q.extraUnits > 0) {
        summary += ' ${l10n.registrationPaymentSubscriptionExtraSummary(q.extraUnits, _fmt(q.extraAmount))}';
      }
      summary += ' ${l10n.registrationPaymentTotalAmountSummary(_fmt(q.total))}';
      subscriptionText = _fmt(q.total);
      subscriptionHint = Text(summary, style: Theme.of(context).textTheme.bodySmall);
    } else {
      subscriptionHint = Text(l10n.registrationPaymentSubscriptionHint, style: Theme.of(context).textTheme.bodySmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesPayment),
        RegReadOnlyAmountField(
          key: const Key('admissionFeeField'),
          label: l10n.registrationPaymentAdmissionFeeLabel,
          text: feeText,
          hint: '',
        ),
        feeHint,
        const SizedBox(height: 12),
        RegReadOnlyAmountField(
          key: const Key('subscriptionField'),
          label: l10n.registrationPaymentSubscriptionLabel,
          text: subscriptionText,
          hint: '',
        ),
        subscriptionHint,
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationPaymentReceiptNoLabel,
          value: f.receiptNo,
          onChanged: (v) => bloc.add(ReceiptNoChanged(v)),
        ),
        const SizedBox(height: 12),
        _ReceiptField(state: state),
        const SizedBox(height: 12),
        RegLabel(
          required: true,
          text: l10n.registrationPaymentMethodLabel,
          error: err(RegErrorKind.paymentMethodRequired),
        ),
        Wrap(
          children: [
            for (final m in PaymentMethod.values)
              if (m != PaymentMethod.unknown)
                SizedBox(
                  width: 240,
                  child: RegCheckboxRow(
                    value: f.paymentMethod == m,
                    label: m.apiValue,
                    onChanged: (_) => bloc.add(PaymentMethodSelected(m)),
                  ),
                ),
          ],
        ),
        if (f.paymentMethod == PaymentMethod.bank) _BankInfo(),
        if (f.paymentMethod == PaymentMethod.mfs) _MfsInfo(),
        if (state.fileError?.isReceipt ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.fileError!.kind == FileErrorKind.type
                  ? l10n.registrationPaymentFileTypeError
                  : l10n.registrationPaymentFileSizeError(5),
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
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
    final receipt = state.form.receiptFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegLabel(text: l10n.registrationPaymentReceiptImageLabel),
        if (receipt?.hasFile ?? false)
          Row(
            children: [
              Expanded(
                child: Text(receipt!.fileName ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => bloc.add(ReceiptFileRemoved()),
                child: Text(l10n.registrationPaymentRemoveFile),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(l10n.registrationPaymentAttachReceipt),
            onPressed: () => _pick(context),
          ),
        Text(l10n.registrationPaymentMaxFileSizeHint(5), style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _BankInfo extends StatelessWidget {
  // Mirrors ORG_BANK_INFO (registration.model.ts).
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.registrationPaymentBankNameLabel}: ব্র্যাক ব্যাংক পিএলসি'),
          Text('${l10n.registrationPaymentBranchLabel}: শ্যামপুর এসএমই/কৃষি শাখা'),
          Text('${l10n.registrationPaymentAccountNameLabel}: Md Kamrul Hasan'),
          Text('${l10n.registrationPaymentAccountNumberLabel}: 1071193760001'),
          Text('${l10n.registrationPaymentRoutingNumberLabel}: 060276537'),
        ],
      ),
    );
  }
}

class _MfsInfo extends StatelessWidget {
  // Mirrors ORG_MFS_INFO (registration.model.ts).
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Text('${l10n.registrationPaymentMfsNumberLabel}: 01758290421 (পার্সোনাল)'),
    );
  }
}
