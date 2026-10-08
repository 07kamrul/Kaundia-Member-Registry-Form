import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/society_costs_bloc.dart';
import '../presentation/widgets/management_page_kit.dart';
import '../presentation/widgets/management_widgets.dart';
import '../presentation/widgets/society_costs_dialogs.dart';
import '../presentation/widgets/society_costs_widgets.dart';

/// Society costs (Angular society-costs): filters + summary, cost CRUD with
/// receipt upload, split flow with live dry-run preview, share payment.
class SocietyCostsPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const SocietyCostsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<SocietyCostsPage> createState() => _SocietyCostsPageState();
}

class _SocietyCostsPageState extends State<SocietyCostsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => SocietyCostsBloc(
        adminRepository: AdminRepository(apiClient: sl<ApiClient>()),
        costRepository: SocietyCostRepository(apiClient: sl<ApiClient>()),
      )..add(const SocietyInitRequested()),
      child: BlocConsumer<SocietyCostsBloc, SocietyCostsState>(
        listenWhen: (a, b) => a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            showAppToast(context, loc.adminSocietyCostsErrorsSaveFailed,
                error: true);
          }
        },
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, SocietyCostsState state) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<SocietyCostsBloc>();
    return Scaffold(
      floatingActionButton: AddFab(
        label: loc.adminSocietyCostsCreate,
        onPressed: () => showSocietyCostSheet(context, bloc: bloc),
      ),
      body: PageBody(
        padding: const EdgeInsets.only(bottom: kFabClearance),
        onRefresh: () => reloadAndWait<SocietyCostsEvent, SocietyCostsState>(
          bloc,
          const SocietyRefreshRequested(),
          (s) => s.loading,
        ),
        children: [
          PageHeader(
            icon: Icons.request_quote_outlined,
            title: loc.adminSocietyCostsTitle,
            subtitle: loc.adminSocietyCostsSubtitle,
          ),
          if (state.summary != null) SocietySummaryTiles(summary: state.summary!),
          SocietyFilterPanel(
            state: state,
            searchController: _searchController,
            onChanged: bloc.add,
            onSearch: () => bloc.add(SocietyFiltersChanged(
              categoryFilter: state.categoryFilter,
              sourceFilter: state.sourceFilter,
              billedFilter: state.billedFilter,
              search: _searchController.text,
            )),
            onReset: () {
              _searchController.clear();
              bloc.add(const SocietyFiltersReset());
            },
          ),
          ..._costs(context, state, bloc),
        ],
      ),
    );
  }

  List<Widget> _costs(
      BuildContext context, SocietyCostsState state, SocietyCostsBloc bloc) {
    final loc = AppLocalizations.of(context);
    if (state.loading && state.costs.isEmpty) return const [SkeletonLoader(lines: 5)];
    if (state.error != null) {
      return [
        InlineError(
          message: loc.adminSocietyCostsErrorsLoadFailed,
          onRetry: () => bloc.add(const SocietyRefreshRequested()),
        ),
      ];
    }
    if (state.costs.isEmpty) {
      return [
        EmptyState(
          icon: Icons.receipt_long_outlined,
          message: loc.adminSocietyCostsEmptyState,
        ),
      ];
    }
    return [
      ReloadingBar(visible: state.loading),
      CardGrid(
        minItemWidth: 380,
        maxColumns: 2,
        children: [
          for (final cost in state.costs) _costCard(context, state, bloc, cost),
        ],
      ),
    ];
  }

  Widget _costCard(BuildContext context, SocietyCostsState state,
      SocietyCostsBloc bloc, SocietyCost cost) {
    return SocietyCostCard(
      key: ValueKey(cost.id),
      cost: cost,
      expanded: state.expandedId == cost.id,
      onToggle: () => bloc.add(SocietyRowToggled(id: cost.id)),
      actions: SocietyCostActions(
        onEdit: () => showSocietyCostSheet(context, bloc: bloc, editing: cost),
        onDelete: () => _delete(context, bloc, cost),
        onSplit: () => showSocietySplitSheet(context, bloc: bloc, cost: cost),
        onRecordPayment: (share) =>
            showSocietyPaymentSheet(context, bloc: bloc, share: share),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, SocietyCostsBloc bloc, SocietyCost cost) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: loc.adminSocietyCostsDeleteTitle,
      message: '${loc.adminSocietyCostsDeleteMessage}\n\n${cost.title}',
      confirmLabel: loc.commonDelete,
      destructive: true,
    );
    if (confirmed && context.mounted) bloc.add(SocietyCostDeleted(cost: cost));
  }
}
