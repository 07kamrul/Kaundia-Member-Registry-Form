/// Domain entities for the council's published content (notices & events),
/// mirroring Angular `content.model.ts` view models (string ids, booleans).
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.categoryId,
    required this.isPublished,
    required this.isMembersOnly,
    required this.publishAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final String? categoryId;
  final bool isPublished;
  final bool isMembersOnly;
  final String? publishAt;
  final String createdAt;
  final String updatedAt;
}

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.categoryId,
    required this.startAt,
    required this.endAt,
    required this.isPublished,
    required this.isMembersOnly,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? categoryId;
  final String startAt;
  final String? endAt;
  final bool isPublished;
  final bool isMembersOnly;
  final String createdAt;
  final String updatedAt;
}
