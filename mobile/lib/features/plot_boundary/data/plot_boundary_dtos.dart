// DTOs for the /member/plot-* endpoints — snake_case on the wire. Parsing is
// tolerant, matching the neighbours feature style: missing scalars become
// null / empty, numbers accept int | double | numeric String.

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

double? _double(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _dateTime(dynamic v) {
  final s = _str(v);
  if (s == null) return null;
  return DateTime.tryParse(s)?.toLocal();
}

List<Map<dynamic, dynamic>> _maps(dynamic v) => v is List
    ? [
        for (final e in v)
          if (e is Map) e
      ]
    : const [];

List<String> _strings(dynamic v) => v is List
    ? [
        for (final e in v)
          if (e != null) e.toString()
      ]
    : const [];

/// `geometry` block of a GeoJSON polygon feature (or the full feature when
/// `geometry` is absent — the mine endpoint returns `geometry` inline).
class PolygonGeometryDto {
  const PolygonGeometryDto(this.coordinates);

  /// First ring of the polygon: `[[lng, lat], ...]`.
  final List<dynamic> coordinates;

  static PolygonGeometryDto? fromJson(dynamic json) {
    if (json is! Map) return null;
    final coords = json['coordinates'];
    if (coords is List && coords.isNotEmpty && coords.first is List) {
      return PolygonGeometryDto(coords.first as List);
    }
    return null;
  }
}

/// One feature of GET /member/plot-map.
class MapFeatureDto {
  const MapFeatureDto({
    required this.boundaryId,
    required this.propertyId,
    required this.status,
    required this.isMine,
    required this.geometry,
    this.rsDag,
    this.csDag,
  });

  factory MapFeatureDto.fromJson(Map<dynamic, dynamic> json) => MapFeatureDto(
        boundaryId: _str(json['boundary_id']) ?? '',
        propertyId: _str(json['property_id']) ?? '',
        status: _str(json['review_status'] ?? json['status']),
        isMine: json['is_mine'] == true,
        rsDag: _str(json['rs_dag']),
        csDag: _str(json['cs_dag']),
        geometry: PolygonGeometryDto.fromJson(
            json['geometry'] is Map ? json['geometry'] : json),
      );

  final String boundaryId;
  final String propertyId;
  final String? status;
  final bool isMine;
  final String? rsDag;
  final String? csDag;
  final PolygonGeometryDto? geometry;
}

class PlotMapResponseDto {
  const PlotMapResponseDto({
    required this.disclaimerEn,
    required this.disclaimerBn,
    required this.count,
    required this.features,
  });

  factory PlotMapResponseDto.fromJson(Map<dynamic, dynamic> json) =>
      PlotMapResponseDto(
        disclaimerEn: _str(json['disclaimer_en']),
        disclaimerBn: _str(json['disclaimer_bn']),
        count: _int(json['count']) ?? 0,
        features: [
          for (final m in _maps(json['features'])) MapFeatureDto.fromJson(m)
        ],
      );

  final String? disclaimerEn;
  final String? disclaimerBn;
  final int count;
  final List<MapFeatureDto> features;
}

/// GET /member/plot-map/{id}/owner.
class BoundaryOwnerDto {
  const BoundaryOwnerDto({
    required this.boundaryId,
    required this.ownerName,
    required this.mobile,
    required this.contactHidden,
    required this.status,
    this.rsDag,
    this.csDag,
    this.landQuantity,
    this.areaSqm,
    this.areaShotangsho,
  });

  factory BoundaryOwnerDto.fromJson(Map<dynamic, dynamic> json) =>
      BoundaryOwnerDto(
        boundaryId: _str(json['boundary_id']) ?? '',
        ownerName: _str(json['owner_name']) ?? '',
        mobile: _str(json['mobile']),
        contactHidden: json['contact_hidden'] == true,
        status: _str(json['review_status'] ?? json['status']),
        rsDag: _str(json['rs_dag']),
        csDag: _str(json['cs_dag']),
        landQuantity: _str(json['land_quantity']),
        areaSqm: _double(json['computed_area_sqm']),
        areaShotangsho: _double(json['computed_area_shotangsho']),
      );

  final String boundaryId;
  final String ownerName;
  final String? mobile;
  final bool contactHidden;
  final String? status;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;
  final double? areaSqm;
  final double? areaShotangsho;
}

/// GET /member/plot-boundaries/mine (and POST / PUT responses).
class MyBoundaryDto {
  const MyBoundaryDto({
    required this.id,
    required this.propertyId,
    required this.status,
    required this.geometry,
    required this.isMine,
    this.areaSqm,
    this.areaShotangsho,
    this.currentVersion,
    this.reviewNote,
    this.hasPending = false,
    this.liveStatus,
    this.rsDag,
    this.csDag,
    this.landQuantity,
    this.warnings = const [],
  });

  factory MyBoundaryDto.fromJson(Map<dynamic, dynamic> json) => MyBoundaryDto(
        id: _str(json['id']) ?? _str(json['boundary_id']) ?? '',
        propertyId: _str(json['property_id']) ?? '',
        status: _str(json['review_status'] ?? json['status']),
        geometry: PolygonGeometryDto.fromJson(
            json['geometry'] is Map ? json['geometry'] : json),
        isMine: true,
        areaSqm: _double(json['computed_area_sqm']),
        areaShotangsho: _double(json['computed_area_shotangsho']),
        currentVersion: _int(json['current_version']),
        reviewNote: _str(json['review_note']),
        hasPending: json['has_pending'] == true,
        liveStatus: _str(json['live_review_status']),
        rsDag: _str(json['rs_dag']),
        csDag: _str(json['cs_dag']),
        landQuantity: _str(json['land_quantity']),
        warnings: _strings(json['warnings']),
      );

  final String id;
  final String propertyId;
  final bool hasPending;
  final String? liveStatus;
  final String? status;
  final PolygonGeometryDto? geometry;
  final bool isMine;
  final double? areaSqm;
  final double? areaShotangsho;
  final int? currentVersion;
  final String? reviewNote;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;
  final List<String> warnings;
}

/// GET /member/plot-boundaries/{id}/versions.
class BoundaryVersionDto {
  const BoundaryVersionDto({
    required this.id,
    required this.version,
    required this.status,
    required this.createdAt,
    this.geometry,
    this.areaSqm,
    this.changeType,
    this.note,
  });

  factory BoundaryVersionDto.fromJson(Map<dynamic, dynamic> json) =>
      BoundaryVersionDto(
        id: _str(json['id']) ?? '',
        version: _int(json['version']) ?? 0,
        status: _str(json['review_status'] ?? json['status']),
        createdAt: _dateTime(json['created_at']),
        geometry: PolygonGeometryDto.fromJson(
            json['geometry'] is Map ? json['geometry'] : json),
        areaSqm: _double(json['computed_area_sqm']),
        changeType: _str(json['change_type']),
        note: _str(json['note']),
      );

  final String id;
  final int version;
  final String? status;
  final DateTime? createdAt;
  final PolygonGeometryDto? geometry;
  final double? areaSqm;
  final String? changeType;
  final String? note;
}

/// POST /member/plot-boundaries/{id}/report -> 202.
class ReportReceiptDto {
  const ReportReceiptDto({required this.received, this.disputeId});

  factory ReportReceiptDto.fromJson(Map<dynamic, dynamic> json) =>
      ReportReceiptDto(
        received: json['received'] == true,
        disputeId: _str(json['dispute_id']),
      );

  final bool received;
  final String? disputeId;
}

/// Reuse of the neighbours `own` plot shape for the property picker.
class OwnPropertyDto {
  const OwnPropertyDto({
    required this.propertyId,
    this.rsDag,
    this.csDag,
    this.landQuantity,
  });

  factory OwnPropertyDto.fromJson(Map<dynamic, dynamic> json) => OwnPropertyDto(
        propertyId: _str(json['property_id']) ?? '',
        rsDag: _str(json['rs_dag']),
        csDag: _str(json['cs_dag']),
        landQuantity: _str(json['land_quantity']),
      );

  final String propertyId;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;
}
