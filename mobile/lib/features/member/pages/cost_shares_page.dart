import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/finance_entities.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/payment_repository.dart';
import '../domain/payment_entities.dart';
import '../presentation/bloc/cost_shares_bloc.dart';

/// Port of Angular CostSharesComponent: own society-cost shares with the total
/// outstanding card and a mobile list (table-cards idiom).
class CostSharesPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const CostSharesPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CostSharesBloc(repository: MemberPaymentRepository(apiClient: sl<ApiClient>()))
            ..add(const CostSharesLoadRequested()),
      child: const _CostSharesView(),
    );
  }
}

class _CostSharesView extends StatelessWidget {
  const _CostSharesView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<CostSharesBloc, CostSharesState>(
        builder: (context, state) {
          final body = switch (state.status) {
            CostSharesStatus.loading => const SkeletonLoader(lines: 6),
            CostSharesStatus.failure => InlineError(
                message: loc.memberCostSharesLoadError,
                onRetry: () => context.read<CostSharesBloc>().add(const CostSharesLoadRequested()),
              ),
            CostSharesStatus.loaded => ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  PageHeader(
                    title: loc.memberCostSharesTitle,
                    subtitle: loc.memberCostSharesSubtitle,
                  ),
                  if (state.hasOutstanding)
                    AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Theme.of(context).colorScheme.error, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.memberCostSharesTotalOutstanding,
                                    style: Theme.of(context).textTheme.bodySmall),
                                Text(
                                  formatTaka(state.outstandingTotal, 'en'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (state.shares.isEmpty)
                    EmptyState(
                      message: loc.memberCostSharesEmptyState,
                      icon: Icons.check_circle_outline,
                    )
                  else
                    for (final share in state.shares)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    share.costTitle ?? '—',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _shareBadge(context, share.status, loc),
                              ],
                            ),
                            if (share.costCategory != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(share.costCategory!,
                                    style: Theme.of(context).textTheme.bodySmall),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${loc.memberCostSharesTableDue}: ${formatTaka(share.amountDue, 'en')}',
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${loc.memberCostSharesTablePaid}: ${formatTaka(share.amountPaid, 'en')}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${loc.memberCostSharesTableDate}: ${share.costIncurredDate ?? '—'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
          };
          return body;
        },
      ),
    );
  }

  Widget _shareBadge(BuildContext context, ShareStatus status, AppLocalizations loc) {
    final (kind, label) = switch (status) {
      ShareStatus.paid => (StatusKind.approved, loc.memberCostSharesStatusPaid),
      ShareStatus.partial => (StatusKind.pending, loc.memberCostSharesStatusPartial),
      ShareStatus.unpaid => (StatusKind.rejected, loc.memberCostSharesStatusUnpaid),
      ShareStatus.unknown => (StatusKind.neutral, loc.commonNoData),
    };
    return StatusBadge(kind: kind, label: label);
  }
}
