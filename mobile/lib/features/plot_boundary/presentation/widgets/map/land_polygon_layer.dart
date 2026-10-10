import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../domain/land_entities.dart';
import 'land_layer_style.dart';

/// Draws a BDS / RAJUK collection. The (potentially thousands of) polygons
/// are rebuilt only when the collection, layer or highlighted dag changes,
/// not on every camera frame.
class LandPolygonLayer extends StatefulWidget {
  const LandPolygonLayer({
    super.key,
    required this.layer,
    required this.collection,
    this.highlightDag,
  });

  final LandLayer layer;
  final LandCollection collection;
  final String? highlightDag;

  @override
  State<LandPolygonLayer> createState() => _LandPolygonLayerState();
}

class _LandPolygonLayerState extends State<LandPolygonLayer> {
  late List<Polygon> _polygons = _build();

  @override
  void didUpdateWidget(LandPolygonLayer old) {
    super.didUpdateWidget(old);
    final changed = !identical(old.collection, widget.collection) ||
        old.layer != widget.layer ||
        old.highlightDag != widget.highlightDag;
    if (changed) _polygons = _build();
  }

  List<Polygon> _build() {
    final base = LandLayerStyle.of(widget.layer);
    final highlight = widget.highlightDag;
    final normal = <Polygon>[];
    final hits = <Polygon>[];
    for (final plot in widget.collection.plots) {
      final isHit =
          highlight != null && highlight.isNotEmpty && plot.dagKey == highlight;
      final style = isHit ? LandLayerStyle.highlight : base;
      for (final ring in plot.rings) {
        (isHit ? hits : normal).add(Polygon(
          points: ring,
          color: style.fill,
          borderColor: style.stroke,
          borderStrokeWidth: style.strokeWidth,
        ));
      }
    }
    // Highlighted plots are drawn last so they sit on top.
    return [...normal, ...hits];
  }

  @override
  Widget build(BuildContext context) => PolygonLayer(polygons: _polygons);
}
