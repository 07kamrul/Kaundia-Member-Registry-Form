import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/finance_entities.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/payment_repository.dart';
import '../domain/payment_entities.dart';
import '../presentation/bloc/cost_shares_bloc.dart';
import '../presentation/widgets/member_ui.dart';

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
          final bloc = context.read<CostSharesBloc>();
          final reloading = state.status == CostSharesStatus.loading && state.shares.isNotEmpty;
          if (state.status == CostSharesStatus.loading && !reloading) {
            return const SkeletonLoader(lines: 6);
          }
          if (state.status == CostSharesStatus.failure) {
            return InlineError(
              message: loc.memberCostSharesLoadError,
              onRetry: () => bloc.add(const CostSharesLoadRequested()),
            );
          }
          return PageBody(
            onRefresh: () => reloadAndWait<CostSharesState>(
              bloc,
              () => bloc.add(const CostSharesLoadRequested()),
              (s) => s.status != CostSharesStatus.loading,
            ),
            children: [
              PageHeader(
                title: loc.memberCostSharesTitle,
                subtitle: loc.memberCostSharesSubtitle,
                icon: Icons.pie_chart_outline,
              ),
              if (state.hasOutstanding)
                Gutter(
                  vertical: 6,
                  child: StatTile(
                    label: loc.memberCostSharesTotalOutstanding,
                    value: formatTaka(state.outstandingTotal, 'en'),
                    icon: Icons.account_balance_wallet_outlined,
                    accent: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (state.shares.isEmpty)
                EmptyState(
                  message: loc.memberCostSharesEmptyState,
                  icon: Icons.check_circle_outline,
                )
              else ...[
                SectionTitle(loc.memberCostSharesTableCost),
                Gutter(
                  child: ResponsiveGrid(
                    minItemWidth: 320,
                    maxColumns: 3,
                    children: [for (final share in state.shares) _ShareCard(share: share)],
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

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.share});

  final CostSplitShare share;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  share.costTitle ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              _shareBadge(share.status, loc),
            ],
          ),
          if (share.costCategory != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                share.costCategory!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Amount(
                  label: loc.memberCostSharesTableDue,
                  value: formatTaka(share.amountDue, 'en'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Amount(
                  label: loc.memberCostSharesTablePaid,
                  value: formatTaka(share.amountPaid, 'en'),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${loc.memberCostSharesTableDate}: ${share.costIncurredDate ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareBadge(ShareStatus status, AppLocalizations loc) {
    final (kind, label) = switch (status) {
      ShareStatus.paid => (StatusKind.approved, loc.memberCostSharesStatusPaid),
      ShareStatus.partial => (StatusKind.pending, loc.memberCostSharesStatusPartial),
      ShareStatus.unpaid => (StatusKind.rejected, loc.memberCostSharesStatusUnpaid),
      ShareStatus.unknown => (StatusKind.neutral, loc.commonNoData),
    };
    return StatusBadge(kind: kind, label: label);
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
