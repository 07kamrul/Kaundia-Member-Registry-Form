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

const int _sqmPerHectare = 10000;

/// Info card for a tapped BDS dag or RAJUK RS plot (the Angular popups).
class LandInfoSheet extends StatelessWidget {
  const LandInfoSheet({
    super.key,
    required this.layer,
    required this.plot,
    required this.onStreetView,
  });

  final LandLayer layer;
  final LandPlot plot;
  final void Function(LatLng point) onStreetView;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String digits(String? v) =>
        v == null || v.isEmpty ? '—' : formatDigits(context, v);

    final (title, rows) = switch (layer) {
      LandLayer.bds => (
          loc.plotMapViewsBdsInfoTitle,
          [
            (loc.plotMapViewsDagNoLabel, digits(plot.displayDag)),
            (
              loc.plotMapViewsSurveyTypeLabel,
              loc.plotMapViewsSurveyTypeValue,
            ),
            (
              loc.plotMapViewsMouzaNameLabel,
              loc.plotMapViewsMouzaNameValue,
            ),
            (loc.plotMapViewsSheetNoLabel, digits(plot.sheet)),
            (loc.plotMapViewsAreaLabel, digits(_hectares(plot.areaSqm))),
          ],
        ),
      LandLayer.rajuk => (
          '${loc.plotMapViewsRsPlotNo}: '
              '${digits(plot.rsPlotNo ?? plot.plotNo)}',
          [
            (loc.plotMapViewsRsJlNo, digits(kRajukJlNo)),
            ('', loc.plotMapViewsMouzaLabel),
            ('', loc.plotMapViewsThanaLabel),
          ],
        ),
    };

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
                  layer == LandLayer.bds
                      ? Icons.map_outlined
                      : Icons.description_outlined,
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
            if (layer == LandLayer.bds) ...[
              const SizedBox(height: 12),
              _NoteBox(text: loc.plotMapViewsKhatianNote),
            ],
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

  static String? _hectares(double? areaSqm) => areaSqm != null && areaSqm > 0
      ? (areaSqm / _sqmPerHectare).toStringAsFixed(4)
      : null;
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

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSecondaryContainer,
              ),
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
  required LandLayer layer,
  required LandPlot plot,
  required ExternalLinkLauncher launcher,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => LandInfoSheet(
      layer: layer,
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
