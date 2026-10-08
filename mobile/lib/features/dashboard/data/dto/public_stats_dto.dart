/// DTO for GET /public/stats — snake_case on the wire (mirrors Angular
/// PublicStatsApiModel in public-stats.service.ts).
class PublicStatsDto {
  const PublicStatsDto({
    required this.pendingCount,
    required this.approvedCount,
    required this.monthlySubscriptionTotal,
  });

  /// Missing/blank keys degrade to 0 — the Angular home card silently shows
  /// placeholders when stats are incomplete.
  factory PublicStatsDto.fromJson(Map<String, dynamic> json) => PublicStatsDto(
        pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
        approvedCount: (json['approved_count'] as num?)?.toInt() ?? 0,
        monthlySubscriptionTotal: (json['monthly_subscription_total'] as num?)?.toInt() ?? 0,
      );

  final int pendingCount;
  final int approvedCount;
  final int monthlySubscriptionTotal;

  Map<String, dynamic> toJson() => {
        'pending_count': pendingCount,
        'approved_count': approvedCount,
        'monthly_subscription_total': monthlySubscriptionTotal,
      };
}
