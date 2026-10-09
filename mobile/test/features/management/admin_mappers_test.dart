import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/enums/enums.dart';
import 'package:kaundia_app/features/management/domain/admin_mappers.dart';
import 'package:kaundia_app/features/management/domain/admin_entities.dart';

void main() {
  group('SubmissionDetailApiX.toDetailEntity', () {
    test('maps every snake_case field', () {
      final api = {
        'id': 12,
        'member_id': 'KND-0007',
        'status': 'pending',
        'full_name': 'রহিম উদ্দিন',
        'mobile': '01700000000',
        'created_at': '2026-01-02T03:04:05Z',
        'father_or_husband': 'করিম উদ্দিন',
        'mother': 'রহিমা বেগম',
        'dob': '1990-01-01',
        'nationality': 'বাংলাদেশী',
        'occupation': 'কৃষক',
        'nid': '1234567890',
        'gender': 'পুরুষ',
        'email': 'rahim@example.com',
        'permanent_house': 'বাড়ি ১',
        'permanent_road': 'রোড ১',
        'permanent_post_office': 'পোস্ট ১',
        'permanent_upazila': 'উপজেলা ১',
        'permanent_district': 'জেলা ১',
        'permanent_division': 'বিভাগ ১',
        'current_house': 'বাড়ি ২',
        'current_road': 'রোড ২',
        'current_post_office': 'পোস্ট ২',
        'current_upazila': 'উপজেলা ২',
        'current_district': 'জেলা ২',
        'current_division': 'বিভাগ ২',
        'urgent_contact_name': 'জরুরি ব্যক্তি',
        'urgent_contact_relation': 'ভাই',
        'urgent_contact_mobile': '01800000000',
        'urgent_contact_address': 'ঠিকানা',
        'admission_fee': '500',
        'subscription': '100',
        'receipt_no': 'RC-1',
        'payment_method': 'bkash',
        'member_photo_path': 'uploads/photos/member.jpg',
        'member_signature': 'sig',
        'receipt_photo_path': 'uploads/receipts/r.jpg',
        'rejection_reason': null,
        'notification_status': 'sent',
        'properties': [
          {
            'id': 3,
            'property_type': ['জমি'],
            'property_type_other': 'অন্য',
            'khatian_no': 'KH-9',
            'dag_no_cs': 'CS-1',
            'dag_no_rs': 'RS-2',
            'holding_number': 'H-5',
            'land_quantity': '33',
            'my_share_quantity': '11',
            'ownership': 'যৌথ',
            'joint_owner_count': 4,
            'applicable_docs': [
              {
                'id': 8,
                'doc_type': 'খাজনা রশিদ',
                'file_path': 'uploads/docs/kh.pdf'
              },
            ],
          },
        ],
        'nominees': [
          {
            'id': 5,
            'name': 'নমিনি',
            'relation': 'স্ত্রী',
            'mobile': '01900000000',
            'address': 'একই ঠিকানা',
            'share_percentage': 100,
          },
        ],
      };

      final s = Map<String, dynamic>.from(api).toDetailEntity();

      expect(s.id, '12');
      expect(s.status, SubmissionStatus.pending);
      expect(s.fullName, 'রহিম উদ্দিন');
      expect(s.mobile, '01700000000');
      expect(s.createdAt, '2026-01-02T03:04:05Z');
      expect(s.fatherOrHusband, 'করিম উদ্দিন');
      expect(s.mother, 'রহিমা বেগম');
      expect(s.dob, '1990-01-01');
      expect(s.nationality, 'বাংলাদেশী');
      expect(s.occupation, 'কৃষক');
      expect(s.nid, '1234567890');
      expect(s.gender, 'পুরুষ');
      expect(s.email, 'rahim@example.com');
      expect(s.permanentHouse, 'বাড়ি ১');
      expect(s.permanentDivision, 'বিভাগ ১');
      expect(s.currentHouse, 'বাড়ি ২');
      expect(s.currentDivision, 'বিভাগ ২');
      expect(s.urgentContactName, 'জরুরি ব্যক্তি');
      expect(s.urgentContactRelation, 'ভাই');
      expect(s.urgentContactMobile, '01800000000');
      expect(s.urgentContactAddress, 'ঠিকানা');
      expect(s.admissionFee, '500');
      expect(s.subscription, '100');
      expect(s.receiptNo, 'RC-1');
      expect(s.paymentMethod, 'bkash');
      expect(s.memberPhotoUrl, isNotNull);
      expect(s.memberPhotoUrl, contains(encodeURIComponent('photos')));
      expect(s.memberSignature, 'sig');
      expect(s.receiptPhotoUrl, isNotNull);
      expect(s.rejectionReason, isNull);
      expect(s.notificationStatus, 'sent');

      expect(s.properties, hasLength(1));
      final p = s.properties.single;
      expect(p.id, '3');
      expect(p.propertyType, ['জমি']);
      expect(p.propertyTypeOther, 'অন্য');
      expect(p.khatianNo, 'KH-9');
      expect(p.dagNoCs, 'CS-1');
      expect(p.dagNoRs, 'RS-2');
      expect(p.holdingNumber, 'H-5');
      expect(p.landQuantity, '33');
      expect(p.myShareQuantity, '11');
      expect(p.ownership, 'যৌথ');
      expect(p.jointOwnerCount, 4);
      expect(p.applicableDocs, hasLength(1));
      expect(p.applicableDocs.single.id, '8');
      expect(p.applicableDocs.single.docType, 'খাজনা রশিদ');
      expect(p.applicableDocs.single.fileUrl, isNotNull);

      expect(s.nominees, hasLength(1));
      final n = s.nominees.single;
      expect(n.id, '5');
      expect(n.name, 'নমিনি');
      expect(n.relation, 'স্ত্রী');
      expect(n.mobile, '01900000000');
      expect(n.address, 'একই ঠিকানা');
      expect(n.sharePercentage, 100);
    });

    test('handles missing optional fields', () {
      final s = Map<String, dynamic>.from({
        'id': 1,
        'status': 'approved',
        'full_name': 'x',
        'mobile': 'y',
        'created_at': '',
        'father_or_husband': '',
        'mother': '',
        'dob': '',
        'nationality': '',
        'occupation': '',
        'nid': '',
        'gender': '',
        'email': '',
        'admission_fee': '',
        'subscription': '',
        'receipt_no': '',
        'payment_method': '',
        'properties': [],
        'nominees': [],
      }).toDetailEntity();
      expect(s.status, SubmissionStatus.approved);
      expect(s.properties, isEmpty);
      expect(s.nominees, isEmpty);
      expect(s.memberPhotoUrl, isNull);
    });
  });

  group('MemberApiX / MemberProfileApiX', () {
    test('maps member rows', () {
      final m = Map<String, dynamic>.from({
        'id': 4,
        'member_id': 'KND-0004',
        'status': 'approved',
        'full_name': 'মেম্বার',
        'mobile': '01711',
        'email': 'm@example.com',
        'due_installments': 2,
      }).toMemberEntity();
      expect(m.id, '4');
      expect(m.memberId, 'KND-0004');
      expect(m.status, SubmissionStatus.approved);
      expect(m.fullName, 'মেম্বার');
      expect(m.mobile, '01711');
      expect(m.email, 'm@example.com');
      expect(m.dueInstallments, 2);
    });

    test('maps member profile with fee summary, installments, picnic, audit',
        () {
      final base = <String, dynamic>{
        'id': 9,
        'member_id': 'KND-0009',
        'status': 'approved',
        'full_name': 'প্রোফাইল',
        'mobile': '01722',
        'created_at': '2026-02-02T00:00:00Z',
        'father_or_husband': 'f',
        'mother': 'm',
        'dob': 'd',
        'nationality': 'n',
        'occupation': 'o',
        'nid': 'nid',
        'gender': 'g',
        'email': 'e',
        'admission_fee': '1',
        'subscription': '2',
        'receipt_no': 'r',
        'payment_method': 'cash',
        'properties': [],
        'nominees': [],
        'updated_at': '2026-03-01T00:00:00Z',
        'reviewed_at': '2026-02-03T00:00:00Z',
        'reviewed_by_name': 'রিভিউয়ার',
        'fee_summary': {
          'due_count': 1,
          'paid_count': 5,
          'due_total': 100,
          'paid_total': 500,
        },
        'installments': [
          {
            'id': 21,
            'year': 2026,
            'month': 1,
            'amount': 100,
            'status': 'paid',
            'paid_at': '2026-01-31'
          },
        ],
        'picnic_payments': [
          {
            'id': 31,
            'total': 250,
            'additional_count': 1,
            'payment_date': '2026-01-10',
            'receipt_no': 'P-1',
            'payment_method': 'cash',
          },
        ],
        'audit_trail': [
          {
            'id': 41,
            'action': 'approve',
            'detail': 'ok',
            'actor_name': 'অ্যাডমিন',
            'created_at': '2026-02-03T00:00:00Z',
          },
        ],
      };
      final p = Map<String, dynamic>.from(base).toProfileEntity();
      expect(p, isA<MemberProfile>());
      expect(p.memberId, 'KND-0009');
      expect(p.updatedAt, '2026-03-01T00:00:00Z');
      expect(p.reviewedAt, '2026-02-03T00:00:00Z');
      expect(p.reviewedByName, 'রিভিউয়ার');
      expect(p.feeSummary.dueCount, 1);
      expect(p.feeSummary.paidCount, 5);
      expect(p.feeSummary.dueTotal, 100);
      expect(p.feeSummary.paidTotal, 500);
      expect(p.installments.single.id, '21');
      expect(p.installments.single.year, 2026);
      expect(p.installments.single.month, 1);
      expect(p.installments.single.amount, 100);
      expect(p.installments.single.status, 'paid');
      expect(p.installments.single.paidAt, '2026-01-31');
      expect(p.picnicPayments.single.total, 250);
      expect(p.picnicPayments.single.additionalCount, 1);
      expect(p.picnicPayments.single.paymentDate, '2026-01-10');
      expect(p.picnicPayments.single.receiptNo, 'P-1');
      expect(p.picnicPayments.single.paymentMethod, 'cash');
      expect(p.auditTrail.single.action, 'approve');
      expect(p.auditTrail.single.actorName, 'অ্যাডমিন');
    });
  });

  group('FeeSetting / ConfigListItem / Notice / Event', () {
    test('fee setting maps is_active via status int', () {
      final active = Map<String, dynamic>.from({
        'id': 1,
        'key': 'admission_fee',
        'value': 500,
        'unit': 'taka',
        'start_date': '2026-01-01',
        'end_date': null,
        'status': 1,
      }).toFeeSettingEntity();
      expect(active.id, '1');
      expect(active.key, 'admission_fee');
      expect(active.value, 500);
      expect(active.unit, 'taka');
      expect(active.startDate, '2026-01-01');
      expect(active.endDate, isNull);
      expect(active.status, 1);
      expect(active.isActive, isTrue);

      final inactive = Map<String, dynamic>.from({
        'id': 2,
        'key': 'admission_fee',
        'value': 400,
        'start_date': '2025-01-01',
        'end_date': '2025-12-31',
        'status': 0,
      }).toFeeSettingEntity();
      expect(inactive.isActive, isFalse);
      expect(inactive.unit, isNull);
      expect(inactive.endDate, '2025-12-31');
    });

    test('config list item maps is_active: 1 to bool', () {
      final item = Map<String, dynamic>.from({
        'id': 7,
        'category': 'property_type',
        'value': 'জমি',
        'label': 'জমি লেবেল',
        'sort_order': 3,
        'is_active': 1,
      }).toConfigItemEntity();
      expect(item.id, '7');
      expect(item.category, 'property_type');
      expect(item.value, 'জমি');
      expect(item.label, 'জমি লেবেল');
      expect(item.sortOrder, 3);
      expect(item.isActive, isTrue);
    });

    test('notice/event map snake_case flags', () {
      final notice = Map<String, dynamic>.from({
        'id': 2,
        'title': 'নোটিশ',
        'body': 'বিস্তারিত',
        'category_id': 3,
        'is_published': true,
        'is_members_only': false,
        'publish_at': '2026-05-01T00:00:00Z',
        'created_at': 'c',
        'updated_at': 'u',
      }).toNoticeEntity();
      expect(notice.id, '2');
      expect(notice.categoryId, '3');
      expect(notice.isPublished, isTrue);
      expect(notice.isMembersOnly, isFalse);
      expect(notice.publishAt, '2026-05-01T00:00:00Z');

      final event = Map<String, dynamic>.from({
        'id': 4,
        'title': 'ইভেন্ট',
        'description': null,
        'location': 'স্থান',
        'category_id': null,
        'start_at': '2026-06-01T00:00:00Z',
        'end_at': null,
        'is_published': false,
        'is_members_only': true,
        'created_at': 'c',
        'updated_at': 'u',
      }).toEventEntity();
      expect(event.id, '4');
      expect(event.categoryId, isNull);
      expect(event.isMembersOnly, isTrue);
      expect(event.isPublished, isFalse);
      expect(event.location, 'স্থান');
    });
  });

  group('PropertyRequestApiX', () {
    test('maps payload with co_owners and docs', () {
      final r = Map<String, dynamic>.from({
        'id': 6,
        'action': 'edit',
        'property_id': 77,
        'payload': {
          'property_type': ['জমি'],
          'property_type_other': null,
          'khatian_no': 'KH-1',
          'dag_no_cs': 'CS',
          'dag_no_rs': 'RS',
          'holding_number': 'H',
          'land_quantity': '10',
          'my_share_quantity': '5',
          'ownership': 'যৌথ',
          'co_owners': [
            {'owner_name': 'মালিক', 'owner_phone': '017'},
          ],
          'docs': [
            {'doc_type': 'দলিল', 'keep_path': 'uploads/docs/d.pdf'},
          ],
        },
        'status': 'pending',
        'cancel_reason': null,
        'reviewed_at': null,
        'created_at': '2026-01-01',
        'member_name': 'সদস্য',
        'member_code': 'KND-1',
      }).toPropertyRequestEntity();

      expect(r.id, 6);
      expect(r.action, PropertyRequestAction.edit);
      expect(r.propertyId, 77);
      expect(r.status, PropertyRequestStatus.pending);
      expect(r.payload.propertyType, ['জমি']);
      expect(r.payload.khatianNo, 'KH-1');
      expect(r.payload.ownership, 'যৌথ');
      expect(r.payload.coOwners.single.ownerName, 'মালিক');
      expect(r.payload.coOwners.single.ownerPhone, '017');
      expect(r.payload.docs.single.docType, 'দলিল');
      expect(r.payload.docs.single.keepPath, 'uploads/docs/d.pdf');
      expect(r.memberName, 'সদস্য');
      expect(r.memberCode, 'KND-1');
    });
  });

  group('PicnicPaymentsPageApiX', () {
    test('maps page totals and items', () {
      final page = Map<String, dynamic>.from({
        'items': [
          {
            'id': 1,
            'member_id': 3,
            'member_name': 'মেম্বার',
            'head_price': 100,
            'additional_price': 50,
            'additional_count': 2,
            'total': 200,
            'payment_date': '2026-01-05',
            'receipt_no': 'R',
            'payment_method': 'cash',
          },
        ],
        'total_collected': 200,
        'count': 1,
      }).toPicnicPageEntity();
      expect(page.totalCollected, 200);
      expect(page.count, 1);
      expect(page.items.single.memberId, 3);
      expect(page.items.single.headPrice, 100);
      expect(page.items.single.total, 200);
      expect(page.items.single.receiptNo, 'R');
    });
  });
}

String encodeURIComponent(String segment) => Uri.encodeComponent(segment);
