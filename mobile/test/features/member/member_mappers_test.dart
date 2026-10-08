import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/config/app_config.dart';
import 'package:kaundia_app/core/enums/enums.dart';
import 'package:kaundia_app/features/member/data/finance_repository.dart';
import 'package:kaundia_app/features/member/data/member_repository.dart';
import 'package:kaundia_app/features/member/data/payment_repository.dart';
import 'package:kaundia_app/features/member/data/resolution_book_repository.dart';
import 'package:kaundia_app/features/member/data/roadmap_repository.dart';
import 'package:kaundia_app/features/member/domain/finance_entities.dart';
import 'package:kaundia_app/features/member/domain/member_entities.dart';
import 'package:kaundia_app/features/member/domain/payment_entities.dart';
import 'package:kaundia_app/features/member/domain/resolution_book_entities.dart';
import 'package:kaundia_app/features/member/domain/roadmap_entities.dart';

void main() {
  group('memberProfileFromApi (snake_case field-for-field)', () {
    final api = {
      'member_id': 123,
      'status': 'approved',
      'full_name': 'রহিম উদ্দিন',
      'father_or_husband': 'করিম উদ্দিন',
      'mother': 'রহিমা বেগম',
      'dob': '1990-01-02',
      'nationality': 'বাংলাদেশী',
      'nid': '1234567890',
      'gender': 'male',
      'mobile': '+8801712345678',
      'email': 'rahim@example.com',
      'occupation': 'কৃষক',
      'permanent_house': 'বাড়ি ১',
      'permanent_road': 'রাস্তা ২',
      'permanent_post_office': 'ডাকঘর ৩',
      'permanent_upazila': 'উপজেলা ৪',
      'permanent_district': 'জেলা ৫',
      'permanent_division': 'বিভাগ ৬',
      'current_house': 'নতুন বাড়ি',
      'current_road': null,
      'current_post_office': null,
      'current_upazila': null,
      'current_district': null,
      'current_division': null,
      'urgent_contact_name': 'জরুরি',
      'urgent_contact_relation': 'ভাই',
      'urgent_contact_mobile': '+8801898765432',
      'urgent_contact_address': 'ঠিকানা',
      'admission_fee': '1000',
      'subscription': '100',
      'receipt_no': 'RC-9',
      'payment_method': 'Cash',
      'member_signature': null,
      'submission_date': '2026-01-05',
      'member_photo_path': '/uploads/photos/p.jpg',
      'receipt_photo_path': null,
      'properties': [
        {
          'id': 7,
          'property_type': ['land'],
          'property_type_other': 'অন্য',
          'khatian_no': 'KH-1',
          'dag_no_cs': 'CS-10',
          'dag_no_rs': 'RS-20',
          'holding_number': 'HN-30',
          'land_quantity': '1.5',
          'my_share_quantity': '0.5',
          'ownership': 'যৌথ',
          'co_owners': [
            {'id': 11, 'owner_name': 'মালিক ১', 'owner_phone': '+8801700000000'},
          ],
          'applicable_docs': [
            {'id': 21, 'doc_type': 'khatian', 'file_path': '/uploads/docs/k.jpg'},
          ],
        },
      ],
      'nominees': [
        {
          'id': 31,
          'name': 'নমিনি',
          'relation': 'স্ত্রী',
          'mobile': '+8801611111111',
          'address': null,
        },
      ],
    };

    final p = memberProfileFromApi(api);

    test('maps every scalar field', () {
      expect(p.memberId, '123'); // id -> String
      expect(p.status, 'approved');
      expect(p.memberStatus, MemberStatus.approved);
      expect(p.fullName, 'রহিম উদ্দিন');
      expect(p.fatherOrHusband, 'করিম উদ্দিন');
      expect(p.mother, 'রহিমা বেগম');
      expect(p.dob, '1990-01-02');
      expect(p.nationality, 'বাংলাদেশী');
      expect(p.nid, '1234567890');
      expect(p.gender, 'male');
      expect(p.mobile, '+8801712345678');
      expect(p.email, 'rahim@example.com');
      expect(p.occupation, 'কৃষক');
      expect(p.permanentHouse, 'বাড়ি ১');
      expect(p.permanentRoad, 'রাস্তা ২');
      expect(p.permanentPostOffice, 'ডাকঘর ৩');
      expect(p.permanentUpazila, 'উপজেলা ৪');
      expect(p.permanentDistrict, 'জেলা ৫');
      expect(p.permanentDivision, 'বিভাগ ৬');
      expect(p.currentHouse, 'নতুন বাড়ি');
      expect(p.currentRoad, isNull);
      expect(p.currentPostOffice, isNull);
      expect(p.currentUpazila, isNull);
      expect(p.currentDistrict, isNull);
      expect(p.currentDivision, isNull);
      expect(p.urgentContactName, 'জরুরি');
      expect(p.urgentContactRelation, 'ভাই');
      expect(p.urgentContactMobile, '+8801898765432');
      expect(p.urgentContactAddress, 'ঠিকানা');
      expect(p.admissionFee, '1000');
      expect(p.subscription, '100');
      expect(p.receiptNo, 'RC-9');
      expect(p.paymentMethod, 'Cash');
      expect(p.memberSignature, isNull);
      expect(p.submissionDate, '2026-01-05');
    });

    test('maps photo paths through AppConfig.fileUrl', () {
      expect(p.memberPhotoUrl, AppConfig.fileUrl('/uploads/photos/p.jpg'));
      expect(p.receiptPhotoUrl, ''); // null path -> ''
    });

    test('maps properties, co-owners and docs', () {
      expect(p.properties, hasLength(1));
      final property = p.properties.single;
      expect(property.id, '7');
      expect(property.propertyType, ['land']);
      expect(property.propertyTypeOther, 'অন্য');
      expect(property.khatianNo, 'KH-1');
      expect(property.dagNoCs, 'CS-10');
      expect(property.dagNoRs, 'RS-20');
      expect(property.holdingNumber, 'HN-30');
      expect(property.landQuantity, '1.5');
      expect(property.myShareQuantity, '0.5');
      expect(property.ownership, 'যৌথ');
      expect(property.coOwners.single.id, '11');
      expect(property.coOwners.single.ownerName, 'মালিক ১');
      expect(property.coOwners.single.ownerPhone, '+8801700000000');
      final doc = property.applicableDocs.single;
      expect(doc.id, '21');
      expect(doc.docType, 'khatian');
      expect(doc.filePath, '/uploads/docs/k.jpg');
      expect(doc.fileUrl, AppConfig.fileUrl('/uploads/docs/k.jpg'));
    });

    test('maps nominees', () {
      final n = p.nominees.single;
      expect(n.id, '31');
      expect(n.name, 'নমিনি');
      expect(n.relation, 'স্ত্রী');
      expect(n.mobile, '+8801611111111');
      expect(n.address, isNull);
    });
  });

  group('propertyRequestFromApi', () {
    test('maps payload with docs and co-owners', () {
      final r = propertyRequestFromApi({
        'id': 55,
        'action': 'edit',
        'property_id': 7,
        'payload': {
          'property_type': ['flat'],
          'property_type_other': null,
          'khatian_no': 'K9',
          'dag_no_cs': 'C9',
          'dag_no_rs': 'R9',
          'holding_number': 'H9',
          'land_quantity': '2',
          'my_share_quantity': '1',
          'ownership': 'একক',
          'co_owners': [
            {'owner_name': 'A', 'owner_phone': 'B'},
          ],
          'docs': [
            {'doc_type': 'khatian', 'keep_path': '/uploads/kept.jpg'},
            {'doc_type': 'new_doc', 'keep_path': null},
          ],
        },
        'status': 'pending',
        'cancel_reason': null,
        'reviewed_at': null,
        'created_at': '2026-03-01T00:00:00Z',
        'member_name': 'রহিম',
        'member_code': 'MBR-1',
      });
      expect(r.id, '55');
      expect(r.action, PropertyRequestAction.edit);
      expect(r.propertyId, '7');
      expect(r.payload.propertyType, ['flat']);
      expect(r.payload.khatianNo, 'K9');
      expect(r.payload.ownership, 'একক');
      expect(r.payload.coOwners.single.ownerName, 'A');
      expect(r.payload.docs, hasLength(2));
      expect(r.payload.docs[0].keepPath, '/uploads/kept.jpg');
      expect(r.payload.docs[1].keepPath, isNull);
      expect(r.status, PropertyRequestStatus.pending);
      expect(r.memberName, 'রহিম');
      expect(r.reference, 'PR-2026-0055');
    });
  });

  group('installment + payment mappers', () {
    test('installmentFromApi', () {
      final i = installmentFromApi({
        'id': 9,
        'year': 2026,
        'month': 3,
        'amount': 100,
        'status': 'paid',
        'paid_at': '2026-03-05',
      });
      expect(i.id, '9');
      expect(i.year, 2026);
      expect(i.month, 3);
      expect(i.amount, 100);
      expect(i.isPaid, isTrue);
      expect(i.paidAt, '2026-03-05');
    });

    test('installmentPaymentFromApi maps nested installments', () {
      final payment = installmentPaymentFromApi({
        'id': 4,
        'method': 'bKash',
        'transaction_ref': 'TRX-123',
        'sender_account': '017',
        'amount': '250',
        'paid_on': '2026-03-06',
        'proof_url': '/uploads/proof.png',
        'note': null,
        'status': 'pending',
        'rejection_reason': null,
        'reviewed_at': null,
        'created_at': '2026-03-06T10:00:00Z',
        'installments': [
          {'id': 1, 'year': 2026, 'month': 1, 'amount': 100},
          {'id': 2, 'year': 2026, 'month': 2, 'amount': '150'},
        ],
      });
      expect(payment.id, '4');
      expect(payment.method, 'bKash');
      expect(payment.transactionRef, 'TRX-123');
      expect(payment.senderAccount, '017');
      expect(payment.amount, 250); // string amounts coerced
      expect(payment.proofUrl, AppConfig.fileUrl('/uploads/proof.png'));
      expect(payment.status, SubmissionStatus.pending);
      expect(payment.installments, hasLength(2));
      expect(payment.installments[1].amount, 150);
    });

    test('costSplitShareFromApi', () {
      final s = costSplitShareFromApi({
        'id': 12,
        'cost_split_id': 3,
        'member_id': 123,
        'member_name': 'রহিম',
        'member_display_id': 'MBR-123',
        'cost_title': 'রাস্তা মেরামত',
        'cost_incurred_date': '2026-02-01',
        'cost_category': 'রক্ষণাবেক্ষণ',
        'amount_due': '500.50',
        'amount_paid': 200,
        'status': 'partial',
        'paid_at': null,
        'payment_method_id': null,
        'payment_method_label': null,
        'receipt_no': null,
      });
      expect(s.id, '12');
      expect(s.costSplitId, '3');
      expect(s.memberId, '123');
      expect(s.costTitle, 'রাস্তা মেরামত');
      expect(s.amountDue, 500.50);
      expect(s.amountPaid, 200);
      expect(s.status, ShareStatus.partial);
      expect(s.isOutstanding, isTrue);
      expect(s.outstanding, closeTo(300.5, 0.001));
    });
  });

  group('finance mappers', () {
    test('summary maps nested totals, breakdowns and series', () {
      final s = financeSummaryFromApi({
        'period': {'type': 'custom', 'date_from': '2026-01-01', 'date_to': '2026-01-31'},
        'totals': {'income': '1000', 'expense': '400.25', 'net': '599.75'},
        'balance': '9999',
        'previous': {'income': '800', 'expense': '300', 'net': '500'},
        'income_by_category': [
          {'category_id': 1, 'category': 'চাঁদা', 'amount': '1000', 'share': '100'},
        ],
        'expense_by_category': const [],
        'previous_income_by_category': const [],
        'previous_expense_by_category': const [],
        'series': [
          {'label': '2026-01', 'income': '1000', 'expense': '400.25', 'net': '599.75'},
        ],
        'granularity': 'month',
        'transaction_count': 3,
        'last_updated': '2026-02-01T00:00:00Z',
      });
      expect(s.totals.income, 1000);
      expect(s.totals.expense, 400.25);
      expect(s.balance, 9999);
      expect(s.previous!.net, 500);
      expect(s.incomeByCategory.single.category, 'চাঁদা');
      expect(s.incomeByCategory.single.categoryId, '1');
      expect(s.series.single.label, '2026-01');
      expect(s.granularityIsYear, isFalse);
      expect(s.transactionCount, 3);
      expect(s.periodDateFrom, '2026-01-01');
      expect(s.periodDateTo, '2026-01-31');
    });

    test('ledger page maps transactions', () {
      final page = financeLedgerPageFromApi({
        'items': [
          {
            'id': 1,
            'txn_date': '2026-01-10',
            'type': 'expense',
            'category_id': null,
            'category_label': 'ব্যয়',
            'amount': '50',
            'description': 'কেনাকাটা',
            'reference_no': 'REF-1',
            'attachment_url': '/uploads/a.pdf',
            'status': 'approved',
            'approved_by_name': 'কমিটি',
            'approved_at': null,
            'reversal_of_id': null,
            'created_at': '2026-01-10T00:00:00Z',
          },
        ],
        'total': 1,
        'totals': {'income': '0', 'expense': '50', 'net': '-50'},
      });
      final t = page.items.single;
      expect(t.id, '1');
      expect(t.type, FinanceType.expense);
      expect(t.amount, 50);
      expect(t.attachmentUrl, AppConfig.fileUrl('/uploads/a.pdf'));
      expect(t.status, FinanceStatus.approved);
      expect(page.total, 1);
      expect(page.totals.net, -50);
    });
  });

  group('roadmap mappers', () {
    test('roadmapFromApi maps timeframes and items', () {
      final r = roadmapFromApi({
        'last_updated': '2026-01-01',
        'totals': {'total': 2, 'done': 1, 'in_progress': 1, 'planned': 0, 'percent': 50},
        'timeframes': [
          {
            'id': 1,
            'key': 'short',
            'name_bn': 'স্বল্পমেয়াদ',
            'name_en': 'Short',
            'target_window_bn': '১ বছর',
            'target_window_en': '1 year',
            'sort_order': 1,
            'total': 2,
            'done': 1,
            'in_progress': 1,
            'planned': 0,
            'percent': 50,
            'items': [
              {
                'id': 10,
                'timeframe_id': 1,
                'text': 'রাস্তা',
                'status': 'done',
                'target_date': '2026-06-01',
                'owner': 'কমিটি',
                'note': null,
                'sort_order': 1,
                'completed_at': '2026-05-01',
                'updated_at': null,
              },
              {
                'id': 11,
                'timeframe_id': 1,
                'text': 'মসজিদ',
                'status': 'in_progress',
                'target_date': null,
                'owner': null,
                'note': 'চলছে',
                'sort_order': 2,
                'completed_at': null,
                'updated_at': null,
              },
            ],
          },
        ],
      });
      expect(r.lastUpdated, '2026-01-01');
      expect(r.totals.done, 1);
      expect(r.timeframes.single.nameBn, 'স্বল্পমেয়াদ');
      expect(r.timeframes.single.windowEn, '1 year');
      final items = r.timeframes.single.items;
      expect(items[0].id, '10');
      expect(items[0].status, RoadmapStatus.done);
      expect(items[1].status, RoadmapStatus.inProgress);
      expect(items[1].timeframeId, '1');
      expect(currentTimeframeIndex(r), 0);
    });
  });

  group('resolution book mappers', () {
    test('meeting detail maps resolutions/attendance/recordings', () {
      final m = meetingDetailFromApi({
        'id': 5,
        'meeting_no': '2026-01',
        'date': '2026-01-10',
        'time': '10:00',
        'meeting_type': 'online',
        'chairperson': 'সভাপতি',
        'next_meeting_date': '2026-02-10',
        'status': 'completed',
        'resolution_count': 1,
        'attendance_present': 1,
        'attendance_total': 2,
        'attendance_percent': 50,
        'agenda': 'আলোচ্যসূচি',
        'summary': null,
        'created_by': 'রহিম',
        'updated_at': '2026-01-11T00:00:00Z',
        'resolutions': [
          {
            'id': 7,
            'meeting_id': 5,
            'resolution_no': 1,
            'decision': 'সিদ্ধান্ত',
            'vote_for': 5,
            'vote_against': 1,
            'vote_neutral': 0,
            'assigned_to': {'id': 2, 'full_name': 'করিম', 'member_id': 'MBR-2'},
            'task': 'কাজ',
            'due_date': '2026-03-01',
            'status': 'in_progress',
            'updated_at': null,
          },
        ],
        'attendance': [
          {
            'member': {'id': 2, 'full_name': 'করিম', 'member_id': null},
            'status': 'present',
          },
        ],
        'recordings': [
          {
            'id': 9,
            'meeting_id': 5,
            'original_name': 'rec.mp4',
            'file_type': 'video',
            'file_size': 1024,
            'uploaded_by': null,
            'uploaded_at': null,
          },
        ],
      });
      expect(m.id, '5');
      expect(m.meetingNo, '2026-01');
      expect(m.meetingType, MeetingType.online);
      expect(m.status, MeetingStatus.completed);
      expect(m.attendancePercent, 50);
      final res = m.resolutions.single;
      expect(res.id, '7');
      expect(res.voteFor, 5);
      expect(res.assignedTo!.fullName, 'করিম');
      expect(res.assignedTo!.memberId, 'MBR-2');
      expect(res.status, ResolutionStatus.inProgress);
      expect(m.attendance.single.status, AttendanceStatus.present);
      expect(m.recordings.single.fileType, RecordingType.video);
      expect(m.recordings.single.fileSize, 1024);
    });

    test('meeting summary maps dashboard fields', () {
      final s = meetingSummaryFromApi({
        'total_meetings': 10,
        'meetings_this_year': 3,
        'average_attendance_percent': 88.5,
        'open_action_items': 4,
        'upcoming_meeting_date': '2026-04-01',
        'recent_meetings': [
          {
            'id': 5,
            'meeting_no': '2026-01',
            'date': '2026-01-10',
            'time': null,
            'meeting_type': 'offline',
            'chairperson': 'x',
            'next_meeting_date': null,
            'status': 'scheduled',
            'resolution_count': 0,
            'attendance_present': 0,
            'attendance_total': 0,
            'attendance_percent': 0,
          },
        ],
      });
      expect(s.totalMeetings, 10);
      expect(s.meetingsThisYear, 3);
      expect(s.averageAttendancePercent, 88.5);
      expect(s.openActionItems, 4);
      expect(s.upcomingMeetingDate, '2026-04-01');
      expect(s.recentMeetings.single.status, MeetingStatus.scheduled);
    });
  });

  group('MemberProfileUpdate snake_case body', () {
    test('emits only set fields with snake_case keys', () {
      final body = const MemberProfileUpdate(
        fullName: 'নতুন নাম',
        mobile: '+8801700000000',
        currentRoad: 'রাস্তা',
      ).toSnakeCaseBody();
      expect(body, {
        'full_name': 'নতুন নাম',
        'mobile': '+8801700000000',
        'current_road': 'রাস্তা',
      });
    });

    test('touchesCoreFields mirrors Angular CORE_FIELDS', () {
      const current = MemberProfile(
        memberId: '1',
        status: 'approved',
        fullName: 'A',
        fatherOrHusband: 'B',
        mother: 'C',
        dob: '1990-01-01',
        mobile: '+8801700000000',
        memberPhotoUrl: '',
        receiptPhotoUrl: '',
        properties: [],
        nominees: [],
      );
      // Core change (fullName) -> re-queue.
      expect(const MemberProfileUpdate(fullName: 'X').touchesCoreFields(current), isTrue);
      // Contact-only change (mobile) -> no re-queue.
      expect(
        const MemberProfileUpdate(mobile: '+8801800000000').touchesCoreFields(current),
        isFalse,
      );
      // Identical core values -> no re-queue.
      expect(const MemberProfileUpdate(fullName: 'A').touchesCoreFields(current), isFalse);
    });
  });

  group('formatting helpers', () {
    test('lakh grouping', () {
      expect(NumberFormatLike.enInGrouped(1250000), '12,50,000');
      expect(NumberFormatLike.enInGrouped(50000), '50,000');
      expect(NumberFormatLike.enIn('1250000.50'), '12,50,000.50');
    });
    test('taka + percent + bangla digits', () {
      expect(formatTakaCompact(50000, 'en'), '৳ 50,000');
      expect(formatTakaCompact(50000, 'bn'), '৳ ৫০,০০০');
      expect(formatPercent(42.3, 'bn'), '৪২.৩%');
      expect(formatTaka(1000, 'en'), '৳ 1,000.00');
    });
  });
}
