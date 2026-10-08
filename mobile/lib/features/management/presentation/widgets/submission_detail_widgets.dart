import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/admin_entities.dart';
import 'management_widgets.dart';

/// Section cards for the submission review page. Pure presentation: every
/// mutation is reported through callbacks owned by the page.

String joinAddress(
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

/// Opens the platform file picker and returns the chosen local path.
Future<String?> pickFilePath({required bool imagesOnly}) async {
  final result = await FilePicker.platform.pickFiles(
    type: imagesOnly ? FileType.image : FileType.any,
  );
  return result?.files.single.path;
}

class SubmissionPersonalCard extends StatelessWidget {
  const SubmissionPersonalCard({super.key, required this.submission});

  final SubmissionDetail submission;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = submission;
    return ManagementSectionCard(
      title: loc.adminSubmissionDetailPersonalInfo,
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsName, value: s.fullName),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsFatherOrHusband,
              value: s.fatherOrHusband),
          InfoRow(label: loc.adminSubmissionDetailFieldsMother, value: s.mother),
          InfoRow(label: loc.adminSubmissionDetailFieldsDob, value: s.dob),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsNationality,
              value: s.nationality),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsOccupation,
              value: s.occupation),
          InfoRow(label: loc.adminSubmissionDetailFieldLabelsNid, value: s.nid),
          InfoRow(label: loc.adminSubmissionDetailFieldsGender, value: s.gender),
          InfoRow(label: loc.adminSubmissionDetailFieldsEmail, value: s.email),
          if (s.memberId != null)
            InfoRow(label: loc.adminMemberDetailFMemberId, value: s.memberId!),
        ],
      ),
    );
  }
}

class SubmissionAddressCard extends StatelessWidget {
  const SubmissionAddressCard({super.key, required this.submission});

  final SubmissionDetail submission;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = submission;
    return ManagementSectionCard(
      title: loc.adminSubmissionDetailFieldsAddress,
      icon: Icons.home_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: loc.adminSubmissionDetailPermanentAddress,
            value: joinAddress(s.permanentHouse, s.permanentRoad,
                s.permanentPostOffice, s.permanentUpazila, s.permanentDistrict,
                s.permanentDivision),
            expanded: true,
          ),
          InfoRow(
            label: loc.adminSubmissionDetailCurrentAddress,
            value: joinAddress(s.currentHouse, s.currentRoad,
                s.currentPostOffice, s.currentUpazila, s.currentDistrict,
                s.currentDivision),
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class SubmissionEmergencyCard extends StatelessWidget {
  const SubmissionEmergencyCard({super.key, required this.submission});

  final SubmissionDetail submission;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = submission;
    final name = s.urgentContactName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    return ManagementSectionCard(
      title: loc.adminSubmissionDetailUrgentContact,
      icon: Icons.contact_phone_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminSubmissionDetailFieldsName, value: name),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsRelation,
              value: s.urgentContactRelation ?? ''),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsMobile,
              value: s.urgentContactMobile ?? ''),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsAddress,
              value: s.urgentContactAddress ?? ''),
        ],
      ),
    );
  }
}

class SubmissionPaymentCard extends StatelessWidget {
  const SubmissionPaymentCard({super.key, required this.submission});

  final SubmissionDetail submission;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = submission;
    return ManagementSectionCard(
      title: loc.adminSubmissionDetailPaymentSummary,
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
              label: loc.adminSubmissionDetailFieldsAdmissionFee,
              value: s.admissionFee),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsSubscription,
              value: s.subscription),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsReceiptNo,
              value: s.receiptNo),
          InfoRow(
              label: loc.adminSubmissionDetailFieldsPaymentMethod,
              value: s.paymentMethod),
        ],
      ),
    );
  }
}

/// Member / receipt photo previews with "upload again" replacements.
class SubmissionAttachmentsCard extends StatelessWidget {
  const SubmissionAttachmentsCard({
    super.key,
    required this.submission,
    required this.busy,
    required this.onReplace,
  });

  final SubmissionDetail submission;
  final bool busy;

