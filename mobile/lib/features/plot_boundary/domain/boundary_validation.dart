import 'package:latlong2/latlong.dart';

import 'geo.dart';

/// Client-side validation verdict shown live in the editor. This mirrors the
/// backend checks so the member gets instant feedback; the server remains the
/// authority (a save can still fail with the same codes).
class BoundaryValidation {
  const BoundaryValidation({
    required this.error,
    required this.areaSqm,
  });

  /// First blocking problem, if any (drives the localized error message).
  final BoundaryError? error;

  /// Estimated planar area in m². Labelled as an estimate in the UI; the
  /// server computes the geodesic area.
  final double areaSqm;

  double get areaShotangsho => sqmToShotangsho(areaSqm);

  bool get canSave => error == null;

  static const int maxVertices = 200;
}

enum BoundaryError {
  tooFewPoints,
  selfIntersecting,
  outsideSociety,
  zeroArea,
  tooManyVertices,
}

BoundaryError? validateVertices(
  List<LatLng> vertices, {
  SocietyBbox? bbox,
  int maxVertices = BoundaryValidation.maxVertices,
}) {
  final ring = _open(vertices);
  if (ring.length > maxVertices) return BoundaryError.tooManyVertices;
  if (ring.length < 3) return BoundaryError.tooFewPoints;
  if (isSelfIntersecting(ring)) return BoundaryError.selfIntersecting;
  if (estimateAreaSqm(ring) < 0.01) return BoundaryError.zeroArea;
  if (bbox != null && !ring.every(bbox.contains)) {
    return BoundaryError.outsideSociety;
  }
  return null;
}

BoundaryValidation validate(
  List<LatLng> vertices, {
  SocietyBbox? bbox,
}) {
  final error = validateVertices(vertices, bbox: bbox);
  final area = error == BoundaryError.tooFewPoints
      ? 0.0
      : estimateAreaSqm(vertices);
  return BoundaryValidation(error: error, areaSqm: area);
}

List<LatLng> _open(List<LatLng> points) {
  if (points.length > 1 && points.first == points.last) {
    return points.sublist(0, points.length - 1);
  }
  return points;
}
