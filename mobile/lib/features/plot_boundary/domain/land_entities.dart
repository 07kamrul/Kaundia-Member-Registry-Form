import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'dag_number.dart';
import 'geo.dart';

/// Which official dataset a land plot belongs to.
enum LandLayer { bds, rajuk }

/// The three map views of the plot map page.
enum MapMode { boundaries, bds, rajuk }

extension MapModeX on MapMode {
  /// The official layer behind this mode; null for the member boundary view.
  LandLayer? get landLayer => switch (this) {
        MapMode.boundaries => null,
        MapMode.bds => LandLayer.bds,
        MapMode.rajuk => LandLayer.rajuk,
      };
}

/// One plot of the ingested BDS mouza map or the RAJUK DAP masterplan.
class LandPlot extends Equatable {
  LandPlot({
    required this.rings,
    this.dag,
    this.labelBn,
    this.sheet,
    this.areaSqm,
    this.plotNo,
    this.rsPlotNo,
  });

  /// Outer ring of every polygon part (MultiPolygon yields several).
  final List<List<LatLng>> rings;
  final String? dag;
  final String? labelBn;
  final String? sheet;
  final double? areaSqm;
  final String? plotNo;
  final String? rsPlotNo;

  /// Search/highlight key: dag, else RS plot no, else plot no (normalised).
  String get dagKey {
    final value = dag ?? rsPlotNo ?? plotNo;
    return value == null ? '' : normalizeDagNo(value);
  }

  /// Text shown in the BDS info card and as the zoomed-in map label.
  String get displayDag => dag ?? labelBn ?? '';

  /// Computed once: the map reads it for every plot on every camera move.
  late final SocietyBbox? bounds =
      SocietyBbox.around([for (final r in rings) ...r]);

  LatLng? get center => bounds?.center;

  bool containsPoint(LatLng point) {
    final box = bounds;
    if (box == null || !box.contains(point)) return false;
    return rings.any((ring) => pointInRing(point, ring));
  }

  @override
  List<Object?> get props =>
      [rings, dag, labelBn, sheet, areaSqm, plotNo, rsPlotNo];
}

/// A bbox/lookup response; [truncated] means the server capped the result.
class LandCollection extends Equatable {
  const LandCollection({this.plots = const [], this.truncated = false});

  final List<LandPlot> plots;
  final bool truncated;

  bool get isEmpty => plots.isEmpty;

  /// Top-most plot under [point], later plots drawing above earlier ones.
  LandPlot? plotAt(LatLng point) {
    for (final plot in plots.reversed) {
      if (plot.containsPoint(point)) return plot;
    }
    return null;
  }

  @override
  List<Object?> get props => [plots, truncated];
}
