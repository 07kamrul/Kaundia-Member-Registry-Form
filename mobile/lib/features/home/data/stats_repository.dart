import '../../../core/network/api_client.dart';

/// Public landing stats, mirroring Angular `public-stats.service.ts`:
/// GET /public/stats -> { pending_count, approved_count,
/// monthly_subscription_total }.
class PublicStats {
  const PublicStats({
    required this.pendingCount,
    required this.approvedCount,
    required this.monthlySubscriptionTotal,
  });

  final int pendingCount;
  final int approvedCount;
  final int monthlySubscriptionTotal;
}

class StatsRepository {
  StatsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<PublicStats> getStats() async {
    final json =
        Map<String, dynamic>.from(await _api.getUri('/public/stats') as Map);
    return PublicStats(
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      approvedCount: (json['approved_count'] as num?)?.toInt() ?? 0,
      monthlySubscriptionTotal: (json['monthly_subscription_total'] as num?)?.toInt() ?? 0,
    );
  }
}
