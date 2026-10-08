import '../../../core/network/api_client.dart';
import '../domain/roadmap_entities.dart';

String _str(dynamic v) => v?.toString() ?? '';
String? _s(dynamic v) => v == null ? null : v.toString();
int _int(dynamic v) => (v is num) ? v.toInt() : 0;
num _num(dynamic v) => (v is num) ? v : 0;

RoadmapItem _item(Map<dynamic, dynamic> api) => RoadmapItem(
      id: _str(api['id']),
      timeframeId: _str(api['timeframe_id']),
      text: _str(api['text']),
      status: RoadmapStatusX.fromName(_s(api['status'])),
      targetDate: _s(api['target_date']),
      owner: _s(api['owner']),
      note: _s(api['note']),
      sortOrder: _int(api['sort_order']),
      completedAt: _s(api['completed_at']),
      updatedAt: _s(api['updated_at']),
    );

RoadmapProgress _progress(Map<dynamic, dynamic> api) => RoadmapProgress(
      total: _int(api['total']),
      done: _int(api['done']),
      inProgress: _int(api['in_progress']),
      planned: _int(api['planned']),
      percent: _num(api['percent']),
    );

Roadmap roadmapFromApi(Map<dynamic, dynamic> api) => Roadmap(
      lastUpdated: _s(api['last_updated']),
      totals: _progress(api['totals'] as Map<dynamic, dynamic>? ?? const {}),
      timeframes: [
        for (final tf in (api['timeframes'] as List<dynamic>? ?? const []))
          roadmapTimeframeFromApi(tf as Map<dynamic, dynamic>),
      ],
    );

RoadmapTimeframe roadmapTimeframeFromApi(Map<dynamic, dynamic> tf) => RoadmapTimeframe(
      id: _str(tf['id']),
      key: _str(tf['key']),
      nameBn: _str(tf['name_bn']),
      nameEn: _str(tf['name_en']),
      windowBn: _str(tf['target_window_bn']),
      windowEn: _str(tf['target_window_en']),
      sortOrder: _int(tf['sort_order']),
      progress: _progress(tf),
      items: [
        for (final item in (tf['items'] as List<dynamic>? ?? const []))
          _item(item as Map<dynamic, dynamic>),
      ],
    );

/// Public roadmap reads (roadmap.service.ts member half).
class RoadmapRepository {
  RoadmapRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<Roadmap> getRoadmap() async {
    final api = await _api.getUri('/roadmap') as Map<dynamic, dynamic>;
    return roadmapFromApi(api);
  }

  /// Server-rendered A4 handout bytes (GET /roadmap/export.pdf).
  Future<List<int>> downloadPdf() => _api.downloadBytes('/roadmap/export.pdf');
}
