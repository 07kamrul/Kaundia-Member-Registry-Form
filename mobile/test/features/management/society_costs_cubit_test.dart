import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/management/data/admin_repository.dart';
import 'package:kaundia_app/features/management/domain/finance_entities.dart';
import 'package:kaundia_app/features/management/presentation/bloc/society_costs_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

SocietyCost _cost(int id, {CostSplit? split}) => SocietyCost(
      id: id,
      title: 'রাস্তা',
      totalAmount: 1000,
      incurredDate: '2026-01-01',
      paymentSource: CostPaymentSource.memberBilled,
      createdAt: 'c',
      updatedAt: 'u',
      split: split,
    );

void main() {
  late _MockApiClient api;
  late SocietyCostRepository costRepository;
  late SocietyCostsCubit cubit;

  setUpAll(() {
    registerFallbackValue(const ApiException(type: ApiExceptionType.network));
  });

  setUp(() {
    api = _MockApiClient();
    costRepository = SocietyCostRepository(apiClient: api);
    final adminRepository = AdminRepository(apiClient: api);
    when(() => api.getUri('/admin/config-lists', query: any(named: 'query')))
        .thenAnswer((_) async => []);
    cubit = SocietyCostsCubit(
      adminRepository: adminRepository,
      costRepository: costRepository,
    );
  });

  group('split preview (dry_run)', () {
    test('equal-method preview seeds manual amounts and returns no rows', () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenAnswer((_) async => [
                {'member_id': 1, 'member_name': 'এক', 'amount_due': '500'},
                {'member_id': 2, 'member_name': 'দুই', 'amount_due': '500'},
              ]);
      await cubit.openSplit(_cost(3));

      expect(cubit.state.splitCost, isNotNull);
      expect(cubit.state.splitMethod, CostSplitMethod.equal);
      expect(cubit.state.splitPreview, isEmpty);
      expect(cubit.state.manualAmounts.map((m) => m.memberName), ['এক', 'দুই']);

      final body = verify(() => api.post('/admin/society-costs/3/split', captureAny(named: 'any')))
          .captured
          .last as Map<String, dynamic>;
      expect(body['split_method'], 'equal');
      expect(body['dry_run'], true);
    });

    test('manual-method preview with amounts posts manual_shares with dry_run', () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenAnswer((_) async => [
                {'member_id': 1, 'member_name': 'এক', 'amount_due': '500'},
                {'member_id': 2, 'member_name': 'দুই', 'amount_due': '500'},
              ]);
      await cubit.openSplit(_cost(3));
      await cubit.setSplitMethod(CostSplitMethod.manual);
      cubit.setManualAmount(1, 600);
      cubit.setManualAmount(2, 400);
      await cubit.refreshSplitPreview();

      expect(cubit.manualTotal, 1000);
      expect(cubit.manualMismatch, isFalse);

      final bodies = verify(() => api.post('/admin/society-costs/3/split', captureAny(named: 'any')))
          .captured
          .cast<Map<String, dynamic>>()
          .toList();
      final last = bodies.last;
      expect(last['split_method'], 'manual');
      expect(last['dry_run'], true);
      expect(last['manual_shares'], [
        {'member_id': 1, 'amount_due': 600},
        {'member_id': 2, 'amount_due': 400},
      ]);
    });

    test('manual mismatch is detected against the cost total', () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenAnswer((_) async => [
                {'member_id': 1, 'member_name': 'এক', 'amount_due': '500'},
                {'member_id': 2, 'member_name': 'দুই', 'amount_due': '500'},
              ]);
      await cubit.openSplit(_cost(3));
      await cubit.setSplitMethod(CostSplitMethod.manual);
      cubit.setManualAmount(1, 600);
      cubit.setManualAmount(2, 300);
      expect(cubit.manualTotal, 900);
      expect(cubit.manualMismatch, isTrue);
    });

    test('preview failure exposes splitError', () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenThrow(const ApiException(type: ApiExceptionType.network));
      await cubit.openSplit(_cost(3));
      expect(cubit.state.splitError, isNotNull);
      expect(cubit.state.splitLoading, isFalse);
    });

    test('confirmSplit saves without dry_run and refreshes', () async {
      var call = 0;
      when(() => api.post('/admin/society-costs/3/split', any())).thenAnswer((_) async {
        call += 1;
        if (call == 1) {
          return [
            {'member_id': 1, 'member_name': 'এক', 'amount_due': '1000'},
          ];
        }
        return {
          'id': 3,
          'title': 'রাস্তা',
          'total_amount': '1000',
          'incurred_date': '2026-01-01',
          'payment_source': 'member_billed',
          'created_at': 'c',
          'updated_at': 'u',
          'split': {
            'id': 1,
            'society_cost_id': 3,
            'split_method': 'equal',
            'created_at': 'cs',
            'shares': [
              {
                'id': 9,
                'cost_split_id': 1,
                'member_id': 1,
                'amount_due': '1000',
                'amount_paid': 0,
                'status': 'unpaid',
              },
            ],
          },
        };
      });
      when(() => api.getUri('/admin/society-costs', query: any(named: 'query')))
          .thenAnswer((_) async => []);
      when(() => api.getUri('/admin/society-costs/summary', query: any(named: 'query')))
          .thenAnswer((_) async => {
                'total_amount': '0',
                'society_fund_total': '0',
                'member_billed_total': '0',
                'outstanding_total': '0',
                'collected_total': '0',
                'by_category': [],
              });

      await cubit.openSplit(_cost(3));
      final ok = await cubit.confirmSplit();

      expect(ok, isTrue);
      final bodies = verify(() => api.post('/admin/society-costs/3/split', captureAny(named: 'any')))
          .captured
          .cast<Map<String, dynamic>>()
          .toList();
      expect(bodies.last.containsKey('dry_run'), isFalse);
      expect(bodies.last['split_method'], 'equal');
      verify(() => api.getUri('/admin/society-costs', query: any(named: 'query'))).called(1);
    });
  });

  group('recordSharePayment', () {
    test('PATCHes amount_paid as due+additional', () async {
      when(() => api.patch('/admin/cost-split-shares/9', any()))
          .thenAnswer((_) async => {
                'id': 9,
                'cost_split_id': 1,
                'member_id': 1,
                'amount_due': '1000',
                'amount_paid': '1000',
                'status': 'paid',
              });
      when(() => api.getUri(any(), query: any(named: 'query')))
          .thenAnswer((_) async => []);
      final share = CostSplitShare(
        id: 9,
        costSplitId: 1,
        memberId: 1,
        amountDue: 1000,
        amountPaid: 400,
        status: ShareStatus.partial,
      );
      final ok = await cubit.recordSharePayment(share, additionalAmount: 600, receiptNo: 'R-1');

      expect(ok, isTrue);
      final body = verify(() => api.patch('/admin/cost-split-shares/9', captureAny(named: 'any')))
          .captured
          .single as Map<String, dynamic>;
      expect(body['amount_paid'], 1000);
      expect(body['receipt_no'], 'R-1');
    });
  });
}
