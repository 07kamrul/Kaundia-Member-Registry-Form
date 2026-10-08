import '../../../core/network/api_client.dart';

/// Active option values for a config-list category (Angular ConfigListService).
/// Falls back to [defaults] when the category is unconfigured ([]) or the API
/// is unreachable; results are cached per category for the session.
class ConfigListRepository {
  ConfigListRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _cache = <String, List<String>>{};

  Future<List<String>> getValues(String category, List<String> defaults) async {
    final cached = _cache[category];
    if (cached != null) return cached;
    try {
      final raw = await _apiClient.getUri('/public/config-lists/$category');
      final values = [
        if (raw is List)
          for (final row in raw)
            if (row is Map && row['value'] != null) row['value'].toString(),
      ];
      final result = values.isEmpty ? defaults : values;
      _cache[category] = result;
      return result;
    } catch (_) {
      // The form must still render without the admin-editable lists.
      return defaults;
    }
  }
}
