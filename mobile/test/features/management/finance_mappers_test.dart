import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/management/domain/finance_entities.dart';
import 'package:kaundia_app/features/management/domain/finance_mappers.dart';

void main() {
  group('finance mappers', () {
    test('transaction maps every field incl string amounts', () {
      final t = Map<String, dynamic>.from({
        'id': 5,
        'txn_date': '2026-01-15',
        'type': 'income',
        'category_id': 2,
        'category_label': 'চাঁদা',
        'amount': '1250.50',
        'description': 'জানুয়ারি চাঁদা',
        'reference_no': 'REF-1',
        'attachment_url': 'uploads/txn/a.pdf',
        'status': 'approved',
        'approved_by_name': 'সভাপতি',
        'approved_at': '2026-01-16T00:00:00Z',
        'reversal_of_id': null,
        'created_at': '2026-01-15T00:00:00Z',
        'internal_notes': 'নোট',
        'rejection_reason': null,
        'linked_payment_type': 'installment',
        'linked_payment_id': 9,
        'created_by_name': 'কোষাধ্যক্ষ',
        'is_active': false,
      }).toTransactionEntity();

      expect(t.id, 5);
      expect(t.txnDate, '2026-01-15');
      expect(t.type, FinanceType.income);
      expect(t.categoryId, 2);
      expect(t.categoryLabel, 'চাঁদা');
      expect(t.amount, 1250.5);
      expect(t.description, 'জানুয়ারি চাঁদা');
      expect(t.referenceNo, 'REF-1');
      expect(t.attachmentUrl, isNotNull);
      expect(t.status, FinanceStatus.approved);
      expect(t.approvedByName, 'সভাপতি');
      expect(t.approvedAt, isNotNull);
      expect(t.reversalOfId, isNull);
      expect(t.createdAt, '2026-01-15T00:00:00Z');
      expect(t.internalNotes, 'নোট');
      expect(t.rejectionReason, isNull);
      expect(t.linkedPaymentType, PaymentSourceType.installment);
      expect(t.linkedPaymentId, 9);
      expect(t.createdByName, 'কোষাধ্যক্ষ');
      expect(t.isActive, isFalse);
    });

    test('ledger page maps totals as strings', () {
      final page = Map<String, dynamic>.from({
        'items': [
          {
            'id': 1,
            'txn_date': '2026-01-01',
            'type': 'expense',
            'amount': 10,
            'description': 'd',
            'status': 'draft',
            'created_at': 'c',
          },
        ],
        'total': 1,
        'totals': {'income': '100', 'expense': '40', 'net': '60'},
      }).toLedgerEntity();
      expect(page.total, 1);
      expect(page.totals.income, 100);
      expect(page.totals.expense, 40);
      expect(page.totals.net, 60);
      expect(page.items.single.type, FinanceType.expense);
      expect(page.items.single.status, FinanceStatus.draft);
    });

    test('overview + unlinked payment', () {
      final o = Map<String, dynamic>.from({
        'pending_count': 3,
        'month_income': '500',
        'month_expense': '200',
        'month_net': '300',
        'balance': '1000',
        'recent': [],
      }).toOverviewEntity();
      expect(o.pendingCount, 3);
      expect(o.monthNet, 300);
      expect(o.balance, 1000);

      final u = Map<String, dynamic>.from({
        'source_type': 'picnic_payment',
        'source_id': 12,
        'member_name': 'মেম্বার',
        'member_display_id': 'KND-3',
        'amount': '250',
        'paid_on': '2026-01-10',
        'receipt_no': 'R',
        'detail': 'পিকনিক',
      }).toUnlinkedPaymentEntity();
      expect(u.sourceType, PaymentSourceType.picnicPayment);
      expect(u.sourceId, 12);
      expect(u.amount, 250);
      expect(u.memberDisplayId, 'KND-3');
    });

    test('admin installment payment', () {
      final p = Map<String, dynamic>.from({
        'id': 8,
        'method': 'bkash',
        'transaction_ref': 'TRX-9',
        'sender_account': '017',
        'amount': 300,
        'paid_on': '2026-01-20',
        'proof_url': 'uploads/proof.jpg',
        'note': 'নোট',
        'status': 'pending',
        'rejection_reason': null,
        'reviewed_at': null,
        'created_at': '2026-01-21T00:00:00Z',
        'member_id': 4,
        'member_name': 'সদস্য',
        'member_display_id': 'KND-4',
        'installments': [
          {'id': 3, 'year': 2026, 'month': 2, 'amount': '150'},
        ],
      }).toAdminPaymentEntity();
      expect(p.id, 8);
      expect(p.method, 'bkash');
      expect(p.transactionRef, 'TRX-9');
      expect(p.senderAccount, '017');
      expect(p.amount, 300);
      expect(p.status, 'pending');
      expect(p.memberId, 4);
      expect(p.memberName, 'সদস্য');
      expect(p.memberDisplayId, 'KND-4');
      expect(p.proofUrl, isNotNull);
      expect(p.installments.single.amount, 150);
      expect(p.installments.single.month, 2);
    });
  });

  group('roadmap mappers', () {
    test('roadmap with timeframes and items', () {
      final r = Map<String, dynamic>.from({
        'last_updated': '2026-01-01T00:00:00Z',
        'totals': {
          'total': 2,
          'done': 1,
          'in_progress': 1,
          'planned': 0,
          'percent': 50
        },
        'timeframes': [
          {
            'id': 1,
            'key': 'y1',
            'name_bn': 'প্রথম বছর',
            'name_en': 'Year 1',
            'target_window_bn': '২০২৬',
            'target_window_en': '2026',
            'sort_order': 0,
            'total': 2,
            'done': 1,
            'in_progress': 1,
            'planned': 0,
            'percent': 50,
            'items': [
              {
                'id': 10,
                'timeframe_id': 1,
                'text': 'কাজ',
                'status': 'in_progress',
                'target_date': '2026-06-30',
                'owner': 'কমিটি',
                'note': 'n',
                'sort_order': 0,
                'completed_at': null,
                'updated_at': null,
              },
            ],
          },
        ],
      }).toRoadmapEntity();

      expect(r.lastUpdated, isNotNull);
      expect(r.totals.done, 1);
      expect(r.totals.percent, 50);
      final tf = r.timeframes.single;
      expect(tf.id, 1);
      expect(tf.nameBn, 'প্রথম বছর');
      expect(tf.windowBn, '২০২৬');
      expect(tf.items.single.id, 10);
      expect(tf.items.single.status, RoadmapStatus.inProgress);
      expect(tf.items.single.targetDate, '2026-06-30');
      expect(tf.items.single.owner, 'কমিটি');
    });

    test('archived cycle', () {
      final c = Map<String, dynamic>.from({
        'archived_at': '2026-01-01T00:00:00Z',
        'total': 1,
        'done': 1,
        'items': [
          {
            'id': 2,
            'timeframe_id': 1,
            'text': 't',
            'status': 'done',
            'sort_order': 0,
          },
        ],
      }).toCycleEntity();
      expect(c.total, 1);
      expect(c.done, 1);
      expect(c.items.single.status, RoadmapStatus.done);
    });
  });

  group('society cost mappers', () {
    test('cost with split + shares', () {
      final c = Map<String, dynamic>.from({
        'id': 3,
        'title': 'রাস্তা মেরামত',
        'description': 'd',
        'category_id': 1,
        'category_label': 'রক্ষণাবেক্ষণ',
        'total_amount': '10000',
        'incurred_date': '2026-01-01',
        'payment_source': 'member_billed',
        'receipt_file_url': 'uploads/receipt.pdf',
        'notes': 'n',
        'created_at': 'c',
        'updated_at': 'u',
        'split': {
          'id': 5,
          'society_cost_id': 3,
          'split_method': 'equal',
          'created_at': 'cs',
          'shares': [
            {
              'id': 50,
              'cost_split_id': 5,
              'member_id': 7,
              'member_name': 'সদস্য',
              'member_display_id': 'KND-7',
              'cost_title': 'রাস্তা মেরামত',
              'cost_incurred_date': '2026-01-01',
              'cost_category': 'রক্ষণাবেক্ষণ',
              'amount_due': '500',
              'amount_paid': '250',
              'status': 'partial',
              'paid_at': '2026-01-05',
              'payment_method_id': 1,
              'payment_method_label': 'cash',
              'receipt_no': 'R-9',
            },
          ],
        },
      }).toCostEntity();

      expect(c.id, 3);
      expect(c.title, 'রাস্তা মেরামত');
      expect(c.totalAmount, 10000);
      expect(c.paymentSource, CostPaymentSource.memberBilled);
      expect(c.receiptFileUrl, isNotNull);
      expect(c.split, isNotNull);
      expect(c.split!.splitMethod, CostSplitMethod.equal);
      final share = c.split!.shares.single;
      expect(share.id, 50);
      expect(share.costSplitId, 5);
      expect(share.memberId, 7);
      expect(share.amountDue, 500);
      expect(share.amountPaid, 250);
      expect(share.status, ShareStatus.partial);
      expect(share.receiptNo, 'R-9');
    });

    test('split preview row + summary strings', () {
      final row = Map<String, dynamic>.from({
        'member_id': 1,
        'member_name': 'এক',
        'amount_due': '333.33',
      }).toSplitPreviewRowEntity();
      expect(row.memberId, 1);
      expect(row.amountDue, 333.33);

      final s = Map<String, dynamic>.from({
        'total_amount': '100',
        'society_fund_total': '40',
        'member_billed_total': '60',
        'outstanding_total': '20',
        'collected_total': '80',
        'by_category': [
          {'category': 'ক', 'total': '70'},
        ],
      }).toSummaryEntity();
      expect(s.totalAmount, 100);
      expect(s.societyFundTotal, 40);
      expect(s.memberBilledTotal, 60);
      expect(s.outstandingTotal, 20);
      expect(s.collectedTotal, 80);
      expect(s.byCategory.single.category, 'ক');
      expect(s.byCategory.single.total, 70);
    });
  });
}
