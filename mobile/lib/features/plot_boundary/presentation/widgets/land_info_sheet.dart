import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/land_entities.dart';
import '../../domain/street_view.dart';
import 'owner_bottom_sheet.dart' show formatDigits;

/// RS journal number printed in the RAJUK popup (mirrors Angular).
const String kRajukJlNo = '245';

/// Info card for a tapped RAJUK RS plot (the Angular popup). BDS dags use
/// the khatian dialog instead (`dag_info_sheet.dart`).
class LandInfoSheet extends StatelessWidget {
  const LandInfoSheet({
    super.key,
    required this.plot,
    required this.onStreetView,
  });

  final LandPlot plot;
  final void Function(LatLng point) onStreetView;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String digits(String? v) =>
        v == null || v.isEmpty ? '—' : formatDigits(context, v);

    final title =
        '${loc.plotMapViewsRsPlotNo}: ${digits(plot.rsPlotNo ?? plot.plotNo)}';
    final rows = [
      (loc.plotMapViewsRsJlNo, digits(kRajukJlNo)),
      ('', loc.plotMapViewsMouzaLabel),
      ('', loc.plotMapViewsThanaLabel),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final (label, value) in rows)
              _InfoRow(label: label, value: value),
            const SizedBox(height: 16),
            AppButton(
              label: loc.plotMapViewsStreetView,
              icon: Icons.streetview_outlined,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: () {
                final center = plot.center;
                if (center != null) onStreetView(center);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: label.isEmpty
          ? Text(value, style: theme.textTheme.bodyMedium)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(label,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Opens [LandInfoSheet] for [plot]; Street View goes through [launcher].
Future<void> showLandInfoSheet(
  BuildContext context, {
  required LandPlot plot,
  required ExternalLinkLauncher launcher,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => LandInfoSheet(
      plot: plot,
      onStreetView: (point) async {
        final opened = await launcher.open(streetViewUri(point));
        if (!opened && sheetContext.mounted) {
          showAppToast(
            sheetContext,
            AppLocalizations.of(sheetContext).plotMapViewsLoadError,
            error: true,
          );
        }
      },
    ),
  );
}
