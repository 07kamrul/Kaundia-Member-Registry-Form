import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../domain/member_entities.dart';
import '../presentation/bloc/picnic_payment_bloc.dart';
import '../presentation/widgets/member_ui.dart';

/// Port of Angular PicnicPaymentComponent: date-driven rates with breakdown,
/// additional-heads stepper + per-head name/relation rows, and payment history.
class PicnicPaymentPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PicnicPaymentPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PicnicPaymentBloc(repository: MemberRepository(apiClient: sl<ApiClient>()))
          ..add(const PicnicStarted()),
      child: const _PicnicView(),
    );
  }
}

class _PicnicView extends StatelessWidget {
  const _PicnicView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<PicnicPaymentBloc, PicnicPaymentState>(
        listener: (context, state) {
          final total = state.successTotal;
          if (total != null) {
            showAppToast(context, loc.memberPicnicSaveSuccess(total));
          }
          final err = state.formError;
          if (err != null) {
            showAppToast(context, err == 'saveError' ? loc.memberPicnicSaveError : err,
                error: true);
          }
          if (state.historyError) {
            showAppToast(context, loc.memberPicnicHistoryLoadFailed, error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<PicnicPaymentBloc>();
          return PageBody(
            maxWidth: Breakpoints.formMaxWidth,
            onRefresh: () => reloadAndWait<PicnicPaymentState>(
              bloc,
              () => bloc.add(const PicnicStarted()),
              (s) => !s.historyLoading && !s.feeLoading && s.status != PicnicPageStatus.loading,
            ),
            children: [
              PageHeader(
                title: loc.memberPicnicTitle,
                subtitle: loc.memberPicnicSubtitle,
                icon: Icons.celebration_outlined,
              ),
              _FeeCard(state: state, bloc: bloc),
              _HeadsCard(state: state, bloc: bloc),
              _PaymentCard(state: state, bloc: bloc),
              ..._history(context, state, loc),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _history(BuildContext context, PicnicPaymentState state, AppLocalizations loc) {
    if (state.historyLoading) return const [SkeletonLoader(lines: 3)];
    if (state.payments.isEmpty) {
      return [EmptyState(message: loc.memberPicnicEmptyState, icon: Icons.event_outlined)];
    }
    return [
      SectionTitle(loc.memberPicnicHistoryTitle),
      Gutter(
        child: ResponsiveGrid(
          minItemWidth: 300,
          maxColumns: 2,
          children: [for (final p in state.payments) _HistoryCard(payment: p)],
        ),
      ),
    ];
  }
}

/// Payment date + the rate breakdown for that date.
class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.state, required this.bloc});

  final PicnicPaymentState state;
  final PicnicPaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final b = state.breakdown;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DatePickerField(
            label: loc.memberPicnicDateLabel,
            value: state.paymentDate,
            onPicked: (v) => bloc.add(PicnicDateChanged(v)),
          ),
          const SizedBox(height: 16),
          if (state.feeLoading)
            const LinearProgressIndicator()
          else if (state.ratesError != PicnicRatesError.none)
            NoticeBanner(
              margin: EdgeInsets.zero,
              tone: NoticeTone.error,
              message: switch (state.ratesError) {
                PicnicRatesError.notConfigured => loc.memberPicnicNotConfigured,
                PicnicRatesError.access => loc.memberPicnicAccessDenied,
                _ => loc.memberPicnicFeeLoadFailed,
              },
              action: TextButton.icon(
                onPressed: () => bloc.add(const PicnicRatesRefreshRequested()),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(loc.memberPicnicRetry),
              ),
            )
          else if (b != null) ...[
            _FeeLine(label: loc.memberPicnicMemberHead, value: '৳ ${b.headFee}'),
            if (b.count > 0)
              _FeeLine(
                label: '${loc.memberPicnicAdditionalHeadsLabel} (${b.count} × ৳ ${b.additionalHeadFee})',
                value: '৳ ${b.additionalAmount}',
              ),
            const SizedBox(height: 8),
            _TotalBox(label: loc.memberPicnicTotal, value: '৳ ${b.total}'),
          ],
        ],
      ),
    );
  }
}

class _FeeLine extends StatelessWidget {
  const _FeeLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Additional-heads stepper plus a name/relation pair per head.
class _HeadsCard extends StatelessWidget {
  const _HeadsCard({required this.state, required this.bloc});

