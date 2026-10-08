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
import '../presentation/bloc/property_requests_cubit.dart';
import '../presentation/widgets/management_widgets.dart';
import 'submissions_list_page.dart' show statusLabel;

/// Property change request review queue (Angular property-requests): status
/// filter, expandable payload detail, approve / cancel with reason.
class PropertyRequestsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PropertyRequestsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          PropertyRequestsCubit(repository: AdminRepository(apiClient: sl<ApiClient>()))..load(),
      child: BlocConsumer<PropertyRequestsCubit, PropertyRequestsState>(
        listener: (context, state) {
          if (state.actionError != null) {
            if (state.actionError == 'reasonRequired') {
              showAppToast(context, loc.adminPropertyRequestsErrorsReasonRequired, error: true);
            } else {
              showAppToast(context, describeApiError(context, state.actionError), error: true);
            }
          }
          if (state.error != null) {
            showAppToast(context, loc.adminPropertyRequestsErrorsLoadFailed, error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<PropertyRequestsCubit>();
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminPropertyRequestsTitle,
                  subtitle: loc.adminPropertyRequestsSubtitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<PropertyRequestStatus?>(
                  initialValue: state.statusFilter,
                  decoration: InputDecoration(
                    labelText: loc.adminPropertyRequestsStatusLabelsAll,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<PropertyRequestStatus?>(
                      value: null,
                      child: Text(loc.adminPropertyRequestsStatusLabelsAll),
                    ),
                    DropdownMenuItem<PropertyRequestStatus?>(
                      value: PropertyRequestStatus.pending,
                      child: Text(loc.adminPropertyRequestsStatusLabelsPending),
                    ),
                    DropdownMenuItem<PropertyRequestStatus?>(
                      value: PropertyRequestStatus.approved,
                      child: Text(loc.adminPropertyRequestsStatusLabelsApproved),
                    ),
                    DropdownMenuItem<PropertyRequestStatus?>(
                      value: PropertyRequestStatus.cancelled,
                      child: Text(loc.adminPropertyRequestsStatusLabelsCancelled),
                    ),
                  ],
                  onChanged: cubit.setStatusFilter,
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 4)
              else if (state.items.isEmpty)
                EmptyState(message: loc.adminPropertyRequestsNoRequests)
              else
                AppDataTableCards<MemberPropertyRequest>(
                  items: state.items,
                  rowBuilder: (context, r) => _row(context, loc, cubit, r),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _actionLabel(AppLocalizations loc, PropertyRequestAction action) => switch (action) {
        PropertyRequestAction.add => loc.adminPropertyRequestsActionsAdd,
        PropertyRequestAction.edit => loc.adminPropertyRequestsActionsEdit,
        PropertyRequestAction.delete => loc.adminPropertyRequestsActionsDelete,
        _ => '—',
      };

  Widget _row(BuildContext context, AppLocalizations loc, PropertyRequestsCubit cubit,
      MemberPropertyRequest r) {
    final year = DateTime.tryParse(r.createdAt)?.year ?? DateTime.now().year;
    final reference = 'PR-$year-${'${r.id}'.padLeft(4, '0')}';
    final date = DateTime.tryParse(r.createdAt);
    final p = r.payload;
    final types = [...p.propertyType, if (p.propertyTypeOther?.isNotEmpty == true) p.propertyTypeOther!];
    final summary = [
      if (types.isNotEmpty) types.join(' / '),
      if (p.khatianNo != null) 'Khatian ${p.khatianNo}',
      if (p.dagNoCs != null) 'CS ${p.dagNoCs}',
      if (p.dagNoRs != null) 'RS ${p.dagNoRs}',
    ].join(' · ');
    final busy = cubit.state.busyId == r.id;
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
                        '${r.memberName ?? '—'} ${r.memberCode ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(summary, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(
                  kind: switch (r.status) {
                    PropertyRequestStatus.pending => StatusKind.pending,
                    PropertyRequestStatus.approved => StatusKind.approved,
                    PropertyRequestStatus.cancelled => StatusKind.rejected,
                    _ => StatusKind.neutral,
                  },
                  label: switch (r.status) {
                    PropertyRequestStatus.pending => loc.adminPropertyRequestsStatusLabelsPending,
                    PropertyRequestStatus.approved => loc.adminPropertyRequestsStatusLabelsApproved,
                    PropertyRequestStatus.cancelled =>
                      loc.adminPropertyRequestsStatusLabelsCancelled,
                    _ => statusLabel(loc, SubmissionStatus.unknown),
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(label: loc.adminPropertyRequestsTableHeadersReference, value: reference),
            InfoRow(label: loc.adminPropertyRequestsTableHeadersAction, value: _actionLabel(loc, r.action)),
            InfoRow(
              label: loc.adminPropertyRequestsTableHeadersDate,
              value: date == null ? r.createdAt : DateFormat('yyyy-MM-dd').format(date),
            ),
            // Payload detail.
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(loc.adminPropertyRequestsTableHeadersProperty,
                  style: Theme.of(context).textTheme.bodyMedium),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (types.isNotEmpty)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsType,
                            value: types.join(' / ')),
                      if (p.khatianNo != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsKhatianNo,
                            value: p.khatianNo!),
                      if (p.dagNoCs != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsDagNoCs,
                            value: p.dagNoCs!),
                      if (p.dagNoRs != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsDagNoRs,
                            value: p.dagNoRs!),
                      if (p.holdingNumber != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsHoldingNumber,
                            value: p.holdingNumber!),
                      if (p.landQuantity != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsLandQuantity,
                            value: p.landQuantity!),
                      if (p.myShareQuantity != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsMyShareQuantity,
                            value: p.myShareQuantity!),
                      if (p.ownership != null)
                        InfoRow(
                            label: loc.adminSubmissionDetailFieldLabelsOwnership,
                            value: p.ownership!),
                      if (p.coOwners.isNotEmpty)
                        InfoRow(
                          label: loc.adminPropertyRequestsPayloadCoOwners,
                          value: p.coOwners
                              .map((c) => '${c.ownerName} (${c.ownerPhone})')
                              .join(', '),
                          expanded: true,
                        ),
                      if (p.docs.isNotEmpty)
                        InfoRow(
                          label: loc.adminPropertyRequestsPayloadDocs,
                          value: p.docs.map((d) => d.docType).join(', '),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (r.cancelReason != null && r.cancelReason!.isNotEmpty)
              InfoRow(
                  label: loc.adminPropertyRequestsCancelReasonLabel, value: r.cancelReason!),
            if (r.status == PropertyRequestStatus.pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: loc.adminPropertyRequestsCancelButton,
                    variant: AppButtonVariant.danger,
                    onPressed: busy ? null : () => _cancelDialog(context, loc, cubit, r),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: loc.adminPropertyRequestsApproveButton,
                    icon: Icons.check,
                    onPressed: busy
                        ? null
                        : () async {
                            final confirmed = await AppDialog.confirm(
                              context,
                              title: loc.adminPropertyRequestsApproveModalTitle,
                              message: loc.adminPropertyRequestsApproveModalMessageSuffix,
                              confirmLabel: loc.adminPropertyRequestsApproveModalConfirmLabel,
                            );
                            if (confirmed && context.mounted) await cubit.approve(r);
                          },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelDialog(BuildContext context, AppLocalizations loc,
      PropertyRequestsCubit cubit, MemberPropertyRequest r) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.adminPropertyRequestsCancelModalTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: loc.adminPropertyRequestsCancelReasonLabel,
            hintText: loc.adminPropertyRequestsCancelModalPlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.adminPropertyRequestsCancelModalConfirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await cubit.cancel(r, controller.text);
  }
}
