import '../../../core/network/api_client.dart';
import '../domain/neighbour_entities.dart';
import '../domain/neighbour_mappers.dart';
import '../domain/neighbours_repository.dart';
import 'neighbour_dtos.dart';

class NeighboursRepositoryImpl implements NeighboursRepository {
  NeighboursRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<NeighbourDirectory> getNeighbours({DagType? dagType}) async {
    final data = await _api.getUri(
      '/member/neighbours',
      query: dagType == null ? null : {'dag_type': dagType.apiName},
    );
    if (data is! Map) {
      throw const FormatException('Unexpected /member/neighbours payload');
    }
    return NeighbourDirectoryDto.fromJson(data).toEntity(requested: dagType);
  }
}
