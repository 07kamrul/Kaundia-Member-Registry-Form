import '../domain/content_entities.dart';

/// API DTOs mirroring the backend JSON exactly (snake_case, numeric ids),
/// mirroring Angular `content.model.ts` API models. Mappers to entities are
/// hand-written and tested field-for-field.
class NoticeDto {
  const NoticeDto({
    required this.id,
    required this.title,
    required this.body,
    required this.categoryId,
    required this.isPublished,
    required this.isMembersOnly,
    required this.publishAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoticeDto.fromJson(Map<String, dynamic> json) => NoticeDto(
        id: json['id'],
        title: json['title'] as String,
        body: json['body'] as String,
        categoryId: json['category_id'],
        isPublished: json['is_published'] == true || json['is_published'] == 1,
        isMembersOnly: json['is_members_only'] == true || json['is_members_only'] == 1,
        publishAt: json['publish_at'] as String?,
        createdBy: json['created_by'],
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  final dynamic id;
  final String title;
  final String body;
  final dynamic categoryId;
  final bool isPublished;
  final bool isMembersOnly;
  final String? publishAt;
  final dynamic createdBy;
  final String createdAt;
  final String updatedAt;
}

class EventDto {
  const EventDto({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.categoryId,
    required this.startAt,
    required this.endAt,
    required this.isPublished,
    required this.isMembersOnly,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) => EventDto(
        id: json['id'],
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        categoryId: json['category_id'],
        startAt: json['start_at'] as String,
        endAt: json['end_at'] as String?,
        isPublished: json['is_published'] == true || json['is_published'] == 1,
        isMembersOnly: json['is_members_only'] == true || json['is_members_only'] == 1,
        createdBy: json['created_by'],
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  final dynamic id;
  final String title;
  final String? description;
  final String? location;
  final dynamic categoryId;
  final String startAt;
  final String? endAt;
  final bool isPublished;
  final bool isMembersOnly;
  final dynamic createdBy;
  final String createdAt;
  final String updatedAt;
}

extension NoticeDtoX on NoticeDto {
  Notice toEntity() => Notice(
        id: id.toString(),
        title: title,
        body: body,
        categoryId: categoryId?.toString(),
        isPublished: isPublished,
        isMembersOnly: isMembersOnly,
        publishAt: publishAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension EventDtoX on EventDto {
  EventItem toEntity() => EventItem(
        id: id.toString(),
        title: title,
        description: description,
        location: location,
        categoryId: categoryId?.toString(),
        startAt: startAt,
        endAt: endAt,
        isPublished: isPublished,
        isMembersOnly: isMembersOnly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
