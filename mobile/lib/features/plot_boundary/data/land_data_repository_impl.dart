import '../../../core/network/api_client.dart';
import '../domain/geo.dart';
import '../domain/land_data_repository.dart';
import '../domain/land_entities.dart';
import '../domain/land_mappers.dart';
import 'land_data_dtos.dart';

class LandDataRepositoryImpl implements LandDataRepository {
  LandDataRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<LandCollection> plotsInBbox(LandLayer layer, SocietyBbox bbox) async {
    final path = switch (layer) {
      LandLayer.bds => '/land/dags',
      LandLayer.rajuk => '/land/masterplan',
    };
    return _collection(
      await _api.getUri(path, query: {'bbox': bbox.queryValue}),
    );
  }

  @override
  Future<LandCollection> lookup(LandLayer layer, String dagNo) async {
    final encoded = Uri.encodeComponent(dagNo);
    final path = switch (layer) {
      LandLayer.bds => '/land/dag/bds/lookup/$encoded',
      LandLayer.rajuk => '/land/masterplan/lookup/$encoded',
    };
    return _collection(await _api.getUri(path));
  }

  LandCollection _collection(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Unexpected /land payload');
    }
    return LandCollectionDto.fromJson(data).toEntity();
  }
}
