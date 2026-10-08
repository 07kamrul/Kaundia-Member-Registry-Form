import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../presentation/bloc/picnic_payment_bloc.dart';

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
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageHeader(
                title: loc.memberPicnicTitle,
                subtitle: loc.memberPicnicSubtitle,
              ),
              // Payment date + rates.
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${loc.memberPicnicDateLabel}: ${state.paymentDate}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.tryParse(state.paymentDate) ?? DateTime.now(),
                            );
                            if (picked != null) {
                              bloc.add(PicnicDateChanged(picked.toIso8601String().substring(0, 10)));
                            }
                          },
                          child: Text(loc.commonSelect),
                        ),
                      ],
                    ),
                    if (state.feeLoading)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.ratesError != PicnicRatesError.none) ...[
                      Text(
                        switch (state.ratesError) {
                          PicnicRatesError.notConfigured => loc.memberPicnicNotConfigured,
                          PicnicRatesError.access => loc.memberPicnicAccessDenied,
                          _ => loc.memberPicnicFeeLoadFailed,
                        },
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      TextButton(
                        onPressed: () => bloc.add(const PicnicRatesRefreshRequested()),
                        child: Text(loc.memberPicnicRetry),
                      ),
                    ] else if (state.breakdown != null) ...[
                      Text('${loc.memberPicnicMemberHead}: ৳ ${state.breakdown!.headFee}'),
                      if (state.breakdown!.count > 0) ...[
                        Text(
                          '${loc.memberPicnicAdditionalHeadsLabel}: ${state.breakdown!.count} × ৳ ${state.breakdown!.additionalHeadFee} = ৳ ${state.breakdown!.additionalAmount}',
                        ),
                      ],
                      Text(
                        '${loc.memberPicnicTotal}: ৳ ${state.breakdown!.total}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
              // Additional heads + labels.
              AppCard(
                title: loc.memberPicnicAdditionalHeadsLabel,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: state.additionalHeads > 0
                              ? () => bloc.add(PicnicHeadsChanged(state.additionalHeads - 1))
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${state.additionalHeads}'),
                        IconButton(
                          onPressed: state.additionalHeads < maxAdditionalHeads
                              ? () => bloc.add(PicnicHeadsChanged(state.additionalHeads + 1))
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        Expanded(
                          child: Text(loc.memberPicnicAdditionalHeadsHint(maxAdditionalHeads),
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                    for (var i = 0; i < state.labels.length; i++) ...[
                      TextField(
                        decoration: InputDecoration(
                          labelText: '${loc.memberPicnicHeadNameLabel} ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => bloc.add(PicnicLabelNameChanged(i, v)),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PicnicRelation>(
                        initialValue: state.labels[i].relation,
                        decoration: InputDecoration(
                          labelText: loc.memberPicnicHeadRelationLabel(i + 1),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: PicnicRelation.spouse,
                              child: Text(loc.memberPicnicRelationsSpouse)),
                          DropdownMenuItem(
                              value: PicnicRelation.child,
                              child: Text(loc.memberPicnicRelationsChild)),
                          DropdownMenuItem(
                              value: PicnicRelation.guest,
                              child: Text(loc.memberPicnicRelationsGuest)),
                        ],
                        onChanged: (v) =>
                            v == null ? null : () => bloc.add(PicnicLabelRelationChanged(i, v)),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              // Receipt + method + submit.
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: loc.memberPicnicReceiptNoLabel,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(PicnicReceiptNoChanged(v)),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: state.paymentMethod,
                      decoration: InputDecoration(
                        labelText: loc.memberPicnicMethodLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Cash', child: Text(loc.memberPicnicMethodsCash)),
                        DropdownMenuItem(value: 'bKash', child: Text(loc.memberPicnicMethodsBKash)),
                        DropdownMenuItem(value: 'Nagad', child: Text(loc.memberPicnicMethodsNagad)),
                        DropdownMenuItem(
                            value: 'Bank Transfer', child: Text(loc.memberPicnicMethodsBankTransfer)),
                        DropdownMenuItem(value: 'Other', child: Text(loc.memberPicnicMethodsOther)),
                      ],
                      onChanged: (v) { if (v != null) bloc.add(PicnicPaymentMethodChanged(v)); },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: state.saving ? loc.memberPicnicSaving : loc.memberPicnicSubmit,
                      expanded: true,
                      onPressed: state.canSubmit ? () => bloc.add(const PicnicSubmitted()) : null,
                    ),
                  ],
                ),
              ),
              // History.
              if (state.historyLoading)
                const SkeletonLoader(lines: 3)
              else if (state.payments.isEmpty)
                EmptyState(message: loc.memberPicnicEmptyState, icon: Icons.event_outlined)
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(loc.memberPicnicHistoryTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final p in state.payments)
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.paymentDate} · ৳ ${p.total}'),
                              Text(
                                '${p.additionalCount} ${loc.memberPicnicHeadsColumn}'
                                '${p.receiptNo != null ? ' · ${loc.memberPicnicReceiptColumn}: ${p.receiptNo}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
