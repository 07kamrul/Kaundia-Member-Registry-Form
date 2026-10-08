import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/dashboard/data/dto/public_stats_dto.dart';
import 'package:kaundia_app/features/dashboard/domain/entity/public_stats.dart';

void main() {
  group('PublicStatsDto.fromJson', () {
    // Raw snake_case literal — asserts every field name spelling.
    test('parses every snake_case field', () {
      final dto = PublicStatsDto.fromJson(const {
        'pending_count': 7,
        'approved_count': 42,
        'monthly_subscription_total': 12345,
      });
      expect(dto.pendingCount, 7);
      expect(dto.approvedCount, 42);
      expect(dto.monthlySubscriptionTotal, 12345);
    });

    test('mapper produces a camelCase entity with identical values', () {
      const dto = PublicStatsDto(
        pendingCount: 1,
        approvedCount: 2,
        monthlySubscriptionTotal: 3,
      );
      final PublicStats entity = dto.toEntity();
      expect(entity.pendingCount, 1);
      expect(entity.approvedCount, 2);
      expect(entity.monthlySubscriptionTotal, 3);
      expect(entity.props, [1, 2, 3]);
    });

    test('round-trips through toJson', () {
      const raw = <String, dynamic>{
        'pending_count': 7,
        'approved_count': 42,
        'monthly_subscription_total': 12345,
      };
      expect(PublicStatsDto.fromJson(raw).toJson(), raw);
    });
  });
}
