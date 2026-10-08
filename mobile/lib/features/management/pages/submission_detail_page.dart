import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/submissions_bloc.dart';
import '../presentation/widgets/management_widgets.dart';
import 'submissions_list_page.dart';

/// Full submission review (Angular submission-detail): every section of the
/// application, attachment previews, and approve/reject in review mode.
class SubmissionDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const SubmissionDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final id = this.id ?? (ModalRoute.of(context)?.settings.arguments as String?);
    if (id == null) {
      return EmptyState(message: loc.commonNoData);
    }
    return BlocProvider(
      create: (_) => SubmissionDetailBloc(
        repository: AdminRepository(apiClient: sl<ApiClient>()),
        id: id,
      )..load(),
      child: const _SubmissionDetailView(),
    );
  }
}

String _joinAddress(
  String? house,
  String? road,
  String? po,
  String? up,
  String? dist,
  String? div,
) =>
    [house, road, po, up, dist, div]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(', ');

class _SubmissionDetailView extends StatelessWidget {
  const _SubmissionDetailView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<SubmissionDetailBloc, SubmissionDetailState>(
      listener: (context, state) {
        if (state.actionError != null) {
          showAppToast(context, describeApiError(context, state.actionError), error: true);
        }
      },
      builder: (context, state) {
        final bloc = context.read<SubmissionDetailBloc>();
        if (state.loading) {
          return const SkeletonLoader(lines: 8);
        }
        if (state.error != null) {
          return InlineError(message: loc.adminSubmissionDetailErrorsLoadFailed, onRetry: () => bloc.add(const SubmissionsLoadRequested()));
        }
        final s = state.submission;
        if (s == null) return EmptyState(message: loc.commonNoData);

        final reviewMode = s.status == SubmissionStatus.pending;
        return ListView(
          children: [
            PageHeader(
              title: loc.adminSubmissionDetailTitle,
              subtitle: s.fullName,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: StatusBadge(
                    kind: switch (s.status) {
                      SubmissionStatus.pending => StatusKind.pending,
                      SubmissionStatus.approved => StatusKind.approved,
                      SubmissionStatus.rejected => StatusKind.rejected,
                      _ => StatusKind.neutral,
                    },
                    label: statusLabel(loc, s.status),
                  ),
                ),
              ],
            ),
            if (state.rejectionNotice != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.adminSubmissionDetailErrorsRejectEmailFailed),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            label: loc.adminSubmissionDetailResendButton,
                            variant: AppButtonVariant.secondary,
                            onPressed: state.busy ? null : () => bloc.add(SubmissionDetailResendNotificationRequested()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            _personalSection(context, loc, s),
            _addressSection(context, loc, s),
            _emergencySection(context, loc, s),
            _attachmentsSection(context, loc, s, bloc, state.busy),
            _propertiesSection(context, loc, s, bloc, state.busy),
            _nomineesSection(context, loc, s),
            _paymentSection(context, loc, s),
            if (s.rejectionReason != null && s.rejectionReason!.isNotEmpty)
              AppCard(
                title: loc.adminSubmissionDetailFieldsRejectionReason,
                child: Text(s.rejectionReason!),
              ),
            if (reviewMode) _reviewActions(context, loc, bloc, state.busy),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _personalSection(BuildContext context, AppLocalizations loc, SubmissionDetail s) {
    return AppCard(
      title: loc.adminSubmissionDetailPersonalInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsName, value: s.fullName),
          InfoRow(label: loc.adminSubmissionDetailFieldsFatherOrHusband, value: s.fatherOrHusband),
          InfoRow(label: loc.adminSubmissionDetailFieldsMother, value: s.mother),
          InfoRow(label: loc.adminSubmissionDetailFieldsDob, value: s.dob),
          InfoRow(label: loc.adminSubmissionDetailFieldsNationality, value: s.nationality),
          InfoRow(label: loc.adminSubmissionDetailFieldsOccupation, value: s.occupation),
          InfoRow(label: loc.adminSubmissionDetailFieldLabelsNid, value: s.nid),
          InfoRow(label: loc.adminSubmissionDetailFieldsGender, value: s.gender),
          InfoRow(label: loc.adminSubmissionDetailFieldsEmail, value: s.email),
          if (s.memberId != null)
            InfoRow(label: loc.adminMemberDetailFMemberId, value: s.memberId!),
        ],
      ),
    );
  }

