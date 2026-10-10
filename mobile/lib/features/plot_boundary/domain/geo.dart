import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Central GeoJSON <-> LatLng conversion and client-side geometry checks.
///
/// RFC 7946 positions are [longitude, latitude]; LatLng is (latitude,
/// longitude). Every conversion in the feature MUST go through [ringToLatLng]
/// / [latLngToRing] so the axis order bug cannot appear anywhere else.

/// `[[lng, lat], ...]` -> `LatLng(lat, lng)`. Non-finite / malformed
/// positions are skipped; the ring is NOT auto-closed.
List<LatLng> ringToLatLng(List<dynamic> ring) => [
      for (final pos in ring)
        if (pos is List && pos.length >= 2)
          if (_isFiniteNum(pos[0]) && _isFiniteNum(pos[1]))
            LatLng((pos[1] as num).toDouble(), (pos[0] as num).toDouble()),
    ];

/// `LatLng(lat, lng)` -> `[[lng, lat], ...]`, ring closed (first == last).
List<List<double>> latLngToRing(List<LatLng> points) {
  if (points.isEmpty) return const [];
  final open = _dropClosingPoint(points);
  return [
    for (final p in open) [p.longitude, p.latitude],
    [open.first.longitude, open.first.latitude],
  ];
}

/// Bounding box `minLng,minLat,maxLng,maxLat` parsed from config / query.
class SocietyBbox {
  const SocietyBbox({
    required this.minLng,
    required this.minLat,
    required this.maxLng,
    required this.maxLat,
  });

  factory SocietyBbox.parse(String raw) {
    final parts = raw.split(',').map((s) => double.tryParse(s.trim())).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) {
      throw const FormatException('Invalid SOCIETY_BBOX');
    }
    return SocietyBbox(
      minLng: parts[0]!,
      minLat: parts[1]!,
      maxLng: parts[2]!,
      maxLat: parts[3]!,
    );
  }

  /// Null when [raw] is empty or malformed.
  static SocietyBbox? tryParse(String raw) {
    if (raw.isEmpty) return null;
    try {
      return SocietyBbox.parse(raw);
    } on FormatException {
      return null;
    }
  }

  final double minLng;
  final double minLat;
  final double maxLng;
  final double maxLat;

  /// Smallest box around [points]; null for an empty list.
  static SocietyBbox? around(Iterable<LatLng> points) {
    var minLat = double.infinity;
    var minLng = double.infinity;
    var maxLat = -double.infinity;
    var maxLng = -double.infinity;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    if (minLat > maxLat || minLng > maxLng) return null;
    return SocietyBbox(
      minLng: minLng,
      minLat: minLat,
      maxLng: maxLng,
      maxLat: maxLat,
    );
  }

  String get queryValue => '$minLng,$minLat,$maxLng,$maxLat';

  LatLng get center => LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

  /// Grows every side by [degrees] (fixed tolerance, e.g. ~400 m = 0.004).
  SocietyBbox inflated(double degrees) => SocietyBbox(
        minLng: minLng - degrees,
        minLat: minLat - degrees,
        maxLng: maxLng + degrees,
        maxLat: maxLat + degrees,
      );

  /// Grows every side by [ratio] of the box size (Leaflet `pad`).
  SocietyBbox padded(double ratio) {
    final dLng = (maxLng - minLng) * ratio;
    final dLat = (maxLat - minLat) * ratio;
    return SocietyBbox(
      minLng: minLng - dLng,
      minLat: minLat - dLat,
      maxLng: maxLng + dLng,
      maxLat: maxLat + dLat,
    );
  }

  /// True when [other] lies entirely inside this box.
  bool containsBox(SocietyBbox other) =>
      other.minLat >= minLat &&
      other.maxLat <= maxLat &&
      other.minLng >= minLng &&
      other.maxLng <= maxLng;

  bool intersects(SocietyBbox other) =>
      other.minLat <= maxLat &&
      other.maxLat >= minLat &&
      other.minLng <= maxLng &&
      other.maxLng >= minLng;

  bool contains(LatLng p) =>
      p.latitude >= minLat &&
      p.latitude <= maxLat &&
      p.longitude >= minLng &&
      p.longitude <= maxLng;

  List<LatLng> get corners => [
        LatLng(minLat, minLng),
        LatLng(maxLat, minLng),
        LatLng(maxLat, maxLng),
        LatLng(minLat, maxLng),
      ];

  @override
  bool operator ==(Object other) =>
      other is SocietyBbox &&
      other.minLng == minLng &&
      other.minLat == minLat &&
      other.maxLng == maxLng &&
      other.maxLat == maxLat;

  @override
  int get hashCode => Object.hash(minLng, minLat, maxLng, maxLat);
}

