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

/// Raw `GET /land/dag/{survey}/{sheet}/{dag}` payload.
class DagDetailsDto {
  const DagDetailsDto({
    required this.survey,
    required this.sheet,
    required this.dag,
    this.mouza = const {},
    this.totalLand,
    this.khatians = const [],
    this.sourceNote,
    this.sourceName,
    this.fetchedAt,
  });

  factory DagDetailsDto.fromJson(Map<dynamic, dynamic> json) {
    final source = json['source'] is Map ? json['source'] as Map : const {};
    final rawKhatians = json['khatians'];
    return DagDetailsDto(
      survey: _str(json['survey']) ?? '',
      sheet: _str(json['sheet']) ?? '',
      dag: _str(json['dag']) ?? '',
      mouza: json['mouza'] is Map ? json['mouza'] as Map : const {},
      totalLand: json['total_land'] is Map ? json['total_land'] as Map : null,
      khatians: [
        for (final k in rawKhatians is List ? rawKhatians : const [])
          if (k is Map) KhatianDto.fromJson(k),
      ],
      sourceNote: _str(json['source_note']),
      sourceName: _str(source['name']),
      fetchedAt: _str(source['fetched_at']),
    );
  }

  final String survey;
  final String sheet;
  final String dag;
  final Map<dynamic, dynamic> mouza;
  final Map<dynamic, dynamic>? totalLand;
  final List<KhatianDto> khatians;
  final String? sourceNote;
  final String? sourceName;
  final String? fetchedAt;
}

class KhatianDto {
  const KhatianDto({
    required this.khatianNo,
    required this.owners,
    this.stageCode,
    this.stageBn,
  });

  factory KhatianDto.fromJson(Map<dynamic, dynamic> json) {
    final rawOwners = json['owners'];
    return KhatianDto(
      khatianNo: _str(json['khatian_no']) ?? '',
      owners: [
        for (final o in rawOwners is List ? rawOwners : const [])
          if (_str(o) case final name?) name,
      ],
      stageCode: _str(json['stage_code']),
      stageBn: _str(json['stage_bn']),
    );
  }

  final String khatianNo;
  final List<String> owners;
  final String? stageCode;
  final String? stageBn;
}
