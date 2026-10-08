import '../../../core/network/api_client.dart';
import '../domain/entity/public_stats.dart';
import 'dto/public_stats_dto.dart';

/// Repository contract (domain-facing).
abstract class PublicStatsRepository {
  Future<PublicStats> getStats();
}

class PublicStatsRepositoryImpl implements PublicStatsRepository {
  PublicStatsRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<PublicStats> getStats() async {
    final data = Map<String, dynamic>.from(await _api.getUri('/public/stats') as Map);
    return PublicStatsDto.fromJson(data).toEntity();
  }
}
