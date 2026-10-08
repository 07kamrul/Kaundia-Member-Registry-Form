import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/admin_entities.dart';
import 'management_widgets.dart';

/// Pieces of the property-request review card.

String propertyRequestActionLabel(
        AppLocalizations loc, PropertyRequestAction action) =>
    switch (action) {
      PropertyRequestAction.add => loc.adminPropertyRequestsActionsAdd,
      PropertyRequestAction.edit => loc.adminPropertyRequestsActionsEdit,
      PropertyRequestAction.delete => loc.adminPropertyRequestsActionsDelete,
      _ => '—',
    };

List<String> _types(PropertyRequestPayload p) => [
      ...p.propertyType,
      if (p.propertyTypeOther?.isNotEmpty == true) p.propertyTypeOther!,
    ];

/// One-line summary: type / khatian / CS / RS.
String propertyRequestSummary(PropertyRequestPayload p) {
  final types = _types(p);
  return [
    if (types.isNotEmpty) types.join(' / '),
    if (p.khatianNo != null) 'Khatian ${p.khatianNo}',
    if (p.dagNoCs != null) 'CS ${p.dagNoCs}',
    if (p.dagNoRs != null) 'RS ${p.dagNoRs}',
  ].join(' · ');
}

/// Expandable full payload of a property request.
class PropertyRequestPayloadTile extends StatelessWidget {
  const PropertyRequestPayloadTile({super.key, required this.payload});

  final PropertyRequestPayload payload;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = payload;
    final types = _types(p);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(Icons.landscape_outlined, color: theme.colorScheme.primary),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(loc.adminPropertyRequestsTableHeadersProperty,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
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
            expanded: true,
          ),
      ],
    );
  }
}
