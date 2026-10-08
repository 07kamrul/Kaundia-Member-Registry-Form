import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../presentation/bloc/payment_verifications_bloc.dart';

import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/widgets/management_widgets.dart';
import 'installments_management_page.dart' show monthLabelOf;

/// Committee queue for member-reported installment payments (Angular
/// payment-verifications): status filter tabs, approve / reject with reason.
class PaymentVerificationsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PaymentVerificationsPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentVerificationsBloc(
        repository: InstallmentPaymentRepository(apiClient: sl<ApiClient>()),
      )..add(const PaymentVerificationsLoadRequested()),
      child: const _PaymentVerificationsView(),
    );
  }
}

String _statusText(AppLocalizations loc, String status) => switch (status) {
      'pending' => loc.commonStatusPending,
      'approved' => loc.commonStatusApproved,
      _ => loc.commonStatusRejected,
    };

StatusKind _statusKind(String status) => switch (status) {
      'pending' => StatusKind.pending,
      'approved' => StatusKind.approved,
      'rejected' => StatusKind.rejected,
      _ => StatusKind.neutral,
    };

class _PaymentVerificationsView extends StatelessWidget {
  const _PaymentVerificationsView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<PaymentVerificationsBloc, PaymentVerificationsState>(
      listener: (context, state) {
        // Load failures render inline; toast action failures.
        if (state.error != null && state.payments.isNotEmpty) {
          showAppToast(context, describeApiError(context, state.error),
              error: true);
        }
      },
      builder: (context, state) {
        final bloc = context.read<PaymentVerificationsBloc>();
        return PageBody(
          onRefresh: () => reloadAndWait(bloc,
              const PaymentVerificationsLoadRequested(), (s) => s.loading),
          children: [
            PageHeader(
              icon: Icons.fact_check_outlined,
              title: loc.adminPaymentVerificationsTitle,
              subtitle: loc.adminPaymentVerificationsSubtitle,
            ),
            ManagementFilterChips<String>(
              selected: state.statusFilter,
              options: [
                for (final s in const ['pending', 'approved', 'rejected'])
                  (s, _statusText(loc, s)),
              ],
              onSelected: (status) => bloc.add(
                  PaymentVerificationsStatusFilterChanged(status: status)),
            ),
            const SizedBox(height: 8),
            ..._content(loc, bloc, state),
          ],
        );
      },
    );
  }

  List<Widget> _content(AppLocalizations loc, PaymentVerificationsBloc bloc,
      PaymentVerificationsState state) {
    if (state.loading) return const [SkeletonLoader(lines: 4, height: 120)];
    if (state.payments.isEmpty && state.error != null) {
      return [
        InlineError(
          message: loc.adminPaymentVerificationsLoadError,
          onRetry: () => bloc.add(const PaymentVerificationsLoadRequested()),
        ),
      ];
    }
    if (state.payments.isEmpty) {
      return [
        EmptyState(
          message: loc.adminPaymentVerificationsEmpty,
          icon: Icons.check_circle_outline,
        ),
      ];
    }
    return [
      SectionTitle(
        _statusText(loc, state.statusFilter),
        trailing: StatusBadge(
          kind: _statusKind(state.statusFilter),
          label: '${state.payments.length}',
        ),
      ),
      ManagementRecordGrid(
        children: [
          for (final p in state.payments)
            _PaymentCard(payment: p, busy: state.busyId == p.id),
        ],
      ),
    ];
  }
}

enum _PaymentAction { approve, reject }

class _PaymentCard extends StatefulWidget {
  const _PaymentCard({required this.payment, required this.busy});

  final AdminInstallmentPayment payment;
  final bool busy;

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  _PaymentAction? _active;

  bool _loading(_PaymentAction action) => widget.busy && _active == action;

  void _approve() {
    setState(() => _active = _PaymentAction.approve);
    context
        .read<PaymentVerificationsBloc>()
        .add(PaymentVerificationsApproved(payment: widget.payment));
  }

  Future<void> _reject(AppLocalizations loc) async {
    final bloc = context.read<PaymentVerificationsBloc>();
    final p = widget.payment;
    final reason = await showReasonDialog(
      context,
      title: loc.adminPaymentVerificationsRejectTitle,
      summary:
          '${p.memberName ?? '—'} · ${formatTaka(p.amount)} · ${p.transactionRef}',
      label: loc.adminPaymentVerificationsReason,
      hint: loc.adminPaymentVerificationsReasonPlaceholder,
      cancelLabel: loc.adminPaymentVerificationsCancel,
      confirmLabel: loc.adminPaymentVerificationsReject,
      validator: (text) =>
          text.length < 3 ? loc.adminPaymentVerificationsReason : null,
    );
    if (reason == null || reason.length < 3 || !mounted) return;
    setState(() => _active = _PaymentAction.reject);
    bloc.add(PaymentVerificationsRejected(payment: p, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = widget.payment;
    final months = p.installments
        .map((i) => '${monthLabelOf(loc, i.month)} ${i.year}')
        .join(', ');
    final note = p.note;
    final rejection = p.rejectionReason;
    return ManagementRecordCard(
      leading: ManagementAvatar(name: p.memberName ?? '?'),
      title: '${p.memberName ?? '—'} ${p.memberDisplayId ?? ''}'.trim(),
      subtitle: months,
      badge: Text(
        formatTaka(p.amount),
        style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
      ),
      actions: _actions(loc),
      children: [
        InfoRow(label: loc.adminPaymentVerificationsMethod, value: p.method),
        InfoRow(
            label: loc.adminPaymentVerificationsReference,
            value: p.transactionRef),
        InfoRow(label: loc.adminPaymentVerificationsPaidOn, value: p.paidOn),
        if (p.senderAccount != null && p.senderAccount!.isNotEmpty)
          InfoRow(
              label: loc.adminPaymentVerificationsSender,
              value: p.senderAccount!),
        if (note != null && note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('"$note"',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ),
        if (rejection != null && rejection.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ManagementCallout(
                message: rejection, icon: Icons.block_outlined, error: true),
          ),
      ],
    );
  }

  List<Widget> _actions(AppLocalizations loc) {
    final p = widget.payment;
    final busy = widget.busy;
    return [
      if (p.proofUrl != null)
        AppButton(
          label: loc.adminPaymentVerificationsViewProof,
          variant: AppButtonVariant.ghost,
          icon: Icons.visibility_outlined,
          onPressed: () => showImagePreview(context, p.proofUrl!, p.transactionRef),
        ),
      if (p.status == 'pending') ...[
        AppButton(
          label: loc.adminPaymentVerificationsReject,
          variant: AppButtonVariant.danger,
          icon: Icons.close,
          loading: _loading(_PaymentAction.reject),
          onPressed: busy ? null : () => _reject(loc),
        ),
        AppButton(
          label: loc.adminPaymentVerificationsApprove,
          icon: Icons.check,
          loading: _loading(_PaymentAction.approve),
          onPressed: busy ? null : _approve,
        ),
      ],
    ];
  }
}
