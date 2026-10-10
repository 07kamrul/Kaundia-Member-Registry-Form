import 'package:latlong2/latlong.dart';

import 'dag_number.dart';
import 'geo.dart';

/// Client-side validation verdict shown live in the editor. This mirrors the
/// backend checks so the member gets instant feedback; the server remains the
/// authority (a save can still fail with the same codes).
class BoundaryValidation {
  const BoundaryValidation({
    required this.error,
    required this.areaSqm,
    this.areaMismatch = false,
  });

  /// First blocking problem, if any (drives the localized error message).
  final BoundaryError? error;

  /// Estimated planar area in m². Labelled as an estimate in the UI; the
  /// server computes the geodesic area.
  final double areaSqm;

  /// Warning only (never blocks saving): the drawn area differs a lot from
  /// the declared land quantity.
  final bool areaMismatch;

  double get areaShotangsho => sqmToShotangsho(areaSqm);

  bool get canSave => error == null;

  static const int maxVertices = 200;

  /// Areas differing by more than this fraction trigger the warning.
  static const double areaMismatchTolerance = 0.35;
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
  double? declaredShotangsho,
}) {
  final error = validateVertices(vertices, bbox: bbox);
  final area = error == BoundaryError.tooFewPoints
      ? 0.0
      : estimateAreaSqm(vertices);
  final drawn = sqmToShotangsho(area);
  final mismatch = declaredShotangsho != null &&
      declaredShotangsho > 0 &&
      area > 0 &&
      (drawn - declaredShotangsho).abs() / declaredShotangsho >
          BoundaryValidation.areaMismatchTolerance;
  return BoundaryValidation(
    error: error,
    areaSqm: area,
    areaMismatch: mismatch,
  );
}

/// Declared land quantity is free text ("5", "৫", "3/1" shares...) — only a
/// clean numeric shotangsho value takes part in the area check.
double? parseDeclaredShotangsho(String? quantity) {
  if (quantity == null) return null;
  final ascii = toAsciiDigits(quantity).trim();
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(ascii)) return null;
  return double.tryParse(ascii);
}

List<LatLng> _open(List<LatLng> points) {
  if (points.length > 1 && points.first == points.last) {
    return points.sublist(0, points.length - 1);
  }
  return points;
}
