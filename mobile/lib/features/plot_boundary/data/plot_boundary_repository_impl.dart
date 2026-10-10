import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';
import 'plot_boundary_dtos.dart';
import '../domain/geo.dart';
import '../domain/plot_boundary_entities.dart';
import '../domain/plot_boundary_mappers.dart';
import '../domain/plot_boundary_repository.dart';

class PlotBoundaryRepositoryImpl implements PlotBoundaryRepository {
  PlotBoundaryRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<List<BoundaryFeature>> getPlotMap(SocietyBbox bbox) async {
    final data = await _api.getUri(
      '/member/plot-map',
      query: {'bbox': bbox.queryValue},
    );
    if (data is! Map) {
      throw const FormatException('Unexpected /member/plot-map payload');
    }
    return PlotMapResponseDto.fromJson(data).toEntities();
  }

  @override
  Future<BoundaryOwner> getOwner(String boundaryId) async {
    final data = await _api.getUri('/member/plot-map/$boundaryId/owner');
    if (data is! Map) {
      throw const FormatException('Unexpected owner payload');
    }
    return BoundaryOwnerDto.fromJson(data).toEntity();
  }

  @override
  Future<List<PlotBoundary>> getMyBoundaries() async {
    final data = await _api.getUri('/member/plot-boundaries/mine');
    if (data is! List) {
      throw const FormatException('Unexpected /mine payload');
    }
    return [
      for (final m in data)
        if (m is Map) MyBoundaryDto.fromJson(m).toEntity(),
    ];
  }

  @override
  Future<PlotBoundary> createBoundary({
    required String propertyId,
    required List<LatLng> points,
  }) async {
    final data = await _api.post('/member/plot-boundaries', {
      'property_id': propertyId,
      'geometry': polygonBody(points),
    });
    return _boundaryFrom(data);
  }

  @override
  Future<PlotBoundary> updateBoundary({
    required String id,
    required List<LatLng> points,
  }) async {
    final data = await _api.put('/member/plot-boundaries/$id', {
      'geometry': polygonBody(points),
    });
    return _boundaryFrom(data);
  }

  @override
  Future<void> withdrawBoundary(String id) async {
    await _api.post('/member/plot-boundaries/$id/withdraw', <String, dynamic>{});
  }

  @override
  Future<List<BoundaryVersion>> getVersions(String boundaryId) async {
    final data =
        await _api.getUri('/member/plot-boundaries/$boundaryId/versions');
    if (data is! List) {
      throw const FormatException('Unexpected versions payload');
    }
    return [
      for (final m in data)
        if (m is Map) BoundaryVersionDto.fromJson(m).toEntity(),
    ];
  }

  @override
  Future<void> reportProblem(String boundaryId, String note) async {
    await _api.post('/member/plot-boundaries/$boundaryId/report', {'note': note});
  }

  @override
  Future<List<OwnProperty>> getMyProperties() async {
    final data = await _api.getUri('/member/neighbours');
    if (data is! Map) {
      throw const FormatException('Unexpected /member/neighbours payload');
    }
    final properties = data['properties'];
    return [
      for (final g in properties is List ? properties : const [])
        if (g is Map && g['own'] is Map)
          OwnPropertyDto.fromJson(g['own'] as Map).toEntity(),
    ];
  }

  PlotBoundary _boundaryFrom(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Unexpected boundary payload');
    }
    return MyBoundaryDto.fromJson(data).toEntity();
  }
}