  /// (attachment kind, picked local path).
  final void Function(String kind, String path) onReplace;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = submission;
    final signature = s.memberSignature;
    return ManagementSectionCard(
      title: loc.adminSubmissionDetailAttachments,
      icon: Icons.attach_file,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            minItemWidth: 200,
            maxColumns: 2,
            children: [
              _AttachmentTile(
                label: loc.adminSubmissionDetailFieldsMemberPhoto,
                url: s.memberPhotoUrl,
                busy: busy,
                onPicked: (path) => onReplace('member_photo', path),
              ),
              _AttachmentTile(
                label: loc.adminSubmissionDetailFieldsReceiptPhoto,
                url: s.receiptPhotoUrl,
                busy: busy,
                onPicked: (path) => onReplace('receipt_photo', path),
              ),
            ],
          ),
          if (signature != null && signature.isNotEmpty) ...[
            const SizedBox(height: 8),
            InfoRow(
                label: loc.adminSubmissionDetailFieldsMemberSignature,
                value: signature),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.label,
    required this.url,
    required this.busy,
    required this.onPicked,
  });

  final String label;
  final String? url;
  final bool busy;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        _AttachmentPreview(url: url, label: label),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: loc.adminSubmissionDetailUploadAgain,
            icon: Icons.upload_outlined,
            variant: AppButtonVariant.ghost,
            onPressed: busy
                ? null
                : () async {
                    final path = await pickFilePath(imagesOnly: true);
                    if (path != null && context.mounted) onPicked(path);
                  },
          ),
        ),
      ],
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.url, required this.label});

  static const double _height = 160;

  final String? url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final link = url;
    if (link == null || link.isEmpty) {
      return _placeholder(context, Icons.image_not_supported_outlined,
          loc.adminSubmissionDetailNoAttachment);
    }
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showImagePreview(context, link, label),
        child: Image.network(
          link,
          height: _height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context,
              Icons.broken_image_outlined, loc.adminSubmissionDetailFileMissing),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      height: _height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}

class SubmissionPropertiesCard extends StatelessWidget {
  const SubmissionPropertiesCard({
    super.key,
    required this.submission,
    required this.busy,
    required this.onReplaceDocument,
  });

  final SubmissionDetail submission;
  final bool busy;

  /// (document id, picked local path).
  final void Function(String docId, String path) onReplaceDocument;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final properties = submission.properties;
    if (properties.isEmpty) {
      return ManagementSectionCard(
        title: loc.adminSubmissionDetailProperties,
        icon: Icons.landscape_outlined,
        child: ManagementMutedText(loc.adminSubmissionDetailNoProperties),
      );
    }
    return ManagementSectionCard(
      title:
          '${loc.adminSubmissionDetailProperties} (${loc.adminSubmissionDetailPropertyCount(properties.length)})',
      icon: Icons.landscape_outlined,
      child: Column(
        children: [
          for (var i = 0; i < properties.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            SubmissionPropertyTile(
              property: properties[i],
              busy: busy,
              onReplaceDocument: onReplaceDocument,
            ),
          ],
        ],
      ),
    );
  }
}

class SubmissionPropertyTile extends StatelessWidget {
  const SubmissionPropertyTile({
    super.key,
    required this.property,
    required this.busy,
    required this.onReplaceDocument,
  });

