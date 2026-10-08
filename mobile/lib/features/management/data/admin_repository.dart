import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_mappers.dart';
import '../../domain/finance_entities.dart';
import '../../domain/finance_mappers.dart';

/// Admin portal endpoints (mirrors Angular AdminService.ts). All payloads are
/// snake_case; ids become String client-side.
class AdminRepository {
  AdminRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  static const _base = '/admin';

  List<Map<String, dynamic>> _rows(dynamic data) =>
      data is List ? data.whereType<Map>().map(Map<String, dynamic>.from).toList() : const [];

  // ----- Submissions -----

  Future<List<SubmissionSummary>> listSubmissions({SubmissionStatus? status}) async {
    final data = await _api.getUri('$_base/submissions', query: {
      if (status != null && status != SubmissionStatus.unknown) 'status': status.apiName,
    });
    return _rows(data).map((r) => r.toSummaryEntity()).toList(growable: false);
  }

  Future<SubmissionDetail> getSubmission(String id) async {
    final data = await _api.getUri('$_base/submissions/$id');
    return Map<String, dynamic>.from(data as Map).toDetailEntity();
  }

  /// kind: 'member_photo' | 'receipt_photo'. Returns the refreshed submission.
  Future<SubmissionDetail> replaceAttachment(String id, String kind, String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final data = await _api.putMultipart('$_base/submissions/$id/attachments/$kind', form);
    return Map<String, dynamic>.from(data as Map).toDetailEntity();
  }

  Future<SubmissionDetail> replaceDocument(String id, String docId, String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final data = await _api.putMultipart('$_base/submissions/$id/documents/$docId', form);
    return Map<String, dynamic>.from(data as Map).toDetailEntity();
  }

  /// Returns the approved member_id.
  Future<String> approveSubmission(String id) async {
    final data = await _api.post('$_base/submissions/$id/approve', {});
    return '${(data as Map)['member_id']}';
  }

  /// Returns whether the rejection email was sent.
  Future<bool> rejectSubmission(String id, String reason) async {
    final data = await _api.post('$_base/submissions/$id/reject', {'reason': reason});
    return (data as Map)['email_sent'] == true;
  }

  Future<bool> resendRejectionNotification(String id) async {
    final data = await _api.post('$_base/submissions/$id/resend-notification', {});
    return (data as Map)['email_sent'] == true;
  }

  // ----- Property requests -----

  Future<List<MemberPropertyRequest>> listPropertyRequests({PropertyRequestStatus? status}) async {
    final data = await _api.getUri('$_base/property-requests', query: {
      if (status != null && status != PropertyRequestStatus.unknown) 'status': status.name,
    });
    return _rows(data).map((r) => r.toPropertyRequestEntity()).toList(growable: false);
  }

  Future<MemberPropertyRequest> approvePropertyRequest(int id) async {
    final data = await _api.post('$_base/property-requests/$id/approve', {});
    return Map<String, dynamic>.from(data as Map).toPropertyRequestEntity();
  }

  Future<MemberPropertyRequest> cancelPropertyRequest(int id, String reason) async {
    final data = await _api.post('$_base/property-requests/$id/cancel', {'reason': reason});
    return Map<String, dynamic>.from(data as Map).toPropertyRequestEntity();
  }

  // ----- Members -----

  Future<List<Member>> listMembers() async {
    final data = await _api.getUri('$_base/members');
    return _rows(data).map((r) => r.toMemberEntity()).toList(growable: false);
  }

  Future<MemberProfile> getMemberProfile(String id) async {
    final data = await _api.getUri('$_base/members/$id');
    return Map<String, dynamic>.from(data as Map).toProfileEntity();
  }

  Future<List<Installment>> getMemberInstallments(String memberId) async {
    final data = await _api.getUri('$_base/members/$memberId/installments');
    return _rows(data).map((r) => r.toInstallmentEntity()).toList(growable: false);
  }

  Future<void> deleteMember(String memberId) => _api.delete('$_base/members/$memberId');

  /// Returns whether the notification email was sent.
  Future<bool> resetMemberPassword(String memberId) async {
    final data = await _api.post('$_base/members/$memberId/reset-password', {});
    return (data as Map)['email_sent'] == true;
  }

  // ----- Installments -----

