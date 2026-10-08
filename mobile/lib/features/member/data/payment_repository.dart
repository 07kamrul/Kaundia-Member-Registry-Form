import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/payment_entities.dart';

num _num(dynamic v) =>
    v is num ? v : (v is String ? num.tryParse(v) ?? 0 : 0);

String _str(dynamic v) => v?.toString() ?? '';
String? _s(dynamic v) => v == null ? null : v.toString();

String? _toFileUrl(dynamic path) {
  final raw = _s(path);
  if (raw == null || raw.isEmpty) return null;
  return AppConfig.fileUrl(raw);
}

InstallmentPayment installmentPaymentFromApi(Map<dynamic, dynamic> api) {
  final installments = (api['installments'] as List<dynamic>? ?? const []);
  return InstallmentPayment(
    id: _str(api['id']),
    method: _str(api['method']),
    transactionRef: _str(api['transaction_ref']),
    senderAccount: _s(api['sender_account']),
    amount: _num(api['amount']),
    paidOn: _str(api['paid_on']),
    proofUrl: _toFileUrl(api['proof_url']),
    note: _s(api['note']),
    status: SubmissionStatusX.fromName(_s(api['status'])),
    rejectionReason: _s(api['rejection_reason']),
    reviewedAt: _s(api['reviewed_at']),
    createdAt: _str(api['created_at']),
    installments: [
      for (final row in installments)
        PayableInstallment(
          id: _str((row as Map<dynamic, dynamic>)['id']),
          year: (row['year'] as num?)?.toInt() ?? 0,
          month: (row['month'] as num?)?.toInt() ?? 0,
          amount: _num(row['amount']),
        ),
    ],
  );
}

CostSplitShare costSplitShareFromApi(Map<dynamic, dynamic> api) => CostSplitShare(
      id: _str(api['id']),
      costSplitId: _str(api['cost_split_id']),
      memberId: _str(api['member_id']),
      memberName: _s(api['member_name']),
      memberDisplayId: _s(api['member_display_id']),
      costTitle: _s(api['cost_title']),
      costIncurredDate: _s(api['cost_incurred_date']),
      costCategory: _s(api['cost_category']),
      amountDue: _num(api['amount_due']),
      amountPaid: _num(api['amount_paid']),
      status: ShareStatusX.fromName(_s(api['status'])),
      paidAt: _s(api['paid_at']),
      paymentMethodId: api['payment_method_id']?.toString(),
      paymentMethodLabel: _s(api['payment_method_label']),
      receiptNo: _s(api['receipt_no']),
    );

/// Member-side installment online payments + own cost shares.
class MemberPaymentRepository {
  MemberPaymentRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const _memberBase = '/member/installment-payments';

  Future<PayableSummary> getPayable() async {
    final api = await _api.getUri('$_memberBase/payable') as Map<dynamic, dynamic>;
    final due = (api['due'] as List<dynamic>? ?? const []);
    return PayableSummary(
      due: [
        for (final row in due)
          PayableInstallment(
            id: _str((row as Map<dynamic, dynamic>)['id']),
            year: (row['year'] as num?)?.toInt() ?? 0,
            month: (row['month'] as num?)?.toInt() ?? 0,
            amount: _num(row['amount']),
          ),
      ],
      pendingInstallmentIds: {
        for (final id in (api['pending_installment_ids'] as List<dynamic>? ?? const []))
          id.toString(),
      },
      totalDue: _num(api['total_due']),
      accounts: [
        for (final a in (api['accounts'] as List<dynamic>? ?? const []))
          PaymentAccount(
            method: _str((a as Map<dynamic, dynamic>)['method']),
            details: _str(a['details']),
          ),
      ],
      payments: [
        for (final p in (api['payments'] as List<dynamic>? ?? const []))
          installmentPaymentFromApi(p as Map<dynamic, dynamic>),
      ],
    );
  }

  /// Multipart submit mirroring the Angular FormData field names.
  Future<InstallmentPayment> submit(PaymentSubmission payload) async {
    final form = FormData();
    form.fields.add(MapEntry('installment_ids', payload.installmentIds.join(',')));
    form.fields.add(MapEntry('method', payload.method));
    form.fields.add(MapEntry('transaction_ref', payload.transactionRef.trim()));
    form.fields.add(MapEntry('paid_on', payload.paidOn));
    final sender = payload.senderAccount?.trim();
    if (sender != null && sender.isNotEmpty) {
      form.fields.add(MapEntry('sender_account', sender));
    }
    final note = payload.note?.trim();
    if (note != null && note.isNotEmpty) {
      form.fields.add(MapEntry('note', note));
    }
    final proof = payload.proof;
    if (proof != null) {
      form.files.add(MapEntry(
        'proof',
        MultipartFile.fromBytes(proof.bytes,
            filename: proof.fileName, contentType: DioMediaType.parse(proof.mimeType)),
      ));
    }
    final data = await _api.postMultipart(_memberBase, form) as Map<dynamic, dynamic>;
    return installmentPaymentFromApi(data);
  }

  /// GET /member/cost-shares — the signed-in member's own shares only.
  Future<List<CostSplitShare>> myCostShares() async {
    final data = await _api.getUri('/member/cost-shares') as List<dynamic>;
    return [
      for (final row in data) costSplitShareFromApi(row as Map<dynamic, dynamic>),
    ];
  }
}