/// Ray-casting point-in-polygon test on a (possibly closed) ring.
bool pointInRing(LatLng point, List<LatLng> ring) {
  final points = _dropClosingPoint(ring);
  var inside = false;
  for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
    final a = points[i];
    final b = points[j];
    final crosses =
        (a.latitude > point.latitude) != (b.latitude > point.latitude);
    if (!crosses) continue;
    final lngAtLat = (b.longitude - a.longitude) *
            (point.latitude - a.latitude) /
            (b.latitude - a.latitude) +
        a.longitude;
    if (point.longitude < lngAtLat) inside = !inside;
  }
  return inside;
}

/// True when the open (or closed — closing point ignored) ring crosses itself.
bool isSelfIntersecting(List<LatLng> points) {
  final ring = _dropClosingPoint(points);
  if (ring.length < 4) return false;
  final n = ring.length;
  for (var i = 0; i < n - 1; i++) {
    final a1 = ring[i];
    final a2 = ring[i + 1];
    for (var j = i + 2; j < n; j++) {
      if (j == n - 1 && i == 0) continue; // closing segment shares vertices
      if (_segmentsCross(a1, a2, ring[j], ring[(j + 1) % n])) return true;
    }
  }
  return false;
}

/// Planar (equirectangular) polygon area in m². Client-side ESTIMATE only —
/// the server computes the authoritative geodesic area.
double estimateAreaSqm(List<LatLng> points) {
  final ring = _dropClosingPoint(points);
  if (ring.length < 3) return 0;
  // Project degrees to metres around the ring's mean latitude (equirectangular).
  final meanLat =
      ring.map((p) => p.latitude).reduce((a, b) => a + b) / ring.length;
  const metresPerDegreeLat = 111319.49;
  final metresPerDegreeLng =
      metresPerDegreeLat * math.cos(meanLat * math.pi / 180.0);
  double x(LatLng p) => p.longitude * metresPerDegreeLng;
  double y(LatLng p) => p.latitude * metresPerDegreeLat;
  var sum = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    sum += x(a) * y(b) - x(b) * y(a);
  }
  return (sum / 2).abs();
}

/// 1 শতাংশ = 435.6 sq ft = 40.47 m² (matches the backend).
const double sqmPerShotangsho = 40.47;

double sqmToShotangsho(double sqm) => sqm / sqmPerShotangsho;

bool _isFiniteNum(dynamic v) => v is num && v.isFinite;

/// Removes a duplicated closing vertex, if present.
List<LatLng> _dropClosingPoint(List<LatLng> points) {
  if (points.length > 1 && points.first == points.last) {
    return points.sublist(0, points.length - 1);
  }
  return points;
}

/// 2D segment crossing test (orientation-based, strict crossing).
bool _segmentsCross(LatLng p1, LatLng p2, LatLng q1, LatLng q2) {
  final d1 = _cross(q1, q2, p1);
  final d2 = _cross(q1, q2, p2);
  final d3 = _cross(p1, p2, q1);
  final d4 = _cross(p1, p2, q2);
  return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
}

double _cross(LatLng o, LatLng a, LatLng b) =>
    (a.longitude - o.longitude) * (b.latitude - o.latitude) -
    (a.latitude - o.latitude) * (b.longitude - o.longitude);
