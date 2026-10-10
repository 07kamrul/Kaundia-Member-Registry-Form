import '../data/land_data_dtos.dart';
import 'geo.dart';
import 'land_entities.dart';

/// Outer ring of every polygon part. `Polygon` coordinates are
/// `[ring, hole, ...]`; `MultiPolygon` coordinates are `[polygon, ...]`.
/// Holes are skipped — plots are drawn as solid shapes.
List<List<dynamic>> _outerRings(String type, List<dynamic> coordinates) {
  switch (type) {
    case 'Polygon':
      return coordinates.isNotEmpty && coordinates.first is List
          ? [coordinates.first as List<dynamic>]
          : const [];
    case 'MultiPolygon':
      return [
        for (final polygon in coordinates)
          if (polygon is List && polygon.isNotEmpty && polygon.first is List)
            polygon.first as List<dynamic>,
      ];
    default:
      return const [];
  }
}

extension LandFeatureDtoX on LandFeatureDto {
  /// Null when the feature has no drawable geometry.
  LandPlot? toEntity() {
    final rings = [
      for (final ring in _outerRings(geometryType, coordinates))
        ringToLatLng(ring),
    ].where((r) => r.length >= 3).toList();
    if (rings.isEmpty) return null;
    return LandPlot(
      rings: rings,
      dag: dag,
      labelBn: labelBn,
      sheet: sheet,
      areaSqm: areaSqm,
      plotNo: plotNo,
      rsPlotNo: rsPlotNo,
    );
  }
}

extension LandCollectionDtoX on LandCollectionDto {
  LandCollection toEntity() => LandCollection(
        plots: [
          for (final f in features) ...[
            if (f.toEntity() case final plot?) plot,
          ],
        ],
        truncated: truncated,
      );
}