  final SubmissionProperty property;
  final bool busy;
  final void Function(String docId, String path) onReplaceDocument;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = property;
    final types = [
      ...p.propertyType,
      if (p.propertyTypeOther?.trim().isNotEmpty == true)
        p.propertyTypeOther!.trim(),
    ];
    final summary = [
      if (p.khatianNo?.isNotEmpty == true)
        '${loc.adminSubmissionDetailFieldLabelsKhatianNo} ${p.khatianNo}',
      if (p.landQuantity?.isNotEmpty == true)
        '${loc.adminSubmissionDetailFieldLabelsLandQuantity} ${p.landQuantity}',
      if (p.ownership?.isNotEmpty == true) p.ownership!,
    ].join(' · ');
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(
        types.isEmpty ? loc.adminSubmissionDetailPropertyCardTitle : types.join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: summary.isEmpty
          ? null
          : Text(summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall),
      children: [
        if (p.dagNoCs?.isNotEmpty == true)
          InfoRow(
              label: loc.adminSubmissionDetailFieldLabelsDagNoCs,
              value: p.dagNoCs!),
        if (p.dagNoRs?.isNotEmpty == true)
          InfoRow(
              label: loc.adminSubmissionDetailFieldLabelsDagNoRs,
              value: p.dagNoRs!),
        if (p.holdingNumber?.isNotEmpty == true)
          InfoRow(
              label: loc.adminSubmissionDetailFieldLabelsHoldingNumber,
              value: p.holdingNumber!),
        if (p.myShareQuantity?.isNotEmpty == true)
          InfoRow(
              label: loc.adminSubmissionDetailFieldLabelsMyShareQuantity,
              value: p.myShareQuantity!),
        if (p.jointOwnerCount != null)
          InfoRow(
              label: loc.adminSubmissionDetailJointOwnerCountLabel,
              value: '${p.jointOwnerCount}'),
        const SizedBox(height: 8),
        Text(
          p.applicableDocs.isEmpty
              ? loc.adminSubmissionDetailNoApplicableDocs
              : loc.adminSubmissionDetailApplicableDocs,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        for (final doc in p.applicableDocs)
          _DocumentRow(doc: doc, busy: busy, onReplace: onReplaceDocument),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.doc,
    required this.busy,
    required this.onReplace,
  });

  final ApplicableDoc doc;
  final bool busy;
  final void Function(String docId, String path) onReplace;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final url = doc.fileUrl;
    final missing = url == null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        missing ? Icons.report_gmailerrorred_outlined : Icons.description_outlined,
        color: missing ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(doc.docType, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: missing ? Text(loc.adminSubmissionDetailFileMissing) : null,
      onTap: missing ? null : () => showImagePreview(context, url, doc.docType),
      trailing: IconButton(
        icon: Icon(missing ? Icons.upload_file_outlined : Icons.visibility_outlined),
        tooltip: missing
            ? loc.adminSubmissionDetailReplaceFile
            : loc.adminSubmissionDetailView,
        onPressed: busy
            ? null
            : () async {
                if (!missing) {
                  showImagePreview(context, url, doc.docType);
                  return;
                }
                final path = await pickFilePath(imagesOnly: false);
                if (path != null) onReplace(doc.id, path);
              },
      ),
    );
  }
}

class SubmissionNomineesCard extends StatelessWidget {
  const SubmissionNomineesCard({super.key, required this.submission});

  final SubmissionDetail submission;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final nominees = submission.nominees;
    if (nominees.isEmpty) {
      return ManagementSectionCard(
        title: loc.adminSubmissionDetailNominees,
        icon: Icons.group_outlined,
        child: ManagementMutedText(loc.adminSubmissionDetailNoNominees),
      );
    }
    num shareTotal = 0;
    var shareDeclared = false;
    for (final n in nominees) {
      final share = n.sharePercentage;
      if (share != null) {
        shareDeclared = true;
        shareTotal += share;
      }
    }
    return ManagementSectionCard(
      title:
          '${loc.adminSubmissionDetailNominees} (${loc.adminSubmissionDetailNomineeCount(nominees.length)})',
      icon: Icons.group_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in nominees) _NomineeTile(nominee: n),
          if (shareDeclared)
            InfoRow(
              label: loc.adminSubmissionDetailFieldLabelsPercentage,
              value: loc.adminSubmissionDetailShareTotal(shareTotal),
            ),
          if (shareDeclared && shareTotal.round() != 100)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ManagementCallout(
                message: loc.adminSubmissionDetailShareWarning(shareTotal),
                icon: Icons.warning_amber_rounded,
                error: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _NomineeTile extends StatelessWidget {
  const _NomineeTile({required this.nominee});

  final Nominee nominee;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final n = nominee;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ManagementAvatar(name: n.name, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                InfoRow(
                    label: loc.adminSubmissionDetailFieldsRelation,
                    value: n.relation),
                InfoRow(
                    label: loc.adminSubmissionDetailFieldsMobile,
                    value: n.mobile),
              ],
            ),
          ),
          if (n.sharePercentage != null)
            StatusBadge(
              kind: StatusKind.neutral,
              label: '${n.sharePercentage}%',
            ),
        ],
      ),
    );
  }
}

/// Page gutter + width cap for detail-page section columns.
class DetailSectionsPadding extends StatelessWidget {
  const DetailSectionsPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
      child: child,
    );
  }
}
