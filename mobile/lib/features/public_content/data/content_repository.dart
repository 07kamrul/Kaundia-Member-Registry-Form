import '../../../core/network/api_client.dart';
import 'content_dto.dart';
import '../domain/content_entities.dart';

/// Unauthenticated reads of the published notices/events feed, mirroring
/// Angular `content.service.ts`. Only rows the backend considers public come
/// back; the same endpoints serve logged-out visitors and logged-in members.
class ContentRepository {
  ContentRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Notice>> listNotices() async {
    final rows = await _api.getUri('/public/notices') as List<dynamic>;
    return rows
        .map((row) => NoticeDto.fromJson(row as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<List<EventItem>> listEvents() async {
    final rows = await _api.getUri('/public/events') as List<dynamic>;
    return rows
        .map((row) => EventDto.fromJson(row as Map<String, dynamic>).toEntity())
        .toList();
  }
}
