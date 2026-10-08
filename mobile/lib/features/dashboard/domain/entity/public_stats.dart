import 'package:equatable/equatable.dart';

import '../../../../core/enums/enums.dart';
import '../../data/dto/public_stats_dto.dart';

/// Public landing stats (camelCase entity; mirrors Angular PublicStats).
class PublicStats extends Equatable {
  const PublicStats({
    required this.pendingCount,
    required this.approvedCount,
    required this.monthlySubscriptionTotal,
  });

  final int pendingCount;
  final int approvedCount;
  final int monthlySubscriptionTotal;

  @override
  List<Object?> get props => [pendingCount, approvedCount, monthlySubscriptionTotal];
}

/// Hand-written mapper DTO → entity. Asserted field-for-field in tests
/// (snake_case ↔ camelCase is exactly where the historical Angular bug lived).
extension PublicStatsDtoX on PublicStatsDto {
  PublicStats toEntity() => PublicStats(
        pendingCount: pendingCount,
        approvedCount: approvedCount,
        monthlySubscriptionTotal: monthlySubscriptionTotal,
      );
}

/// The member's own submission status shown on the dashboard.
class OwnStatus extends Equatable {
  const OwnStatus({required this.status, this.referenceId, this.rejectionReason});

  final SubmissionStatus status;
  final String? referenceId;
  final String? rejectionReason;

  @override
  List<Object?> get props => [status, referenceId, rejectionReason];
}