  final PicnicPaymentState state;
  final PicnicPaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final heads = state.additionalHeads;
    return AppCard(
      title: loc.memberPicnicAdditionalHeadsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: '${loc.memberPicnicAdditionalHeadsLabel} −1',
                onPressed: heads > 0 ? () => bloc.add(PicnicHeadsChanged(heads - 1)) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$heads',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filledTonal(
                tooltip: '${loc.memberPicnicAdditionalHeadsLabel} +1',
                onPressed: heads < maxAdditionalHeads
                    ? () => bloc.add(PicnicHeadsChanged(heads + 1))
                    : null,
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.memberPicnicAdditionalHeadsHint(maxAdditionalHeads),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          for (var i = 0; i < state.labels.length; i++) ...[
            const SizedBox(height: 12),
            _HeadRow(index: i, label: state.labels[i], bloc: bloc),
          ],
        ],
      ),
    );
  }
}

class _HeadRow extends StatelessWidget {
  const _HeadRow({required this.index, required this.label, required this.bloc});

  final int index;
  final PicnicHeadLabel label;
  final PicnicPaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final n = index + 1;
    return FieldGrid(
      children: [
        SyncedTextField(
          value: label.name,
          label: loc.memberPicnicHeadNameLabel(n),
          icon: Icons.person_outline,
          onChanged: (v) => bloc.add(PicnicLabelNameChanged(index, v)),
        ),
        DropdownButtonFormField<PicnicRelation>(
          key: ValueKey('relation-$index-${label.relation}'),
          initialValue: label.relation,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.memberPicnicHeadRelationLabel(n),
            prefixIcon: const Icon(Icons.family_restroom_outlined),
          ),
          items: [
            DropdownMenuItem(value: PicnicRelation.spouse, child: Text(loc.memberPicnicRelationsSpouse)),
            DropdownMenuItem(value: PicnicRelation.child, child: Text(loc.memberPicnicRelationsChild)),
            DropdownMenuItem(value: PicnicRelation.guest, child: Text(loc.memberPicnicRelationsGuest)),
          ],
          onChanged: (v) {
            if (v != null) bloc.add(PicnicLabelRelationChanged(index, v));
          },
        ),
      ],
    );
  }
}

/// Receipt number, method and submit.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.state, required this.bloc});

  final PicnicPaymentState state;
  final PicnicPaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldGrid(
            children: [
              SyncedTextField(
                value: state.receiptNo,
                label: loc.memberPicnicReceiptNoLabel,
                icon: Icons.receipt_outlined,
                textInputAction: TextInputAction.done,
                onChanged: (v) => bloc.add(PicnicReceiptNoChanged(v)),
              ),
              DropdownButtonFormField<String>(
                initialValue: state.paymentMethod,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.memberPicnicMethodLabel,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                items: [
                  DropdownMenuItem(value: 'Cash', child: Text(loc.memberPicnicMethodsCash)),
                  DropdownMenuItem(value: 'bKash', child: Text(loc.memberPicnicMethodsBKash)),
                  DropdownMenuItem(value: 'Nagad', child: Text(loc.memberPicnicMethodsNagad)),
                  DropdownMenuItem(
                      value: 'Bank Transfer', child: Text(loc.memberPicnicMethodsBankTransfer)),
                  DropdownMenuItem(value: 'Other', child: Text(loc.memberPicnicMethodsOther)),
                ],
                onChanged: (v) {
                  if (v != null) bloc.add(PicnicPaymentMethodChanged(v));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: state.saving ? loc.memberPicnicSaving : loc.memberPicnicSubmit,
            icon: Icons.check_circle_outline,
            expanded: true,
            loading: state.saving,
            onPressed: state.canSubmit ? () => bloc.add(const PicnicSubmitted()) : null,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.payment});

  final PicnicPayment payment;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = payment;
    final details = [
      '${p.additionalCount} ${loc.memberPicnicHeadsColumn}',
      if (p.receiptNo != null) '${loc.memberPicnicReceiptColumn}: ${p.receiptNo}',
      if (p.paymentMethod != null) p.paymentMethod!,
    ].join(' · ');
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          const LeadingIcon(icon: Icons.event_available_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.paymentDate, style: theme.textTheme.titleSmall),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '৳ ${p.total}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
