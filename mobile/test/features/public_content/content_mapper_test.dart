import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/public_content/data/content_dto.dart';

void main() {
  group('NoticeDto.fromJson -> toEntity (snake_case mapping)', () {
    test('maps every field, ids to String, is_published 1 -> bool true', () {
      final dto = NoticeDto.fromJson(const {
        'id': 7,
        'title': 'নোটিশ শিরোনাম',
        'body': 'বিস্তারিত বিবরণ',
        'category_id': 3,
        'is_published': 1,
        'is_members_only': 1,
        'publish_at': '2026-01-02T03:04:05Z',
        'created_by': 1,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-03T00:00:00Z',
      });
      final e = dto.toEntity();
      expect(e.id, '7');
      expect(e.title, 'নোটিশ শিরোনাম');
      expect(e.body, 'বিস্তারিত বিবরণ');
      expect(e.categoryId, '3');
      expect(e.isPublished, isTrue);
      expect(e.isMembersOnly, isTrue);
      expect(e.publishAt, '2026-01-02T03:04:05Z');
      expect(e.createdAt, '2026-01-01T00:00:00Z');
      expect(e.updatedAt, '2026-01-03T00:00:00Z');
    });

    test('nulls map to null, false stays false', () {
      final dto = NoticeDto.fromJson(const {
        'id': 9,
        'title': 't',
        'body': 'b',
        'category_id': null,
        'is_published': false,
        'is_members_only': false,
        'publish_at': null,
        'created_by': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      final e = dto.toEntity();
      expect(e.id, '9');
      expect(e.categoryId, isNull);
      expect(e.isPublished, isFalse);
      expect(e.isMembersOnly, isFalse);
      expect(e.publishAt, isNull);
    });
  });

  group('EventDto.fromJson -> toEntity (snake_case mapping)', () {
    test('maps every field incl. start_at/end_at/location', () {
      final dto = EventDto.fromJson(const {
        'id': 12,
        'title': 'বার্ষিক সভা',
        'description': 'সভার বিবরণ',
        'location': 'ক্লাব ঘর',
        'category_id': 2,
        'start_at': '2026-02-01T10:00:00Z',
        'end_at': '2026-02-01T12:00:00Z',
        'is_published': 1,
        'is_members_only': 0,
        'created_by': 1,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-03T00:00:00Z',
      });
      final e = dto.toEntity();
      expect(e.id, '12');
      expect(e.title, 'বার্ষিক সভা');
      expect(e.description, 'সভার বিবরণ');
      expect(e.location, 'ক্লাব ঘর');
      expect(e.categoryId, '2');
      expect(e.startAt, '2026-02-01T10:00:00Z');
      expect(e.endAt, '2026-02-01T12:00:00Z');
      expect(e.isPublished, isTrue);
      expect(e.isMembersOnly, isFalse);
      expect(e.createdAt, '2026-01-01T00:00:00Z');
      expect(e.updatedAt, '2026-01-03T00:00:00Z');
    });

    test('nullable fields map to null', () {
      final dto = EventDto.fromJson(const {
        'id': 13,
        'title': 't',
        'description': null,
        'location': null,
        'category_id': null,
        'start_at': '2026-02-01T10:00:00Z',
        'end_at': null,
        'is_published': true,
        'is_members_only': true,
        'created_by': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      final e = dto.toEntity();
      expect(e.description, isNull);
      expect(e.location, isNull);
      expect(e.categoryId, isNull);
      expect(e.endAt, isNull);
      expect(e.isPublished, isTrue);
      expect(e.isMembersOnly, isTrue);
    });
  });
}
