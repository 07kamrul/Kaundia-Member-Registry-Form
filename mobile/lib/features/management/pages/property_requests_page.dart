import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/enums/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/property_requests_bloc.dart';
import '../presentation/widgets/management_widgets.dart';
import '../presentation/widgets/property_requests_widgets.dart';
import 'submissions_list_page.dart' show statusLabel;

/// Property change request review queue (Angular property-requests): status
/// filter, expandable payload detail, approve / cancel with reason.
class PropertyRequestsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PropertyRequestsPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PropertyRequestsBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..add(const PropertyRequestsLoadRequested()),
      child: const _PropertyRequestsView(),
    );
  }
}

String _statusText(AppLocalizations loc, PropertyRequestStatus status) =>
    switch (status) {
      PropertyRequestStatus.pending =>
        loc.adminPropertyRequestsStatusLabelsPending,
      PropertyRequestStatus.approved =>
        loc.adminPropertyRequestsStatusLabelsApproved,
      PropertyRequestStatus.cancelled =>
        loc.adminPropertyRequestsStatusLabelsCancelled,
      _ => statusLabel(loc, SubmissionStatus.unknown),
    };

StatusKind _statusKind(PropertyRequestStatus status) => switch (status) {
      PropertyRequestStatus.pending => StatusKind.pending,
      PropertyRequestStatus.approved => StatusKind.approved,
      PropertyRequestStatus.cancelled => StatusKind.rejected,
      _ => StatusKind.neutral,
    };

class _PropertyRequestsView extends StatelessWidget {
  const _PropertyRequestsView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<PropertyRequestsBloc, PropertyRequestsState>(
      listener: (context, state) => _notify(context, loc, state),
      builder: (context, state) {
        final bloc = context.read<PropertyRequestsBloc>();
        return PageBody(
          onRefresh: () => reloadAndWait(
              bloc, const PropertyRequestsLoadRequested(), (s) => s.loading),
          children: [
            PageHeader(
              icon: Icons.home_work_outlined,
              title: loc.adminPropertyRequestsTitle,
              subtitle: loc.adminPropertyRequestsSubtitle,
            ),
            ManagementFilterChips<PropertyRequestStatus>(
              selected: state.statusFilter,
              options: [
                (
                  PropertyRequestStatus.unknown,
                  loc.adminPropertyRequestsStatusLabelsAll
                ),
                for (final s in const [
                  PropertyRequestStatus.pending,
                  PropertyRequestStatus.approved,
                  PropertyRequestStatus.cancelled,
                ])
                  (s, _statusText(loc, s)),
              ],
              onSelected: (v) =>
                  bloc.add(PropertyRequestsStatusFilterChanged(status: v)),
            ),
            const SizedBox(height: 8),
            ..._content(loc, bloc, state),
          ],
        );
      },
    );
  }

  void _notify(
      BuildContext context, AppLocalizations loc, PropertyRequestsState state) {
    if (state.actionError != null) {
      showAppToast(
        context,
        state.actionError == 'reasonRequired'
            ? loc.adminPropertyRequestsErrorsReasonRequired
            : describeApiError(context, state.actionError),
        error: true,
      );
    }
    // An empty list shows the load error inline instead.
    if (state.error != null && state.items.isNotEmpty) {
      showAppToast(context, loc.adminPropertyRequestsErrorsLoadFailed,
          error: true);
    }
  }

  List<Widget> _content(AppLocalizations loc, PropertyRequestsBloc bloc,
      PropertyRequestsState state) {
    if (state.loading) return const [SkeletonLoader(lines: 4, height: 120)];
    if (state.items.isEmpty && state.error != null) {
      return [
        InlineError(
          message: loc.adminPropertyRequestsErrorsLoadFailed,
          onRetry: () => bloc.add(const PropertyRequestsLoadRequested()),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        EmptyState(
          message: loc.adminPropertyRequestsNoRequests,
          icon: Icons.home_work_outlined,
        ),
      ];
    }
    return [
      ManagementRecordGrid(
        minItemWidth: 360,
        children: [
          for (final r in state.items)
            _RequestCard(request: r, busy: state.busyId == r.id),
        ],
      ),
    ];
  }
}

