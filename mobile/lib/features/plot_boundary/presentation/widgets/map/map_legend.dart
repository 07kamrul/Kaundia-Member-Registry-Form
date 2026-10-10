import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/plot_boundary_entities.dart';
import '../boundary_status_style.dart';

/// Collapsible legend card for the member boundary view (open by default on
/// wide screens, collapsed on phones — mirrors Angular `legendOpen`).
class MapLegend extends StatefulWidget {
  const MapLegend({super.key, this.initiallyOpen});

  /// Overrides the width-based default (tests).
  final bool? initiallyOpen;

  /// Tablet breakpoint at which the legend starts expanded.
  static const double openByDefaultWidth = 768;

  @override
  State<MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<MapLegend> {
  bool? _open;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final open = _open ??
        widget.initiallyOpen ??
        MediaQuery.sizeOf(context).width >= MapLegend.openByDefaultWidth;

    final items = [
      (loc.plotMapStatusApproved, BoundaryStatus.approved, false),
      (loc.plotMapStatusMine, BoundaryStatus.approved, true),
      (loc.plotMapStatusPending, BoundaryStatus.pendingReview, false),
      (loc.plotMapStatusRejected, BoundaryStatus.rejected, false),
      (loc.plotMapStatusDisputed, BoundaryStatus.disputed, false),
    ];

    return Material(
      elevation: 3,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: loc.plotMapLegend,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _open = !open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(loc.plotMapLegend,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(Icons.expand_more, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (label, status, mine) in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Swatch(status: status, isMine: mine),
                          const SizedBox(width: 8),
                          Text(label, style: const TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.status, required this.isMine});

  final BoundaryStatus status;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final (fill, stroke) = BoundaryStatusStyle.colorsFor(
      context,
      status: status,
      isMine: isMine,
    );
    return Container(
      width: 18,
      height: 12,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: stroke, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
