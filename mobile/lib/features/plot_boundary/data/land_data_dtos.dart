/// Raw `/land/*` GeoJSON FeatureCollection as served by the backend.
class LandCollectionDto {
  const LandCollectionDto({required this.features, this.truncated = false});

  factory LandCollectionDto.fromJson(Map<dynamic, dynamic> json) {
    final raw = json['features'];
    return LandCollectionDto(
      features: [
        for (final f in raw is List ? raw : const [])
          if (f is Map) LandFeatureDto.fromJson(f),
      ],
      truncated: json['truncated'] == true,
    );
  }

  final List<LandFeatureDto> features;
  final bool truncated;
}

class LandFeatureDto {
  const LandFeatureDto({
    required this.geometryType,
    required this.coordinates,
    this.dag,
    this.labelBn,
    this.sheet,
    this.areaSqm,
    this.plotNo,
    this.rsPlotNo,
  });

  factory LandFeatureDto.fromJson(Map<dynamic, dynamic> json) {
    final props = json['properties'] is Map
        ? json['properties'] as Map<dynamic, dynamic>
        : const <dynamic, dynamic>{};
    final geometry = json['geometry'] is Map
        ? json['geometry'] as Map<dynamic, dynamic>
        : const <dynamic, dynamic>{};
    return LandFeatureDto(
      geometryType:
          geometry['type'] is String ? geometry['type'] as String : '',
      coordinates: geometry['coordinates'] is List
          ? geometry['coordinates'] as List
          : const [],
      dag: _str(props['dag']),
      labelBn: _str(props['label_bn']),
      sheet: _str(props['sheet']),
      areaSqm: props['area_sqm'] is num
          ? (props['area_sqm'] as num).toDouble()
          : null,
      plotNo: _str(props['plot_no']),
      rsPlotNo: _str(props['rs_plot_no']),
    );
  }

  final String geometryType;
  final List<dynamic> coordinates;
  final String? dag;
  final String? labelBn;
  final String? sheet;
  final double? areaSqm;
  final String? plotNo;
  final String? rsPlotNo;
}

String? _str(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
