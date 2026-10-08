import '../../../core/network/api_client.dart';
import '../domain/registration_form.dart';

/// Backend-quoted চাঁদা breakdown (registration.model.ts SubscriptionQuote).
class SubscriptionQuote {
  const SubscriptionQuote({
    required this.base,
    required this.extraUnits,
    required this.extraRate,
    required this.extraAmount,
    required this.total,
    required this.unit,
    this.rateVersionEffectiveFrom,
  });

  final double base;
  final int extraUnits;
  final double extraRate;
  final double extraAmount;
  final double total;
  final String unit;
  final String? rateVersionEffectiveFrom;

  factory SubscriptionQuote.fromApi(Map<dynamic, dynamic> m) => SubscriptionQuote(
        base: _num(m['base']),
        extraUnits: (m['extra_units'] as num?)?.toInt() ?? 0,
        extraRate: _num(m['extra_rate']),
        extraAmount: _num(m['extra_amount']),
        total: _num(m['total']),
        unit: (m['unit'] ?? '').toString(),
        rateVersionEffectiveFrom: m['rate_version_effective_from']?.toString(),
      );

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;
}

/// Public fee endpoints: the admission fee is a system-defined amount from the
/// active fee settings, and the subscription is always backend-quoted.
class FeeRepository {
  FeeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Returns the 'admission_fee' value, or null when missing/unconfigured.
  Future<double?> getAdmissionFee() async {
    final raw = await _apiClient.getUri('/public/fee-settings');
    if (raw is Map) {
      final v = raw['admission_fee'];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
    }
    return null;
  }

  Future<SubscriptionQuote> getSubscriptionQuote(double landSizeDecimal) async {
    final raw = await _apiClient.post(
      '/public/registration/subscription-quote',
      {'land_size_decimal': landSizeDecimal},
    );
    return SubscriptionQuote.fromApi(raw as Map);
  }
}
