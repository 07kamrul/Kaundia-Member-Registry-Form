import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/enums/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../presentation/bloc/submissions_cubit.dart';
import '../presentation/widgets/management_widgets.dart';
import 'submissions_list_page.dart';

/// Full submission review (Angular submission-detail): every section of the
/// application, attachment previews, and approve/reject in review mode.
class SubmissionDetailPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const SubmissionDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<SubmissionDetailPage> createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final id = widget.id ?? (ModalRoute.of(context)?.settings.arguments as String?);
    if (id == null) {
      return EmptyState(message: loc.commonNoData);
    }
    return BlocProvider(
      create: (_) => SubmissionDetailCubit(
        repository: AdminRepository(apiClient: sl<ApiClient>()),
        id: id,
      )..load(),
      child: const _SubmissionDetailView(),
    );
  }
}

class _SubmissionDetailView extends StatelessWidget {
  const _SubmissionDetailView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<SubmissionDetailCubit, SubmissionDetailState>(
      listener: (context, state) {
        if (state.actionError != null) {
          showAppToast(context, describeApiError(context, state.actionError), error: true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<SubmissionDetailCubit>();
        if (state.loading) {
          return const SkeletonLoader(lines: 8);
        }
        if (state.error != null) {
          return InlineError(message: loc.adminSubmissionDetailErrorsLoadFailed, onRetry: cubit.load);
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
                            onPressed: state.busy ? null : () => cubit.resendNotification(),
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
            _attachmentsSection(context, loc, s, cubit, state.busy),
            _propertiesSection(context, loc, s, cubit, state.busy),
            _nomineesSection(context, loc, s),
            _paymentSection(context, loc, s),
            if (s.rejectionReason != null && s.rejectionReason!.isNotEmpty)
              AppCard(
                title: loc.adminSubmissionDetailFieldsRejectionReason,
                child: Text(s.rejectionReason!),
              ),
            if (reviewMode) _reviewActions(context, loc, cubit, state.busy),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _personalSection(BuildContext context, AppLocalizations loc, dynamic s) {
    return AppCard(
      title: loc.adminSubmissionDetailPersonalInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsName, value: s.fullName as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsFatherOrHusband, value: s.fatherOrHusband as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsMother, value: s.mother as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsDob, value: s.dob as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsNationality, value: s.nationality as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsOccupation, value: s.occupation as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsNid, value: s.nid as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsGender, value: s.gender as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsEmail, value: s.email as String),
          if ((s as dynamic).memberId != null)
            InfoRow(label: loc.adminMemberDetailFMemberId, value: s.memberId as String),
        ],
      ),
    );
  }

  Widget _addressSection(BuildContext context, AppLocalizations loc, dynamic s) {
    String join(String? house, String? road, String? po, String? up, String? dist, String? div) =>
        [house, road, po, up, dist, div].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    return AppCard(
      title: loc.adminSubmissionDetailFieldsAddress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: loc.adminSubmissionDetailPermanentAddress,
            value: join(s.permanentHouse, s.permanentRoad, s.permanentPostOffice,
                s.permanentUpazila, s.permanentDistrict, s.permanentDivision),
          ),
          InfoRow(
            label: loc.adminSubmissionDetailCurrentAddress,
            value: join(s.currentHouse, s.currentRoad, s.currentPostOffice, s.currentUpazila,
                s.currentDistrict, s.currentDivision),
          ),
        ],
      ),
    );
  }

  Widget _emergencySection(BuildContext context, AppLocalizations loc, dynamic s) {
    final name = s.urgentContactName as String?;
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

  Widget _attachmentsSection(BuildContext context, AppLocalizations loc, dynamic s,
      SubmissionDetailCubit cubit, bool busy) {
    Widget preview(String? url, String label) {
      if (url == null || url.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(loc.adminSubmissionDetailNoAttachment,
              style: Theme.of(context).textTheme.bodySmall),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
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
          ],
        ),
      );
    }

    return AppCard(
      title: loc.adminSubmissionDetailAttachments,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          preview(s.memberPhotoUrl as String?, loc.adminSubmissionDetailFieldsMemberPhoto),
          _replaceButton(
            context,
            loc,
            label: '${loc.adminSubmissionDetailUploadAgain} — ${loc.adminSubmissionDetailFieldsMemberPhoto}',
            enabled: !busy,
            onPicked: (path) => cubit.replaceAttachment('member_photo', path),
          ),
          preview(s.receiptPhotoUrl as String?, loc.adminSubmissionDetailFieldsReceiptPhoto),
          _replaceButton(
            context,
            loc,
            label: '${loc.adminSubmissionDetailUploadAgain} — ${loc.adminSubmissionDetailFieldsReceiptPhoto}',
            enabled: !busy,
            imagesOnly: true,
            onPicked: (path) => cubit.replaceAttachment('receipt_photo', path),
          ),
          if (s.memberSignature != null && (s.memberSignature as String).isNotEmpty)
            InfoRow(label: loc.adminSubmissionDetailFieldsMemberSignature, value: s.memberSignature),
        ],
      ),
    );
  }

  Widget _replaceButton(
    BuildContext context,
    AppLocalizations loc, {
    required String label,
    required bool enabled,
    bool imagesOnly = false,
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

  Widget _propertiesSection(BuildContext context, AppLocalizations loc, dynamic s,
      SubmissionDetailCubit cubit, bool busy) {
    final properties = s.properties as List;
    if (properties.isEmpty) {
      return AppCard(
        title: loc.adminSubmissionDetailProperties,
        child: Text(loc.adminSubmissionDetailNoProperties),
      );
    }
    return AppCard(
      title:
          '${loc.adminSubmissionDetailProperties} (${loc.adminSubmissionDetailPropertyCount(properties.length)})',
      child: Column(
        children: [
          for (final p in properties)
            _PropertyTile(property: p, loc: loc, cubit: cubit, busy: busy),
        ],
      ),
    );
  }

  Widget _nomineesSection(BuildContext context, AppLocalizations loc, dynamic s) {
    final nominees = s.nominees as List;
    if (nominees.isEmpty) {
      return AppCard(
        title: loc.adminSubmissionDetailNominees,
        child: Text(loc.adminSubmissionDetailNoNominees),
      );
    }
    num shareTotal = 0;
    var shareDeclared = false;
    for (final n in nominees) {
      final share = n.sharePercentage as num?;
      if (share != null) {
        shareDeclared = true;
        shareTotal += share;
      }
    }
    return AppCard(
      title:
          '${loc.adminSubmissionDetailNominees} (${loc.adminSubmissionDetailNomineeCount(nominees.length)})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in nominees) ...[
            InfoRow(label: loc.adminSubmissionDetailFieldsName, value: n.name as String),
            InfoRow(label: loc.adminSubmissionDetailFieldsRelation, value: n.relation as String),
            InfoRow(label: loc.adminSubmissionDetailFieldsMobile, value: n.mobile as String),
            if (n.sharePercentage != null)
              InfoRow(
                label: loc.adminSubmissionDetailFieldLabelsPercentage,
                value: '${n.sharePercentage}%',
              ),
            const Divider(height: 16),
          ],
          if (shareDeclared)
            InfoRow(
              label: loc.adminSubmissionDetailShareTotal,
              value: '$shareTotal%',
            ),
          if (shareDeclared && shareTotal.round() != 100)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                loc.adminSubmissionDetailShareWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentSection(BuildContext context, AppLocalizations loc, dynamic s) {
    return AppCard(
      title: loc.adminSubmissionDetailPaymentSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsAdmissionFee, value: s.admissionFee as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsSubscription, value: s.subscription as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsReceiptNo, value: s.receiptNo as String),
          InfoRow(label: loc.adminSubmissionDetailFieldsPaymentMethod, value: s.paymentMethod as String),
        ],
      ),
    );
  }

  Widget _reviewActions(
      BuildContext context, AppLocalizations loc, SubmissionDetailCubit cubit, bool busy) {
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
                      final confirmed = await AppDialog.confirm(
                        context,
                        title: loc.adminSubmissionDetailApproveModalTitle,
                        message: loc.adminSubmissionDetailApproveModalMessageSuffix,
                        confirmLabel: loc.adminSubmissionDetailApproveModalConfirmLabel,
                      );
                      if (confirmed && context.mounted) {
                        final ok = await cubit.approve();
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
              onPressed: busy ? null : () => _openRejectDialog(context, loc, cubit),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRejectDialog(
      BuildContext context, AppLocalizations loc, SubmissionDetailCubit cubit) async {
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
    final emailSent = await cubit.reject(reason);
    if (emailSent && context.mounted) context.go('/submissions');
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({
    required this.property,
    required this.loc,
    required this.cubit,
    required this.busy,
  });

  final dynamic property; // SubmissionProperty
  final AppLocalizations loc;
  final SubmissionDetailCubit cubit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final docs = property.applicableDocs as List;
    final types = [
      ...(property.propertyType as List).whereType<String>(),
      if ((property.propertyTypeOther as String?)?.isNotEmpty == true) property.propertyTypeOther,
    ].join(', ');
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        types.isEmpty ? loc.adminSubmissionDetailPropertyCardTitle : types,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if ((property.khatianNo as String?)?.isNotEmpty == true)
            '${loc.adminSubmissionDetailFieldLabelsKhatianNo} ${property.khatianNo}',
          if ((property.landQuantity as String?)?.isNotEmpty == true)
            '${loc.adminSubmissionDetailFieldLabelsLandQuantity} ${property.landQuantity}',
          if ((property.ownership as String?)?.isNotEmpty == true) property.ownership,
        ].join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((property.dagNoCs as String?)?.isNotEmpty == true)
                InfoRow(label: loc.adminSubmissionDetailFieldLabelsDagNoCs, value: property.dagNoCs),
              if ((property.dagNoRs as String?)?.isNotEmpty == true)
                InfoRow(label: loc.adminSubmissionDetailFieldLabelsDagNoRs, value: property.dagNoRs),
              if ((property.holdingNumber as String?)?.isNotEmpty == true)
                InfoRow(
                    label: loc.adminSubmissionDetailFieldLabelsHoldingNumber,
                    value: property.holdingNumber),
              if ((property.myShareQuantity as String?)?.isNotEmpty == true)
                InfoRow(
                    label: loc.adminSubmissionDetailFieldLabelsMyShareQuantity,
                    value: property.myShareQuantity),
              if (property.jointOwnerCount != null)
                InfoRow(label: loc.adminSubmissionDetailJointOwnerCountLabel, value: '${property.jointOwnerCount}'),
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
                  title: Text(doc.docType as String),
                  subtitle: (doc.fileUrl as String?) != null
                      ? null
                      : Text(loc.adminSubmissionDetailFileMissing),
                  trailing: (doc.fileUrl as String?) != null
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined),
                            tooltip: loc.adminSubmissionDetailView,
                            onPressed: doc.fileUrl == null
                                ? null
                                : () => showImagePreview(context, doc.fileUrl!, doc.docType),
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload_file_outlined),
                            tooltip: loc.adminSubmissionDetailReplaceFile,
                            onPressed: busy
                                ? null
                                : () async {
                                    final result =
                                        await FilePicker.platform.pickFiles(type: FileType.any);
                                    final path = result?.files.single.path;
                                    if (path != null) {
                                      await cubit.replaceDocument(doc.id as String, path);
                                    }
                                  },
                          ),
                        ])
                      : IconButton(
                          icon: const Icon(Icons.upload_file_outlined),
                          tooltip: loc.adminSubmissionDetailReplaceFile,
                          onPressed: busy
                              ? null
                              : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(type: FileType.any);
                                  final path = result?.files.single.path;
                                  if (path != null) {
                                    await cubit.replaceDocument(doc.id as String, path);
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
