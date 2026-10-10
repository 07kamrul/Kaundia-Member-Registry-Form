import 'package:latlong2/latlong.dart';

import 'geo.dart';
import 'plot_boundary_entities.dart';

/// Domain contract for the plot-boundary feature (see docs/plot-boundary-api.md).
abstract class PlotBoundaryRepository {
  /// GET /member/plot-map?bbox= — approved + disputed polygons for everyone,
  /// own polygons of any status. No names/phones here.
  Future<List<BoundaryFeature>> getPlotMap(SocietyBbox bbox);

  /// GET /member/plot-map/{id}/owner — rate-limited on the backend.
  Future<BoundaryOwner> getOwner(String boundaryId);

  /// GET /member/plot-boundaries/mine
  Future<List<PlotBoundary>> getMyBoundaries();

  /// POST /member/plot-boundaries -> 201, status pending_review.
  Future<PlotBoundary> createBoundary({
    required String propertyId,
    required List<LatLng> points,
  });

  /// PUT /member/plot-boundaries/{id} -> back to pending_review, new version.
  Future<PlotBoundary> updateBoundary({
    required String id,
    required List<LatLng> points,
  });

  /// DELETE /member/plot-boundaries/{id} (soft delete, 204).
  Future<void> deleteBoundary(String id);

  /// GET /member/plot-boundaries/{id}/versions
  Future<List<BoundaryVersion>> getVersions(String boundaryId);

  /// POST /member/plot-boundaries/{id}/report -> 202.
  Future<void> reportProblem(String boundaryId, String note);

  /// The member's own plots, for the editor's property picker. Backed by
  /// /member/neighbours (`own` plots), since the API has no dedicated
  /// "list my properties" endpoint.
  Future<List<OwnProperty>> getMyProperties();
}

// ---- Thin use cases so blocs depend on intents, not the data source. ----

class GetPlotMap {
  const GetPlotMap(this._repository);
  final PlotBoundaryRepository _repository;

  Future<List<BoundaryFeature>> call(SocietyBbox bbox) =>
      _repository.getPlotMap(bbox);
}

class GetBoundaryOwner {
  const GetBoundaryOwner(this._repository);
  final PlotBoundaryRepository _repository;

  Future<BoundaryOwner> call(String boundaryId) =>
      _repository.getOwner(boundaryId);
}

class GetMyBoundaries {
  const GetMyBoundaries(this._repository);
  final PlotBoundaryRepository _repository;

  Future<List<PlotBoundary>> call() => _repository.getMyBoundaries();
}

class SaveBoundary {
  const SaveBoundary(this._repository);
  final PlotBoundaryRepository _repository;

  /// Creates when [id] is null, updates otherwise.
  Future<PlotBoundary> call({
    String? id,
    required String propertyId,
    required List<LatLng> points,
  }) =>
      id == null
          ? _repository.createBoundary(propertyId: propertyId, points: points)
          : _repository.updateBoundary(id: id, points: points);
}

class DeleteBoundary {
  const DeleteBoundary(this._repository);
  final PlotBoundaryRepository _repository;

  Future<void> call(String id) => _repository.deleteBoundary(id);
}

class GetBoundaryVersions {
  const GetBoundaryVersions(this._repository);
  final PlotBoundaryRepository _repository;

  Future<List<BoundaryVersion>> call(String id) => _repository.getVersions(id);
}

class ReportBoundaryProblem {
  const ReportBoundaryProblem(this._repository);
  final PlotBoundaryRepository _repository;

  Future<void> call(String id, String note) =>
      _repository.reportProblem(id, note);
}

class GetMyProperties {
  const GetMyProperties(this._repository);
  final PlotBoundaryRepository _repository;

  Future<List<OwnProperty>> call() => _repository.getMyProperties();
}