  Widget _addressSection(BuildContext context, AppLocalizations loc, SubmissionDetail s) {
    return AppCard(
      title: loc.adminSubmissionDetailFieldsAddress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: loc.adminSubmissionDetailPermanentAddress,
            value: _joinAddress(s.permanentHouse, s.permanentRoad, s.permanentPostOffice,
                s.permanentUpazila, s.permanentDistrict, s.permanentDivision),
          ),
          InfoRow(
            label: loc.adminSubmissionDetailCurrentAddress,
            value: _joinAddress(s.currentHouse, s.currentRoad, s.currentPostOffice,
                s.currentUpazila, s.currentDistrict, s.currentDivision),
          ),
        ],
      ),
    );
  }

  Widget _emergencySection(BuildContext context, AppLocalizations loc, SubmissionDetail s) {
    final name = s.urgentContactName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    return AppCard(
      title: loc.adminSubmissionDetailUrgentContact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsName, value: name),
          InfoRow(label: loc.adminSubmissionDetailFieldsRelation, value: s.urgentContactRelation ?? ''),
          InfoRow(label: loc.adminSubmissionDetailFieldsMobile, value: s.urgentContactMobile ?? ''),
          InfoRow(label: loc.adminSubmissionDetailFieldsAddress, value: s.urgentContactAddress ?? ''),
        ],
      ),
    );
  }

  Widget _attachmentsSection(
      BuildContext context, AppLocalizations loc, SubmissionDetail s, SubmissionDetailBloc bloc, bool busy) {
    Widget preview(String? url, String label) {
      if (url == null || url.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            loc.adminSubmissionDetailNoAttachment,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () => showImagePreview(context, url, label),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(loc.adminSubmissionDetailFileMissing),
            ),
          ),
        ),
      );
    }

    return AppCard(
      title: loc.adminSubmissionDetailAttachments,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          preview(s.memberPhotoUrl, loc.adminSubmissionDetailFieldsMemberPhoto),
          _replaceButton(
            context,
            '${loc.adminSubmissionDetailUploadAgain} — ${loc.adminSubmissionDetailFieldsMemberPhoto}',
            enabled: !busy,
            imagesOnly: true,
            onPicked: (path) => bloc.add(SubmissionDetailAttachmentReplaceRequested('member_photo', path)),
          ),
          preview(s.receiptPhotoUrl, loc.adminSubmissionDetailFieldsReceiptPhoto),
          _replaceButton(
            context,
            '${loc.adminSubmissionDetailUploadAgain} — ${loc.adminSubmissionDetailFieldsReceiptPhoto}',
            enabled: !busy,
            imagesOnly: true,
            onPicked: (path) => bloc.add(SubmissionDetailAttachmentReplaceRequested('receipt_photo', path)),
          ),
          if (s.memberSignature != null && s.memberSignature!.isNotEmpty)
            InfoRow(
                label: loc.adminSubmissionDetailFieldsMemberSignature,
                value: s.memberSignature!),
        ],
      ),
    );
  }

  Widget _replaceButton(
    BuildContext context,
    String label, {
    required bool enabled,
    required bool imagesOnly,
    required ValueChanged<String> onPicked,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppButton(
        label: label,
        variant: AppButtonVariant.ghost,
        onPressed: enabled
            ? () async {
                final result = await FilePicker.platform.pickFiles(
                  type: imagesOnly ? FileType.image : FileType.any,
                );
                final path = result?.files.single.path;
                if (path != null && context.mounted) onPicked(path);
              }
            : null,
      ),
    );
  }

  Widget _propertiesSection(
      BuildContext context, AppLocalizations loc, SubmissionDetail s, SubmissionDetailBloc bloc, bool busy) {
    if (s.properties.isEmpty) {
      return AppCard(
        title: loc.adminSubmissionDetailProperties,
        child: Text(loc.adminSubmissionDetailNoProperties),
      );
    }
    return AppCard(
      title:
          '${loc.adminSubmissionDetailProperties} (${loc.adminSubmissionDetailPropertyCount(s.properties.length)})',
      child: Column(
        children: [
          for (final p in s.properties) _PropertyTile(property: p, bloc: bloc, busy: busy),
        ],
      ),
    );
  }

  Widget _nomineesSection(BuildContext context, AppLocalizations loc, SubmissionDetail s) {
    if (s.nominees.isEmpty) {
      return AppCard(
        title: loc.adminSubmissionDetailNominees,
        child: Text(loc.adminSubmissionDetailNoNominees),
      );
    }
    num shareTotal = 0;
    var shareDeclared = false;
    for (final n in s.nominees) {
      final share = n.sharePercentage;
      if (share != null) {
        shareDeclared = true;
        shareTotal += share;
      }
    }
    return AppCard(
      title:
          '${loc.adminSubmissionDetailNominees} (${loc.adminSubmissionDetailNomineeCount(s.nominees.length)})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in s.nominees) ...[
            InfoRow(label: loc.adminSubmissionDetailFieldsName, value: n.name),
            InfoRow(label: loc.adminSubmissionDetailFieldsRelation, value: n.relation),
            InfoRow(label: loc.adminSubmissionDetailFieldsMobile, value: n.mobile),
            if (n.sharePercentage != null)
              InfoRow(
                label: loc.adminSubmissionDetailFieldLabelsPercentage,
                value: '${n.sharePercentage}%',
              ),
            const Divider(height: 16),
          ],
          if (shareDeclared)
            InfoRow(
              label: loc.adminSubmissionDetailFieldLabelsPercentage,
              value: loc.adminSubmissionDetailShareTotal(shareTotal),
            ),
          if (shareDeclared && shareTotal.round() != 100)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                loc.adminSubmissionDetailShareWarning(shareTotal),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentSection(BuildContext context, AppLocalizations loc, SubmissionDetail s) {
    return AppCard(
      title: loc.adminSubmissionDetailPaymentSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsAdmissionFee, value: s.admissionFee),
          InfoRow(label: loc.adminSubmissionDetailFieldsSubscription, value: s.subscription),
          InfoRow(label: loc.adminSubmissionDetailFieldsReceiptNo, value: s.receiptNo),
          InfoRow(label: loc.adminSubmissionDetailFieldsPaymentMethod, value: s.paymentMethod),
        ],
      ),
    );
  }

  Widget _reviewActions(
      BuildContext context, AppLocalizations loc, SubmissionDetailBloc bloc, bool busy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: loc.adminSubmissionDetailApproveButton,
              icon: Icons.check,
              expanded: true,
              onPressed: busy
                  ? null
                  : () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: loc.adminSubmissionDetailApproveModalTitle,
                        message: loc.adminSubmissionDetailApproveModalMessageSuffix,
                        confirmLabel: loc.adminSubmissionDetailApproveModalConfirmLabel,
                      );
                      if (confirmed && context.mounted) {
                        final ok = bloc.add(SubmissionDetailApproveRequested());
                        if (ok && context.mounted) context.go('/submissions');
                      }
                    },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: loc.adminSubmissionDetailRejectButton,
              variant: AppButtonVariant.danger,
              icon: Icons.close,
              expanded: true,
              onPressed: busy ? null : () => _openRejectDialog(context, loc, bloc),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRejectDialog(
      BuildContext context, AppLocalizations loc, SubmissionDetailBloc bloc) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.adminSubmissionDetailRejectModalTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: loc.adminSubmissionDetailRejectModalPlaceholder,
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
            child: Text(loc.adminSubmissionDetailRejectModalConfirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final reason = controller.text.trim();
    if (reason.isEmpty) {
      if (context.mounted) {
        showAppToast(context, loc.adminSubmissionDetailErrorsReasonRequired, error: true);
      }
      return;
    }
    final emailSent = bloc.add(SubmissionDetailRejectRequested(reason));
    if (emailSent && context.mounted) context.go('/submissions');
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({required this.property, required this.bloc, required this.busy});

  final SubmissionProperty property;
  final SubmissionDetailBloc bloc;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final docs = property.applicableDocs;
    final types = [
      ...property.propertyType,
      if (property.propertyTypeOther?.trim().isNotEmpty == true) property.propertyTypeOther!.trim(),
    ];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        types.isEmpty ? loc.adminSubmissionDetailPropertyCardTitle : types.join(', '),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (property.khatianNo?.isNotEmpty == true)
            '${loc.adminSubmissionDetailFieldLabelsKhatianNo} ${property.khatianNo}',
          if (property.landQuantity?.isNotEmpty == true)
            '${loc.adminSubmissionDetailFieldLabelsLandQuantity} ${property.landQuantity}',
          if (property.ownership?.isNotEmpty == true) property.ownership!,
        ].join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (property.dagNoCs?.isNotEmpty == true)
                InfoRow(
                    label: loc.adminSubmissionDetailFieldLabelsDagNoCs,
                    value: property.dagNoCs!),
              if (property.dagNoRs?.isNotEmpty == true)
                InfoRow(
                    label: loc.adminSubmissionDetailFieldLabelsDagNoRs,
                    value: property.dagNoRs!),
              if (property.holdingNumber?.isNotEmpty == true)
                InfoRow(
                    label: loc.adminSubmissionDetailFieldLabelsHoldingNumber,
                    value: property.holdingNumber!),
              if (property.myShareQuantity?.isNotEmpty == true)
                InfoRow(
                    label: loc.adminSubmissionDetailFieldLabelsMyShareQuantity,
                    value: property.myShareQuantity!),
              if (property.jointOwnerCount != null)
                InfoRow(
                    label: loc.adminSubmissionDetailJointOwnerCountLabel,
                    value: '${property.jointOwnerCount}'),
              const SizedBox(height: 8),
              Text(
                docs.isEmpty
                    ? loc.adminSubmissionDetailNoApplicableDocs
                    : loc.adminSubmissionDetailApplicableDocs,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final doc in docs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(doc.docType),
                  subtitle:
                      doc.fileUrl == null ? Text(loc.adminSubmissionDetailFileMissing) : null,
                  trailing: IconButton(
                    icon: Icon(doc.fileUrl == null
                        ? Icons.upload_file_outlined
                        : Icons.visibility_outlined),
                    tooltip: doc.fileUrl == null
                        ? loc.adminSubmissionDetailReplaceFile
                        : loc.adminSubmissionDetailView,
                    onPressed: busy
                        ? null
                        : () async {
                            if (doc.fileUrl != null) {
                              showImagePreview(context, doc.fileUrl!, doc.docType);
                              return;
                            }
                            final result =
                                await FilePicker.platform.pickFiles(type: FileType.any);
                            final path = result?.files.single.path;
                            if (path != null) {
                              bloc.add(SubmissionDetailDocumentReplaceRequested(doc.id, path));
                            }
                          },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
