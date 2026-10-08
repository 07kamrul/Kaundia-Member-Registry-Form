import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/enums/enums.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/features/management/data/admin_repository.dart';

import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late AdminRepository repository;

  setUp(() {
    api = _MockApiClient();
    repository = AdminRepository(apiClient: api);
  });

  test('listSubmissions passes status query and maps rows', () async {
    when(() => api.getUri(
          '/admin/submissions',
          query: any(named: 'query'),
        )).thenAnswer((_) async => [
          {
            'id': 1,
            'full_name': 'নাম',
            'mobile': '017',
            'status': 'pending',
            'created_at': '2026-01-01T00:00:00Z',
          },
        ]);

    final rows = await repository.listSubmissions(status: SubmissionStatus.pending);

    final query = verify(() => api.getUri('/admin/submissions',
        query: captureAny(named: 'query'))).captured.single as Map<String, dynamic>;
    expect(query['status'], 'pending');
    expect(rows.single.fullName, 'নাম');
    expect(rows.single.status, SubmissionStatus.pending);
  });

  test('getSubmission returns detail entity', () async {
    when(() => api.getUri('/admin/submissions/9'))
        .thenAnswer((_) async => {
              'id': 9,
              'status': 'pending',
              'full_name': 'n',
              'mobile': 'm',
              'created_at': 'c',
              'father_or_husband': 'f',
              'mother': 'mo',
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
            });
    final detail = await repository.getSubmission('9');
    expect(detail.id, '9');
  });

  test('approveSubmission POSTs empty body and returns member id', () async {
    when(() => api.post('/admin/submissions/3/approve', any()))
        .thenAnswer((_) async => {'member_id': 'KND-33'});
    final memberId = await repository.approveSubmission('3');
    expect(memberId, 'KND-33');
    verify(() => api.post('/admin/submissions/3/approve', {})).called(1);
  });

  test('rejectSubmission returns email_sent flag', () async {
    when(() => api.post('/admin/submissions/3/reject', any()))
        .thenAnswer((_) async => {'status': 'rejected', 'email_sent': false});
    final sent = await repository.rejectSubmission('3', 'কারণ');
    expect(sent, isFalse);
    final body = verify(() => api.post('/admin/submissions/3/reject', captureAny(named: 'any')))
        .captured
        .single as Map<String, dynamic>;
    expect(body['reason'], 'কারণ');
  });

  test('createFeeSettingVersion sends snake_case body', () async {
    when(() => api.post('/admin/fee-settings', any()))
        .thenAnswer((_) async => {
              'id': 5,
              'key': 'admission_fee',
              'value': 600,
              'unit': 'taka',
              'start_date': '2026-02-01',
              'status': 1,
            });
    final fee = await repository.createFeeSettingVersion(
      key: 'admission_fee',
      value: 600,
      unit: 'taka',
      startDate: '2026-02-01',
    );
    expect(fee.value, 600);
    expect(fee.isActive, isTrue);
    final body = verify(() => api.post('/admin/fee-settings', captureAny(named: 'any')))
        .captured
        .single as Map<String, dynamic>;
    expect(body['key'], 'admission_fee');
    expect(body['value'], 600);
    expect(body['unit'], 'taka');
    expect(body['start_date'], '2026-02-01');
  });

  test('createConfigListItem sends sort_order default 0', () async {
    when(() => api.post('/admin/config-lists', any())).thenAnswer((_) async => {
          'id': 2,
          'category': 'property_type',
          'value': 'ভূমি',
          'label': 'ভূমি',
          'sort_order': 0,
          'is_active': 1,
        });
    final item = await repository.createConfigListItem(
      category: 'property_type',
      value: 'ভূমি',
      label: 'ভূমি',
    );
    expect(item.isActive, isTrue);
    final body = verify(() => api.post('/admin/config-lists', captureAny(named: 'any')))
        .captured
        .single as Map<String, dynamic>;
    expect(body['sort_order'], 0);
    expect(body.containsKey('is_active'), isFalse);
  });

  test('updateConfigListItem patch body only includes provided fields', () async {
    when(() => api.patch('/admin/config-lists/4', any()))
        .thenAnswer((_) async => {
              'id': 4,
              'category': 'notice_category',
              'value': 'v',
              'label': 'l',
              'sort_order': 1,
              'is_active': 0,
            });
    final item = await repository.updateConfigListItem('4', isActive: false);
    expect(item.isActive, isFalse);
    final body = verify(() => api.patch('/admin/config-lists/4', captureAny(named: 'any')))
        .captured
        .single as Map<String, dynamic>;
    expect(body, {'is_active': false});
  });

  test('notice body sends snake_case with null category and publish_at', () async {
    when(() => api.post('/admin/notices', any())).thenAnswer((_) async => {
          'id': 1,
          'title': 't',
          'body': 'b',
          'category_id': null,
          'is_published': false,
          'is_members_only': false,
          'publish_at': null,
          'created_at': 'c',
          'updated_at': 'u',
        });
    await repository.createNotice(const NoticeInput(title: 't', body: 'b'));
    final body = verify(() => api.post('/admin/notices', captureAny(named: 'any')))
        .captured
        .single as Map<String, dynamic>;
    expect(body['category_id'], isNull);
    expect(body['is_published'], isFalse);
    expect(body['is_members_only'], isFalse);
    expect(body['publish_at'], isNull);
  });
}