  /// status: 'paid' | 'due'.
  Future<Installment> updateInstallment(String id, String status) async {
    final data = await _api.patch('$_base/installments/$id', {'status': status});
    return Map<String, dynamic>.from(data as Map).toInstallmentEntity();
  }

  // ----- Picnic payments -----

  Future<PicnicPaymentsPage> getPicnicPayments({
    int? memberId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final data = await _api.getUri('$_base/picnic-payments', query: {
      if (memberId != null) 'member_id': '$memberId',
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Map<String, dynamic>.from(data as Map).toPicnicPageEntity();
  }

  // ----- Fee settings -----

  Future<List<FeeSetting>> getActiveFeeSettings() async {
    final data = await _api.getUri('$_base/fee-settings');
    return _rows(data).map((r) => r.toFeeSettingEntity()).toList(growable: false);
  }

  Future<List<FeeSetting>> getFeeSettingHistory(String key) async {
    final data = await _api.getUri('$_base/fee-settings/$key/history');
    return _rows(data).map((r) => r.toFeeSettingEntity()).toList(growable: false);
  }

  Future<FeeSetting> createFeeSettingVersion({
    required String key,
    required num value,
    String? unit,
    String? startDate,
  }) async {
    final data = await _api.post('$_base/fee-settings', {
      'key': key,
      'value': value,
      if (unit != null && unit.isNotEmpty) 'unit': unit,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
    });
    return Map<String, dynamic>.from(data as Map).toFeeSettingEntity();
  }

  // ----- Config lists -----

  Future<List<ConfigListItem>> listConfigListItems(String category) async {
    final data = await _api.getUri('$_base/config-lists', query: {'category': category});
    return _rows(data).map((r) => r.toConfigItemEntity()).toList(growable: false);
  }

  Future<ConfigListItem> createConfigListItem({
    required String category,
    required String value,
    required String label,
    int sortOrder = 0,
  }) async {
    final data = await _api.post('$_base/config-lists', {
      'category': category,
      'value': value,
      'label': label,
      'sort_order': sortOrder,
    });
    return Map<String, dynamic>.from(data as Map).toConfigItemEntity();
  }

  Future<ConfigListItem> updateConfigListItem(
    String id, {
    String? label,
    int? sortOrder,
    bool? isActive,
  }) async {
    final data = await _api.patch('$_base/config-lists/$id', {
      if (label != null) 'label': label,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    });
    return Map<String, dynamic>.from(data as Map).toConfigItemEntity();
  }

  // ----- Notices / events (management CRUD, full-record bodies) -----

  Future<List<Notice>> listNotices({bool? published, String? categoryId}) async {
    final data = await _api.getUri('$_base/notices', query: {
      if (published != null) 'published': '$published',
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
    });
    return _rows(data).map((r) => r.toNoticeEntity()).toList(growable: false);
  }

  Map<String, dynamic> _noticeBody(NoticeInput n) => {
        'title': n.title,
        'body': n.body,
        'category_id': n.categoryId == null || n.categoryId!.isEmpty
            ? null
            : int.tryParse(n.categoryId!),
        'is_published': n.isPublished,
        'is_members_only': n.isMembersOnly,
        'publish_at': n.publishAt,
      };

  Future<Notice> createNotice(NoticeInput payload) async {
    final data = await _api.post('$_base/notices', _noticeBody(payload));
    return Map<String, dynamic>.from(data as Map).toNoticeEntity();
  }

  Future<Notice> updateNotice(String id, NoticeInput payload) async {
    final data = await _api.patch('$_base/notices/$id', _noticeBody(payload));
    return Map<String, dynamic>.from(data as Map).toNoticeEntity();
  }

  Future<void> deleteNotice(String id) => _api.delete('$_base/notices/$id');

  Future<List<EventItem>> listEvents({bool? published, String? categoryId}) async {
    final data = await _api.getUri('$_base/events', query: {
      if (published != null) 'published': '$published',
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
    });
    return _rows(data).map((r) => r.toEventEntity()).toList(growable: false);
  }

  Map<String, dynamic> _eventBody(EventInput e) => {
        'title': e.title,
        'description': e.description,
        'location': e.location,
        'category_id':
            e.categoryId == null || e.categoryId!.isEmpty ? null : int.tryParse(e.categoryId!),
        'start_at': e.startAt,
        'end_at': e.endAt,
        'is_published': e.isPublished,
        'is_members_only': e.isMembersOnly,
      };

  Future<EventItem> createEvent(EventInput payload) async {
    final data = await _api.post('$_base/events', _eventBody(payload));
    return Map<String, dynamic>.from(data as Map).toEventEntity();
  }

  Future<EventItem> updateEvent(String id, EventInput payload) async {
    final data = await _api.patch('$_base/events/$id', _eventBody(payload));
    return Map<String, dynamic>.from(data as Map).toEventEntity();
  }

  Future<void> deleteEvent(String id) => _api.delete('$_base/events/$id');
}

/// Fields a notice is created/edited with (ISO instants, UTC).
class NoticeInput {
  const NoticeInput({
    required this.title,
    required this.body,
    this.categoryId,
    this.isPublished = false,
    this.isMembersOnly = false,
    this.publishAt,
  });

  final String title;
  final String body;
  final String? categoryId;
  final bool isPublished;
  final bool isMembersOnly;
  final String? publishAt;
}

class EventInput {
  const EventInput({
    required this.title,
    required this.startAt,
    this.description,
    this.location,
    this.categoryId,
    this.endAt,
    this.isPublished = false,
    this.isMembersOnly = false,
  });

  final String title;
  final String? description;
  final String? location;
  final String? categoryId;
  final String startAt;
  final String? endAt;
  final bool isPublished;
  final bool isMembersOnly;
}

// ----- Finance (admin side) -----

class FinanceRepository {
  FinanceRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  static const _admin = '/admin/finance';

  Map<String, String> _filterParams({
    FinanceType? type,
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    num? minAmount,
    num? maxAmount,
    String? reference,
    String? search,
    int? limit,
    int? offset,
  }) =>
      {
        if (type != null && type != FinanceType.unknown) 'type': type.apiName,
        if (categoryId != null) 'category_id': '$categoryId',
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        if (minAmount != null) 'min_amount': '$minAmount',
        if (maxAmount != null) 'max_amount': '$maxAmount',
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (search != null && search.isNotEmpty) 'search': search,
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      };

  Future<FinanceLedgerPage> adminTransactions({
    FinanceStatus? status,
    bool? includeInactive,
    FinanceType? type,
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? limit,
    int? offset,
  }) async {
    final query = _filterParams(
      type: type,
      categoryId: categoryId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
      limit: limit,
      offset: offset,
    );
    if (status != null && status != FinanceStatus.unknown) query['status'] = status.apiName;
    if (includeInactive == true) query['include_inactive'] = 'true';
    final data = await _api.getUri('$_admin/transactions', query: query);
    return Map<String, dynamic>.from(data as Map).toLedgerEntity();
  }

  Map<String, dynamic> _inputBody(FinanceTransactionInput input) => {
        'txn_date': input.txnDate,
        'type': input.type.apiName,
        'category_id': input.categoryId,
        'amount': input.amount,
        'description': input.description,
        'reference_no': (input.referenceNo ?? '').isEmpty ? null : input.referenceNo,
        'internal_notes': (input.internalNotes ?? '').isEmpty ? null : input.internalNotes,
        if (input.status != null) 'status': input.status!.apiName,
        'linked_payment_type': input.linkedPaymentType?.apiName,
        'linked_payment_id': input.linkedPaymentId,
      };

  Future<FinanceTransaction> createTransaction(FinanceTransactionInput input) async {
    final data = await _api.post('$_admin/transactions', _inputBody(input));
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  Future<FinanceTransaction> updateTransaction(int id, FinanceTransactionInput changes) async {
    final data = await _api.patch('$_admin/transactions/$id', _inputBody(changes));
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  Future<FinanceTransaction> uploadAttachment(int id, String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final data = await _api.put('$_admin/transactions/$id/attachment', form);
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  Future<FinanceTransaction> submitTransaction(int id) async {
    final data = await _api.post('$_admin/transactions/$id/submit', {});
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  Future<FinanceTransaction> approveTransaction(int id) async {
    final data = await _api.post('$_admin/transactions/$id/approve', {});
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  Future<FinanceTransaction> rejectTransaction(int id, String reason) async {
    final data = await _api.post('$_admin/transactions/$id/reject', {'reason': reason});
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  Future<FinanceTransaction> reverseTransaction(int id, String reason) async {
    final data = await _api.post('$_admin/transactions/$id/reverse', {'reason': reason});
    return Map<String, dynamic>.from(data as Map).toTransactionEntity();
  }

  /// DELETE carries a {reason} body (mirrors Angular HttpClient.request DELETE).
  Future<void> deleteTransaction(int id, String reason) async {
    await _api.dio.delete('$_admin/transactions/$id', data: {'reason': reason});
  }

  Future<List<FinanceCategory>> categories() async {
    final data = await _api.getUri('$_admin/categories');
    return (data as List)
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r).toCategoryEntity())
        .toList(growable: false);
  }

  Future<FinanceOverview> overview() async {
    final data = await _api.getUri('$_admin/overview');
    return Map<String, dynamic>.from(data as Map).toOverviewEntity();
  }

  Future<List<UnlinkedPayment>> unlinkedPayments({
    PaymentSourceType? sourceType,
    String? search,
    int limit = 50,
  }) async {
    final data = await _api.getUri('$_admin/unlinked-payments', query: {
      'limit': '$limit',
      if (sourceType != null && sourceType != PaymentSourceType.unknown)
        'source_type': sourceType.apiName,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (data as List)
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r).toUnlinkedPaymentEntity())
        .toList(growable: false);
  }

  Future<void> publishReportNotice(FinancePeriod period, {String? dateFrom, String? dateTo}) =>
      _api.post('$_admin/publish-report-notice', {
        'period': period.name,
        'date_from': dateFrom,
        'date_to': dateTo,
      });
}

// ----- Installment payment verification -----

class InstallmentPaymentRepository {
  InstallmentPaymentRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  static const _base = '/admin/installment-payments';

  Future<List<AdminInstallmentPayment>> listForAdmin({String? status}) async {
    final data = await _api.getUri(_base, query: {if (status != null) 'status': status});
    return (data as List)
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r).toAdminPaymentEntity())
        .toList(growable: false);
  }

  Future<int> pendingCount() async {
    final data = await _api.getUri('$_base/pending-count');
    return ((data as Map)['count'] as num?)?.toInt() ?? 0;
  }

  Future<AdminInstallmentPayment> approve(int id) async {
    final data = await _api.post('$_base/$id/approve', {});
    return Map<String, dynamic>.from(data as Map).toAdminPaymentEntity();
  }

  Future<AdminInstallmentPayment> reject(int id, String reason) async {
    final data = await _api.post('$_base/$id/reject', {'reason': reason});
    return Map<String, dynamic>.from(data as Map).toAdminPaymentEntity();
  }
}

// ----- Society costs -----

class SocietyCostRepository {
  SocietyCostRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  static const _base = '/admin';

  Future<List<SocietyCost>> listCosts({
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    CostPaymentSource? paymentSource,
    bool? billed,
    String? search,
  }) async {
    final data = await _api.getUri('$_base/society-costs', query: {
      if (categoryId != null) 'category_id': '$categoryId',
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      if (paymentSource != null && paymentSource != CostPaymentSource.unknown)
        'payment_source': paymentSource.apiName,
      if (billed != null) 'billed': '$billed',
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (data as List)
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r).toCostEntity())
        .toList(growable: false);
  }

  Map<String, dynamic> _costBody(SocietyCostInput input) => {
        'title': input.title,
        'description': input.description,
        'category_id': input.categoryId,
        'total_amount': input.totalAmount,
        'incurred_date': input.incurredDate,
        'payment_source': input.paymentSource.apiName,
        'notes': input.notes,
      };

  Future<SocietyCost> createCost(SocietyCostInput input) async {
    final data = await _api.post('$_base/society-costs', _costBody(input));
    return Map<String, dynamic>.from(data as Map).toCostEntity();
  }

  Future<SocietyCost> updateCost(int id, SocietyCostInput input) async {
    final data = await _api.patch('$_base/society-costs/$id', _costBody(input));
    return Map<String, dynamic>.from(data as Map).toCostEntity();
  }

  Future<void> deleteCost(int id) => _api.delete('$_base/society-costs/$id');

  Future<SocietyCost> uploadReceipt(int id, String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final data = await _api.putMultipart('$_base/society-costs/$id/receipt', form);
    return Map<String, dynamic>.from(data as Map).toCostEntity();
  }

  /// dryRun=true returns the computed shares without saving anything; a confirm
  /// run returns the saved [SocietyCost]. Returns preview rows when dryRun.
  Future<dynamic> splitCost(
    int id, {
    required CostSplitMethod splitMethod,
    List<({int memberId, num amountDue})> manualShares = const [],
    bool allowMismatch = false,
    bool dryRun = false,
  }) async {
    final data = await _api.post('$_base/society-costs/$id/split', {
      'split_method': splitMethod.apiName,
      if (manualShares.isNotEmpty)
        'manual_shares': [
          for (final m in manualShares) {'member_id': m.memberId, 'amount_due': m.amountDue},
        ],
      if (splitMethod == CostSplitMethod.manual) 'allow_mismatch': allowMismatch,
      if (dryRun) 'dry_run': true,
    });
    if (data is List) {
      return data
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r).toSplitPreviewRowEntity())
          .toList(growable: false);
    }
    return Map<String, dynamic>.from(data as Map).toCostEntity();
  }

  Future<CostSplitShare> recordSharePayment(
    int shareId, {
    required num amountPaid,
    String? receiptNo,
  }) async {
    final data = await _api.patch('$_base/cost-split-shares/$shareId', {
      'amount_paid': amountPaid,
      'receipt_no': (receiptNo ?? '').isEmpty ? null : receiptNo,
    });
    return Map<String, dynamic>.from(data as Map).toShareEntity();
  }

  Future<SocietyCostSummary> getSummary({String? dateFrom, String? dateTo}) async {
    final data = await _api.getUri('$_base/society-costs/summary', query: {
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Map<String, dynamic>.from(data as Map).toSummaryEntity();
  }
}

// ----- Roadmap management -----

class RoadmapRepository {
  RoadmapRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  static const _base = '/admin/roadmap';

  Future<Roadmap> getRoadmap() async {
    final data = await _api.getUri('/roadmap');
    return Map<String, dynamic>.from(data as Map).toRoadmapEntity();
  }

  Future<Roadmap> createItem({
    required int timeframeId,
    required String text,
    RoadmapStatus status = RoadmapStatus.planned,
    String? targetDate,
    String? owner,
    String? note,
    bool notify = true,
  }) async {
    final data = await _api.post('$_base/items', {
      'timeframe_id': timeframeId,
      'text': text,
      'status': status.apiName,
      'target_date': (targetDate ?? '').isEmpty ? null : targetDate,
      'owner': (owner ?? '').isEmpty ? null : owner,
      'note': (note ?? '').isEmpty ? null : note,
      'notify': notify,
    });
    return Map<String, dynamic>.from(data as Map).toRoadmapEntity();
  }

  Future<Roadmap> updateItem(
    int id, {
    int? timeframeId,
    String? text,
    String? targetDate,
    String? owner,
    String? note,
  }) async {
    final body = <String, dynamic>{
      if (timeframeId != null) 'timeframe_id': timeframeId,
      if (text != null) 'text': text,
      if (targetDate != null) 'target_date': targetDate.isEmpty ? null : targetDate,
      if (owner != null) 'owner': owner.isEmpty ? null : owner,
      if (note != null) 'note': note.isEmpty ? null : note,
    };
    final data = await _api.put('$_base/items/$id', body);
    return Map<String, dynamic>.from(data as Map).toRoadmapEntity();
  }

  Future<Roadmap> setStatus(int id, RoadmapStatus status, {bool notify = true}) async {
    final data = await _api.post('$_base/items/$id/status', {
      'status': status.apiName,
      'notify': notify,
    });
    return Map<String, dynamic>.from(data as Map).toRoadmapEntity();
  }

  Future<Roadmap> deleteItem(int id) async {
    final data = await _api.delete('$_base/items/$id');
    return Map<String, dynamic>.from(data as Map).toRoadmapEntity();
  }

  Future<Roadmap> reorder(int timeframeId, List<int> itemIds) async {
    final data = await _api.post('$_base/reorder', {
      'timeframe_id': timeframeId,
      'item_ids': itemIds,
    });
    return Map<String, dynamic>.from(data as Map).toRoadmapEntity();
  }

  Future<int> archive({required bool onlyDone}) async {
    final data = await _api.post('$_base/archive', null, query: {'only_done': '$onlyDone'});
    return ((data as Map)['archived'] as num?)?.toInt() ?? 0;
  }

  Future<List<RoadmapArchivedCycle>> getArchive() async {
    final data = await _api.getUri('$_base/archive');
    return (data as List)
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r).toCycleEntity())
        .toList(growable: false);
  }
}
