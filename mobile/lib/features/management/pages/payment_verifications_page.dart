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
import 'installments_management_page.dart' show monthLabelOf;

/// Committee queue for member-reported installment payments (Angular
/// payment-verifications): status filter tabs, approve / reject with reason.
class PaymentVerificationsPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PaymentVerificationsPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<PaymentVerificationsPage> createState() =>
      _PaymentVerificationsPageState();
}

class _PaymentVerificationsPageState extends State<PaymentVerificationsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => PaymentVerificationsCubit(
        repository: InstallmentPaymentRepository(apiClient: sl<ApiClient>()),
      )..load(),
      child: BlocConsumer<PaymentVerificationsCubit, PaymentVerificationsState>(
        listener: (context, state) {
          if (state.error != null) {
            showAppToast(context, describeApiError(context, state.error),
                error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<PaymentVerificationsCubit>();
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminPaymentVerificationsTitle,
                  subtitle: loc.adminPaymentVerificationsSubtitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppTabs(
                  labels: [
                    loc.commonStatusPending,
                    loc.commonStatusApproved,
                    loc.commonStatusRejected,
                  ],
                  selectedIndex: switch (state.statusFilter) {
                    'pending' => 0,
                    'approved' => 1,
                    _ => 2,
                  },
                  onChanged: (index) => cubit.setStatusFilter(switch (index) {
                    0 => 'pending',
                    1 => 'approved',
                    _ => 'rejected',
                  }),
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 4)
              else if (state.payments.isEmpty)
                EmptyState(
                  message: loc.adminPaymentVerificationsEmpty,
                  icon: Icons.check_circle_outline,
                )
              else
                for (final p in state.payments)
                  _paymentCard(context, loc, cubit, p),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentCard(BuildContext context, AppLocalizations loc,
      PaymentVerificationsCubit cubit, AdminInstallmentPayment p) {
    final months = p.installments
        .map((i) => '${monthLabelOf(loc, i.month)} ${i.year}')
        .join(', ');
    final busy = _isBusy(cubit, p.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.memberName ?? '—'} ${p.memberDisplayId ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(months,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  formatTaka(p.amount, decimals: 0),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InfoRow(
                label: loc.adminPaymentVerificationsMethod, value: p.method),
            InfoRow(
                label: loc.adminPaymentVerificationsReference,
                value: p.transactionRef),
            InfoRow(
                label: loc.adminPaymentVerificationsPaidOn, value: p.paidOn),
            if (p.senderAccount != null && p.senderAccount!.isNotEmpty)
              InfoRow(
                  label: loc.adminPaymentVerificationsSender,
                  value: p.senderAccount!),
            if (p.note != null && p.note!.isNotEmpty) Text('"${p.note}"'),
            if (p.rejectionReason != null && p.rejectionReason!.isNotEmpty)
              Text(
                p.rejectionReason!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (p.proofUrl != null)
                  AppButton(
                    label: loc.adminPaymentVerificationsViewProof,
                    variant: AppButtonVariant.ghost,
                    icon: Icons.visibility_outlined,
                    onPressed: () => showImagePreview(
                        context, p.proofUrl!, p.transactionRef),
                  ),
                if (p.status == 'pending') ...[
                  AppButton(
                    label: loc.adminPaymentVerificationsReject,
                    variant: AppButtonVariant.danger,
                    onPressed: busy
                        ? null
                        : () => _rejectDialog(context, loc, cubit, p),
                  ),
                  AppButton(
                    label: loc.adminPaymentVerificationsApprove,
                    icon: Icons.check,
                    onPressed: busy ? null : () => cubit.approve(p),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isBusy(PaymentVerificationsCubit cubit, int id) =>
      cubit.state.busyId == id;

  Future<void> _rejectDialog(BuildContext context, AppLocalizations loc,
      PaymentVerificationsCubit cubit, AdminInstallmentPayment p) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.adminPaymentVerificationsRejectTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${p.memberName ?? '—'} · ${formatTaka(p.amount, decimals: 0)} · ${p.transactionRef}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: loc.adminPaymentVerificationsReason,
                hintText: loc.adminPaymentVerificationsReasonPlaceholder,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.adminPaymentVerificationsCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.adminPaymentVerificationsReject),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final reason = controller.text.trim();
    if (reason.length < 3) {
      showAppToast(context, loc.adminPaymentVerificationsReason, error: true);
      return;
    }
    await cubit.reject(p, reason);
  }
}
