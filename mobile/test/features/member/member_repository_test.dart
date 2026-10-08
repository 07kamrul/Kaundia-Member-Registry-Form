import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/features/member/data/member_repository.dart';
import 'package:kaundia_app/features/member/data/payment_repository.dart';
import 'package:kaundia_app/features/member/domain/member_entities.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late MemberRepository repo;
  late MemberPaymentRepository paymentRepo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    api = _MockApiClient();
    repo = MemberRepository(apiClient: api);
    paymentRepo = MemberPaymentRepository(apiClient: api);
  });

  group('MemberRepository', () {
    test('getProfile hits /member/me and maps', () async {
      when(() => api.getUri('/member/me')).thenAnswer((_) async => {
            'member_id': 1,
            'status': 'pending',
            'full_name': 'A',
            'father_or_husband': 'B',
            'mother': 'C',
            'dob': '1990-01-01',
            'mobile': '+8801700000000',
            'properties': [],
            'nominees': [],
          });
      final p = await repo.getProfile();
      expect(p.memberId, '1');
      expect(p.fullName, 'A');
      verify(() => api.getUri('/member/me')).called(1);
    });

    test('updateProfile sends snake_case sparse body', () async {
      when(() => api.patch('/member/profile', any(that: isA<Map<String, String?>>())))
          .thenAnswer((_) async => {
                'member_id': 1,
                'status': 'pending',
                'full_name': 'X',
                'father_or_husband': 'B',
                'mother': 'C',
                'dob': '1990-01-01',
                'mobile': '+8801700000000',
                'properties': [],
                'nominees': [],
              });
      await repo.updateProfile(const MemberProfileUpdate(fullName: 'X', mobile: '+8801800000000'));
      final captured =
          verify(() => api.patch('/member/profile', captureAny(that: isA<Map<String, String?>>())))
              .captured
              .single as Map<String, String?>;
      expect(captured, {
        'full_name': 'X',
        'mobile': '+8801800000000',
      });
    });

    test('getPicnicRates passes payment_date query', () async {
      when(() => api.getUri('/member/picnic-rates',
              query: any(named: 'query', that: isA<Map<String, dynamic>>())))
          .thenAnswer((_) async => {
                'head_fee': 500,
                'additional_head_fee': 250,
                'unit': 'person',
                'effective_from': '2026-01-01',
              });
      final rates = await repo.getPicnicRates('2026-03-01');
      expect(rates.headFee, 500);
      expect(rates.additionalHeadFee, 250);
      final query = verify(() => api.getUri('/member/picnic-rates',
              query: captureAny(named: 'query')))
          .captured
          .single as Map<String, dynamic>;
      expect(query, {'payment_date': '2026-03-01'});
    });

    test('createPicnicPayment posts the Angular payload shape', () async {
      when(() => api.post('/member/picnic-payments', any()))
          .thenAnswer((_) async => {
                'id': 2,
                'head_price': 500,
                'additional_price': 250,
                'additional_count': 1,
                'total': 750,
                'additional_heads': [
                  {'name': 'A', 'relation': 'guest'},
                ],
                'payment_date': '2026-03-01',
                'receipt_no': null,
                'payment_method': 'Cash',
                'created_at': '2026-03-01T00:00:00Z',
              });
      final payment = await repo.createPicnicPayment(PicnicPaymentInput(
        additionalHeads: 1,
        additionalPeople: const [
          PicnicAdditionalHead(name: 'A', relation: 'guest'),
        ],
        paymentDate: '2026-03-01',
        receiptNo: '',
        paymentMethod: 'Cash',
      ));
      expect(payment.total, 750);
      final body = verify(() => api.post('/member/picnic-payments', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body['additional_heads'], 1);
      expect(body['additional_people'], [
        {'name': 'A', 'relation': 'guest'},
      ]);
      expect(body['payment_date'], '2026-03-01');
      expect(body['receipt_no'], isNull); // empty receipt -> null
      expect(body['payment_method'], 'Cash');
    });

    test('changePassword posts snake_case payload', () async {
      when(() => api.post('/member/change-password', any())).thenAnswer((_) async => null);
      await repo.changePassword(currentPassword: 'old', newPassword: 'new');
      final body = verify(() => api.post('/member/change-password', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body, {'current_password': 'old', 'new_password': 'new'});
    });
  });

  group('MemberPaymentRepository', () {
    test('getPayable maps the Angular PayableSummaryApi', () async {
      when(() => api.getUri('/member/installment-payments/payable'))
          .thenAnswer((_) async => {
                'due': [
                  {'id': 1, 'year': 2026, 'month': 1, 'amount': 100},
                ],
                'pending_installment_ids': [2],
                'total_due': '100',
                'accounts': [
                  {'method': 'bKash', 'details': '017xx'},
                ],
                'payments': [
                  {
                    'id': 9,
                    'method': 'Cash',
                    'transaction_ref': 'R1',
                    'sender_account': null,
                    'amount': 100,
                    'paid_on': '2026-01-05',
                    'proof_url': null,
                    'note': null,
                    'status': 'approved',
                    'rejection_reason': null,
                    'reviewed_at': '2026-01-06',
                    'created_at': '2026-01-05T00:00:00Z',
                    'installments': [
                      {'id': 1, 'year': 2026, 'month': 1, 'amount': 100},
                    ],
                  },
                ],
              });
      final s = await paymentRepo.getPayable();
      expect(s.due.single.id, '1');
      expect(s.totalDue, 100);
      expect(s.pendingInstallmentIds, {'2'});
      expect(s.accounts.single.method, 'bKash');
      expect(s.payments.single.status.name, 'approved');
    });

    test('myCostShares maps GET /member/cost-shares', () async {
      when(() => api.getUri('/member/cost-shares')).thenAnswer((_) async => [
            {
              'id': 1,
              'cost_split_id': 2,
              'member_id': 3,
              'member_name': null,
              'member_display_id': null,
              'cost_title': 'C',
              'cost_incurred_date': '2026-02-02',
              'cost_category': null,
              'amount_due': '400',
              'amount_paid': '400',
              'status': 'paid',
              'paid_at': '2026-02-03',
              'payment_method_id': 1,
              'payment_method_label': 'Cash',
              'receipt_no': 'R',
            },
          ]);
      final shares = await paymentRepo.myCostShares();
      expect(shares.single.id, '1');
      expect(shares.single.status.name, 'paid');
      expect(shares.single.paymentMethodId, '1');
      expect(shares.single.isOutstanding, isFalse);
    });
  });
}
