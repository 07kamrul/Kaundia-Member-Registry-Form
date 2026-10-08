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
    final data = await _api.getUri('/public/stats') as Map<String, dynamic>;
    return PublicStatsDto.fromJson(data).toEntity();
  }
}
