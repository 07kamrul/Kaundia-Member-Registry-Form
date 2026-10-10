import '../data/land_data_dtos.dart';
import 'dag_details_entities.dart';
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

extension DagDetailsDtoX on DagDetailsDto {
  DagDetails toEntity() {
    final land = totalLand;
    final value = land?['value'];
    final unit = land?['unit'];
    return DagDetails(
      survey: survey,
      sheet: sheet,
      dag: dag,
      mouza: MouzaInfo(
        nameBn: _text(mouza['name_bn']),
        nameEn: _text(mouza['name_en']),
        upazilaBn: _text(mouza['upazila_bn']),
        upazilaEn: _text(mouza['upazila_en']),
        districtBn: _text(mouza['district_bn']),
        districtEn: _text(mouza['district_en']),
      ),
      totalLand: value is num && unit is String
          ? TotalLand(value: value.toDouble(), unit: unit)
          : null,
      khatians: [for (final k in khatians) k.toEntity()],
      sourceNote: sourceNote,
      sourceName: sourceName,
      fetchedAt: fetchedAt == null ? null : DateTime.tryParse(fetchedAt!),
    );
  }
}

extension KhatianDtoX on KhatianDto {
  Khatian toEntity() => Khatian(
        khatianNo: khatianNo,
        owners: owners,
        stage: switch (stageCode) {
          'objection' => KhatianStage.objection,
          'appeal' => KhatianStage.appeal,
          _ => KhatianStage.unknown,
        },
        stageBn: stageBn,
      );
}

String? _text(Object? v) {
  if (v is! String) return null;
  final s = v.trim();
  return s.isEmpty ? null : s;
}
