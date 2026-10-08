import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/finance_bloc.dart';
import '../presentation/widgets/finance_management_dialogs.dart';
import '../presentation/widgets/finance_management_widgets.dart';
import '../presentation/widgets/management_page_kit.dart';
import '../presentation/widgets/management_widgets.dart';

/// Finance management (Angular finance-management): overview tiles, filters,
/// ledger with pagination, transaction CRUD + workflow actions, unlinked
/// payment linking, report notice publishing.
class FinanceManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const FinanceManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<FinanceManagementPage> createState() => _FinanceManagementPageState();
}

class _FinanceManagementPageState extends State<FinanceManagementPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinanceBloc(
        adminRepository: AdminRepository(apiClient: sl<ApiClient>()),
        financeRepository: FinanceRepository(apiClient: sl<ApiClient>()),
      )..add(const FinanceInitRequested()),
      child: BlocConsumer<FinanceBloc, FinanceState>(
        listenWhen: (a, b) => a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            showAppToast(context, describeApiError(context, state.actionError),
                error: true);
          }
        },
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, FinanceState state) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<FinanceBloc>();
    return Scaffold(
      floatingActionButton: AddFab(
        label: loc.adminFinanceManagementCreate,
        onPressed: () => showFinanceTransactionSheet(context, bloc: bloc),
      ),
      body: PageBody(
        padding: const EdgeInsets.only(bottom: kFabClearance),
        onRefresh: () => reloadAndWait<FinanceEvent, FinanceState>(
          bloc,
          const FinanceInitRequested(),
          (s) => s.loading,
        ),
        children: [
          PageHeader(
            icon: Icons.account_balance_outlined,
            title: loc.adminFinanceManagementTitle,
            subtitle: loc.adminFinanceManagementSubtitle,
            actions: [_publishNoticeButton(context, state, bloc)],
          ),
          if (state.overview != null) FinanceOverviewTiles(overview: state.overview!),
          _filters(state, bloc),
          ..._ledger(context, state, bloc),
        ],
      ),
    );
  }

  Widget _publishNoticeButton(
      BuildContext context, FinanceState state, FinanceBloc bloc) {
    final loc = AppLocalizations.of(context);
    final label = state.noticeDone
        ? loc.adminFinanceManagementNoticeDone
        : loc.adminFinanceManagementNoticePublish;
    final icon = state.noticeDone ? Icons.check_circle_outline : Icons.campaign_outlined;
    final onPressed =
        state.busy ? null : () => bloc.add(const FinanceReportNoticePublished());
    if (context.isCompact) {
      return IconButton.filledTonal(
        tooltip: label,
        icon: Icon(icon),
        onPressed: onPressed,
      );
    }
    return AppButton(
      label: label,
      icon: icon,
      variant: AppButtonVariant.secondary,
      onPressed: onPressed,
    );
  }

  Widget _filters(FinanceState state, FinanceBloc bloc) {
    void search() => bloc.add(FinanceFiltersChanged(
          statusFilter: state.statusFilter,
          typeFilter: state.typeFilter,
          search: _searchController.text,
        ));
    void dateChanged({String? from, String? to}) {
      bloc
        ..add(FinanceDateRangeChanged(from: from, to: to))
        ..add(const FinanceRefreshRequested());
    }

    return FinanceFilterPanel(
      statusFilter: state.statusFilter,
      typeFilter: state.typeFilter,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      searchController: _searchController,
      onStatusChanged: (v) => bloc.add(FinanceFiltersChanged(
          statusFilter: v, typeFilter: state.typeFilter)),
      onTypeChanged: (v) => bloc.add(FinanceFiltersChanged(
          statusFilter: state.statusFilter, typeFilter: v)),
      onDateFromChanged: (v) => dateChanged(from: v),
      onDateToChanged: (v) => dateChanged(to: v),
      onSearch: search,
      onReset: () {
        _searchController.clear();
        bloc.add(const FinanceFiltersReset());
      },
    );
  }

  List<Widget> _ledger(BuildContext context, FinanceState state, FinanceBloc bloc) {
    final loc = AppLocalizations.of(context);
    final ledger = state.ledger;
    if (state.loading && ledger == null) return const [SkeletonLoader(lines: 6)];
    if (state.error != null) {
      return [
        InlineError(
          message: loc.adminFinanceManagementErrorsLoadFailed,
          onRetry: () => bloc.add(const FinanceRefreshRequested()),
        ),
      ];
    }
    if (ledger == null || ledger.items.isEmpty) {
      return [
        EmptyState(
          icon: Icons.receipt_long_outlined,
          message:
              '${loc.adminFinanceManagementLedgerEmpty}\n${loc.adminFinanceManagementLedgerEmptyHint}',
        ),
      ];
    }
    return [
      SectionTitle(loc.adminFinanceManagementLedgerCount(ledger.total)),
      ReloadingBar(visible: state.loading),
      CardGrid(
        minItemWidth: 380,
        maxColumns: 2,
        children: [
          for (final txn in ledger.items) _txnCard(context, state, bloc, txn),
        ],
      ),
      PageStepper(
        label: loc.adminFinanceManagementLedgerPage(state.page, bloc.totalPages),
        onPrevious: state.page > 1
            ? () => bloc.add(FinancePageChanged(delta: -1))
            : null,
        onNext: state.page < bloc.totalPages
            ? () => bloc.add(FinancePageChanged(delta: 1))
            : null,
      ),
    ];
  }

  Widget _txnCard(BuildContext context, FinanceState state, FinanceBloc bloc,
      FinanceTransaction txn) {
    return FinanceTxnCard(
      key: ValueKey(txn.id),
      txn: txn,
      expanded: state.expandedId == txn.id,
      busy: state.busy,
      onToggle: () => bloc.add(FinanceRowToggled(id: txn.id)),
      actions: FinanceTxnActions(
        onSubmit: () => bloc.add(FinanceDraftSubmitted(txn: txn)),
        onApprove: () => _approve(context, bloc, txn),
        onReject: () => _withReason(context, bloc, txn, _ReasonAction.reject),
        onReverse: () => _withReason(context, bloc, txn, _ReasonAction.reverse),
        onDelete: () => _withReason(context, bloc, txn, _ReasonAction.delete),
        onEdit: () => showFinanceTransactionSheet(context, bloc: bloc, editing: txn),
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, FinanceBloc bloc, FinanceTransaction txn) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: loc.adminFinanceManagementModalsApproveTitle,
      message: loc.adminFinanceManagementModalsApproveConfirm,
    );
    if (confirmed && context.mounted) {
      await dispatchForBool(bloc, (c) => FinanceApproved(txn: txn, completer: c));
    }
  }

  Future<void> _withReason(BuildContext context, FinanceBloc bloc,
      FinanceTransaction txn, _ReasonAction action) async {
    final loc = AppLocalizations.of(context);
    final (title, label) = switch (action) {
      _ReasonAction.reject => (
          loc.adminFinanceManagementModalsRejectTitle,
          loc.adminFinanceManagementModalsRejectReason,
        ),
      _ReasonAction.reverse => (
          loc.adminFinanceManagementModalsReverseTitle,
          loc.adminFinanceManagementModalsReverseReason,
        ),
      _ReasonAction.delete => (
          loc.adminFinanceManagementModalsDeleteTitle,
          loc.adminFinanceManagementModalsDeleteReason,
        ),
    };
    final reason = await showReasonDialog(
      context,
      title: title,
      label: label,
      summary: txn.description,
      confirmLabel: loc.commonConfirmAction,
      validator: (text) =>
          text.isEmpty ? loc.adminFinanceManagementErrorsReasonRequired : null,
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    final ok = switch (action) {
      _ReasonAction.reject => await dispatchForBool(
          bloc, (c) => FinanceRejected(txn: txn, reason: reason, completer: c)),
      _ReasonAction.reverse => await dispatchForBool(
          bloc, (c) => FinanceReversed(txn: txn, reason: reason, completer: c)),
      _ReasonAction.delete => await dispatchForBool(
          bloc, (c) => FinanceDeleted(txn: txn, reason: reason, completer: c)),
    };
    if (ok && context.mounted) showAppToast(context, loc.commonSave);
  }
}

/// Reject / reverse / delete all require a reason.
enum _ReasonAction { reject, reverse, delete }