enum _RequestAction { approve, cancel }

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.request, required this.busy});

  final MemberPropertyRequest request;
  final bool busy;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  _RequestAction? _active;

  bool _loading(_RequestAction action) => widget.busy && _active == action;

  String get _reference {
    final r = widget.request;
    final year = DateTime.tryParse(r.createdAt)?.year ?? DateTime.now().year;
    return 'PR-$year-${'${r.id}'.padLeft(4, '0')}';
  }

  Future<void> _approve(AppLocalizations loc) async {
    final bloc = context.read<PropertyRequestsBloc>();
    final confirmed = await confirmDialog(
      context,
      title: loc.adminPropertyRequestsApproveModalTitle,
      message: '$_reference ${loc.adminPropertyRequestsApproveModalMessageSuffix}',
      confirmLabel: loc.adminPropertyRequestsApproveModalConfirmLabel,
    );
    if (!confirmed || !mounted) return;
    setState(() => _active = _RequestAction.approve);
    bloc.add(PropertyRequestApproved(request: widget.request));
  }

  Future<void> _cancel(AppLocalizations loc) async {
    final bloc = context.read<PropertyRequestsBloc>();
    final reason = await showReasonDialog(
      context,
      title: loc.adminPropertyRequestsCancelModalTitle,
      summary: '$_reference ${loc.adminPropertyRequestsCancelModalMessageSuffix}',
      label: loc.adminPropertyRequestsCancelReasonLabel,
      hint: loc.adminPropertyRequestsCancelModalPlaceholder,
      confirmLabel: loc.adminPropertyRequestsCancelModalConfirmLabel,
      validator: (text) =>
          text.isEmpty ? loc.adminPropertyRequestsErrorsReasonRequired : null,
    );
    if (reason == null || !mounted) return;
    setState(() => _active = _RequestAction.cancel);
    bloc.add(PropertyRequestCancelled(request: widget.request, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final r = widget.request;
    final date = DateTime.tryParse(r.createdAt);
    final cancelReason = r.cancelReason;
    return ManagementRecordCard(
      leading: ManagementAvatar(name: r.memberName ?? '?'),
      title: '${r.memberName ?? '—'} ${r.memberCode ?? ''}'.trim(),
      subtitle: propertyRequestSummary(r.payload),
      badge: StatusBadge(
          kind: _statusKind(r.status), label: _statusText(loc, r.status)),
      actions: _actions(loc),
      children: [
        InfoRow(
            label: loc.adminPropertyRequestsTableHeadersReference,
            value: _reference),
        InfoRow(
            label: loc.adminPropertyRequestsTableHeadersAction,
            value: propertyRequestActionLabel(loc, r.action)),
        InfoRow(
          label: loc.adminPropertyRequestsTableHeadersDate,
          value:
              date == null ? r.createdAt : DateFormat('yyyy-MM-dd').format(date),
        ),
        if (r.action == PropertyRequestAction.delete)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ManagementCallout(
              message: loc.adminPropertyRequestsDeleteRequestNote,
              icon: Icons.delete_sweep_outlined,
            ),
          ),
        PropertyRequestPayloadTile(payload: r.payload),
        if (cancelReason != null && cancelReason.isNotEmpty)
          InfoRow(
              label: loc.adminPropertyRequestsCancelReasonLabel,
              value: cancelReason,
              expanded: true),
      ],
    );
  }

  List<Widget> _actions(AppLocalizations loc) {
    if (widget.request.status != PropertyRequestStatus.pending) return const [];
    final busy = widget.busy;
    return [
      AppButton(
        label: loc.adminPropertyRequestsCancelButton,
        variant: AppButtonVariant.danger,
        icon: Icons.close,
        loading: _loading(_RequestAction.cancel),
        onPressed: busy ? null : () => _cancel(loc),
      ),
      AppButton(
        label: loc.adminPropertyRequestsApproveButton,
        icon: Icons.check,
        loading: _loading(_RequestAction.approve),
        onPressed: busy ? null : () => _approve(loc),
      ),
    ];
  }
}
