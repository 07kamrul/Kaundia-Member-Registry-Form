import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../domain/geo.dart';
import '../../../domain/land_entities.dart';
import '../../widgets/owner_bottom_sheet.dart' show formatDigits;
import 'land_layer_style.dart';

/// Permanent dag labels, only when zoomed in far enough to read them and only
/// for plots in view — the full mouza holds thousands of plots and one marker
/// per plot would freeze the map.
class LandLabelLayer extends StatelessWidget {
  const LandLabelLayer({
    super.key,
    required this.collection,
    this.minZoom = kLandLabelMinZoom,
    this.maxLabels = kLandLabelMax,
  });

  /// Mirrors Angular `BDS_LABEL_MIN_ZOOM`.
  static const double kLandLabelMinZoom = 16;
  static const int kLandLabelMax = 300;

  final LandCollection collection;
  final double minZoom;
  final int maxLabels;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (camera.zoom < minZoom) return const SizedBox.shrink();

    final bounds = camera.visibleBounds;
    final view = SocietyBbox(
      minLng: bounds.west,
      minLat: bounds.south,
      maxLng: bounds.east,
      maxLat: bounds.north,
    ).padded(0.1);

    final markers = <Marker>[];
    for (final plot in collection.plots) {
      if (markers.length >= maxLabels) break;
      final box = plot.bounds;
      final label = plot.displayDag;
      if (box == null || label.isEmpty || !box.intersects(view)) continue;
      markers.add(Marker(
        point: box.center,
        width: 72,
        height: 22,
        child: IgnorePointer(
          child: Center(
            child: Text(
              formatDigits(context, label),
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                color: kDagLabelColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: Colors.white, blurRadius: 3),
                  Shadow(color: Colors.white, blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return MarkerLayer(markers: markers);
  }
}
