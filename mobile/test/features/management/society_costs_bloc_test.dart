import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/management/data/admin_repository.dart';
import 'package:kaundia_app/features/management/domain/finance_entities.dart';
import 'package:kaundia_app/features/management/presentation/bloc/bloc_actions.dart';
import 'package:kaundia_app/features/management/presentation/bloc/society_costs_bloc.dart';
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
  late SocietyCostsBloc bloc;

  /// Lets queued events and their mocked async work run to completion.
  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUpAll(() {
    registerFallbackValue(const ApiException(type: ApiExceptionType.network));
  });

  setUp(() {
    api = _MockApiClient();
    costRepository = SocietyCostRepository(apiClient: api);
    final adminRepository = AdminRepository(apiClient: api);
    when(() => api.getUri('/admin/config-lists', query: any(named: 'query')))
        .thenAnswer((_) async => []);
    bloc = SocietyCostsBloc(
      adminRepository: adminRepository,
      costRepository: costRepository,
    );
  });

  tearDown(() => bloc.close());

  group('split preview (dry_run)', () {
    test('equal-method preview seeds manual amounts and returns no rows',
        () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenAnswer((_) async => [
                {'member_id': 1, 'member_name': 'এক', 'amount_due': '500'},
                {'member_id': 2, 'member_name': 'দুই', 'amount_due': '500'},
              ]);
      bloc.add(SocietySplitOpened(cost: _cost(3)));
      await settle();

      expect(bloc.state.splitCost, isNotNull);
      expect(bloc.state.splitMethod, CostSplitMethod.equal);
      expect(bloc.state.splitPreview, isEmpty);
      expect(bloc.state.manualAmounts.map((m) => m.memberName), ['এক', 'দুই']);

      final body =
          verify(() => api.post('/admin/society-costs/3/split', captureAny()))
              .captured
              .last as Map<String, dynamic>;
      expect(body['split_method'], 'equal');
      expect(body['dry_run'], true);
    });

    test('manual-method preview with amounts posts manual_shares with dry_run',
        () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenAnswer((_) async => [
                {'member_id': 1, 'member_name': 'এক', 'amount_due': '500'},
                {'member_id': 2, 'member_name': 'দুই', 'amount_due': '500'},
              ]);
      bloc.add(SocietySplitOpened(cost: _cost(3)));
      await settle();
      bloc.add(const SocietySplitMethodChanged(method: CostSplitMethod.manual));
      await settle();
      bloc.add(const SocietyManualAmountChanged(memberId: 1, amount: 600));
      bloc.add(const SocietyManualAmountChanged(memberId: 2, amount: 400));
      bloc.add(const SocietySplitPreviewRefreshed());
      await settle();

      expect(bloc.manualTotal, 1000);
      expect(bloc.manualMismatch, isFalse);

      final bodies =
          verify(() => api.post('/admin/society-costs/3/split', captureAny()))
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
      bloc.add(SocietySplitOpened(cost: _cost(3)));
      await settle();
      bloc.add(const SocietySplitMethodChanged(method: CostSplitMethod.manual));
      await settle();
      bloc.add(const SocietyManualAmountChanged(memberId: 1, amount: 600));
      bloc.add(const SocietyManualAmountChanged(memberId: 2, amount: 300));
      await settle();
      expect(bloc.manualTotal, 900);
      expect(bloc.manualMismatch, isTrue);
    });

    test('preview failure exposes splitError', () async {
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenThrow(const ApiException(type: ApiExceptionType.network));
      bloc.add(SocietySplitOpened(cost: _cost(3)));
      await settle();
      expect(bloc.state.splitError, isNotNull);
      expect(bloc.state.splitLoading, isFalse);
    });

    test('SocietySplitConfirmed saves without dry_run and refreshes', () async {
      var call = 0;
      when(() => api.post('/admin/society-costs/3/split', any()))
          .thenAnswer((_) async {
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
      when(() =>
          api.getUri('/admin/society-costs/summary',
              query: any(named: 'query'))).thenAnswer((_) async => {
            'total_amount': '0',
            'society_fund_total': '0',
            'member_billed_total': '0',
            'outstanding_total': '0',
            'collected_total': '0',
            'by_category': [],
          });

      bloc.add(SocietySplitOpened(cost: _cost(3)));
      await settle();
      final ok = await dispatchForBool(
          bloc, (c) => SocietySplitConfirmed(completer: c));

      expect(ok, isTrue);
      final bodies =
          verify(() => api.post('/admin/society-costs/3/split', captureAny()))
              .captured
              .cast<Map<String, dynamic>>()
              .toList();
      expect(bodies.last.containsKey('dry_run'), isFalse);
      expect(bodies.last['split_method'], 'equal');
      verify(() =>
              api.getUri('/admin/society-costs', query: any(named: 'query')))
          .called(1);
    });
  });

  group('SocietySharePaymentRecorded', () {
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
      final ok = await dispatchForBool(
        bloc,
        (c) => SocietySharePaymentRecorded(
          share: share,
          additionalAmount: 600,
          receiptNo: 'R-1',
          completer: c,
        ),
      );

      expect(ok, isTrue);
      final body =
          verify(() => api.patch('/admin/cost-split-shares/9', captureAny()))
              .captured
              .single as Map<String, dynamic>;
      expect(body['amount_paid'], 1000);
      expect(body['receipt_no'], 'R-1');
    });
  });
}
