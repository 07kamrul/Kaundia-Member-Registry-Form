/// DTO for GET /public/stats — snake_case on the wire (mirrors Angular
/// PublicStatsApiModel in public-stats.service.ts).
class PublicStatsDto {
  const PublicStatsDto({
    required this.pendingCount,
    required this.approvedCount,
    required this.monthlySubscriptionTotal,
  });

  factory PublicStatsDto.fromJson(Map<String, dynamic> json) => PublicStatsDto(
        pendingCount: (json['pending_count'] as num).toInt(),
        approvedCount: (json['approved_count'] as num).toInt(),
        monthlySubscriptionTotal: (json['monthly_subscription_total'] as num).toInt(),
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
