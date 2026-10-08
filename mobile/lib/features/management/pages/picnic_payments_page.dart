import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/picnic_payments_bloc.dart';
import '../presentation/widgets/management_widgets.dart';

/// Picnic payments management (Angular picnic-payments): member/date filters,
/// collected summary, payment list.
class PicnicPaymentsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PicnicPaymentsPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PicnicPaymentsBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..add(const PicnicPaymentsLoadRequested()),
      child: const _PicnicPaymentsView(),
    );
  }
}

class _PicnicPaymentsView extends StatelessWidget {
  const _PicnicPaymentsView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<PicnicPaymentsBloc, PicnicPaymentsState>(
      builder: (context, state) {
        final bloc = context.read<PicnicPaymentsBloc>();
        return PageBody(
          onRefresh: () => reloadAndWait(
              bloc, const PicnicPaymentsLoadRequested(), (s) => s.loading),
          children: [
            PageHeader(
              icon: Icons.park_outlined,
              title: loc.adminPicnicPaymentsTitle,
              subtitle: loc.adminPicnicPaymentsSubtitle,
            ),
            _PicnicFilters(state: state),
            const SizedBox(height: 8),
            ManagementStatSummary(
              stats: [
                ManagementStat(
                  label: loc.adminPicnicPaymentsTotalCollected,
                  value: formatTaka(state.totalCollected),
                  icon: Icons.payments_outlined,
                  accent: AppColors.emerald600,
                ),
                ManagementStat(
                  label: loc.adminPicnicPaymentsCount,
                  value: '${state.count}',
                  icon: Icons.receipt_long_outlined,
                  accent: AppColors.goldStrong,
                ),
              ],
            ),
            ..._content(loc, bloc, state),
          ],
        );
      },
    );
  }

  List<Widget> _content(AppLocalizations loc, PicnicPaymentsBloc bloc,
      PicnicPaymentsState state) {
    if (state.loading) return const [SkeletonLoader(lines: 5, height: 96)];
    if (state.error != null) {
      return [
        InlineError(
          message: loc.adminPicnicPaymentsLoadError,
          onRetry: () => bloc.add(const PicnicPaymentsLoadRequested()),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        EmptyState(
          message: loc.adminPicnicPaymentsEmptyState,
          icon: Icons.event_busy_outlined,
        ),
      ];
    }
    return [
      ManagementRecordGrid(
        children: [for (final p in state.items) _PaymentCard(payment: p)],
      ),
    ];
  }
}

/// Member id + date range filters. Owns the member text controller so typing
/// survives rebuilds.
class _PicnicFilters extends StatefulWidget {
  const _PicnicFilters({required this.state});

  final PicnicPaymentsState state;

  @override
  State<_PicnicFilters> createState() => _PicnicFiltersState();
}

class _PicnicFiltersState extends State<_PicnicFilters> {
  late final TextEditingController _member = TextEditingController(
      text: widget.state.memberFilter?.toString() ?? '');

  @override
  void didUpdateWidget(_PicnicFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state.memberFilter;
    if (next != oldWidget.state.memberFilter) {
      _member.text = next?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _member.dispose();
    super.dispose();
  }

  void _apply() => context
      .read<PicnicPaymentsBloc>()
      .add(PicnicPaymentsMemberFilterChanged(raw: _member.text));

  void _reset() {
    _member.clear();
    context.read<PicnicPaymentsBloc>().add(const PicnicPaymentsFiltersReset());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<PicnicPaymentsBloc>();
    final state = widget.state;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            minItemWidth: 200,
            maxColumns: 3,
            children: [
              TextFormField(
                controller: _member,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: loc.adminPicnicPaymentsMemberFilter,
                  prefixIcon: const Icon(Icons.person_search_outlined),
                ),
                onFieldSubmitted: (raw) =>
                    bloc.add(PicnicPaymentsMemberFilterChanged(raw: raw)),
              ),
              DateField(
                label: loc.adminPicnicPaymentsDateFrom,
                value: state.dateFrom,
                onChanged: (v) =>
                    bloc.add(PicnicPaymentsDateRangeChanged(from: v)),
              ),
              DateField(
                label: loc.adminPicnicPaymentsDateTo,
                value: state.dateTo,
                onChanged: (v) => bloc.add(PicnicPaymentsDateRangeChanged(to: v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: loc.adminPicnicPaymentsReset,
                icon: Icons.restart_alt,
                variant: AppButtonVariant.secondary,
                onPressed: _reset,
              ),
              AppButton(
                label: loc.adminPicnicPaymentsApply,
                icon: Icons.filter_alt_outlined,
                loading: state.loading,
                onPressed: _apply,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final AdminPicnicPayment payment;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = payment;
    final name = p.memberName ?? '#${p.memberId}';
    return ManagementRecordCard(
      leading: ManagementAvatar(name: name),
      title: name,
      subtitle: p.paymentDate,
      badge: Text(
        formatTaka(p.total),
        style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
      ),
      children: [
        InfoRow(
            label: loc.adminPicnicPaymentsHeadsColumn,
            value: '${p.additionalCount}'),
        InfoRow(
            label: loc.adminPicnicPaymentsReceiptColumn,
            value: p.receiptNo ?? '—'),
        InfoRow(
            label: loc.adminPicnicPaymentsMethodColumn,
            value: p.paymentMethod ?? '—'),
      ],
    );
  }
}
