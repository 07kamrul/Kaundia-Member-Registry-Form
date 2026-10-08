import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/utils/file_utils.dart';
import '../domain/registration_payload_mapper.dart';
import '../domain/registration_form.dart';
import '../domain/submission_error_mapper.dart';

/// Submit result: the 201 body carries `id`/`status` (no success flag).
class SubmissionResult {
  const SubmissionResult({required this.id});
  final String id;
}

/// Multipart submit mirroring Angular registration.service.ts: a single
/// 'payload' JSON field + member_photo + receipt_photo + doc_files[] whose
/// order matches each property's applicable_docs flattened in property order.
class RegistrationRepository {
  RegistrationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<SubmissionResult> submit(
    RegistrationForm form, {
    required String admissionFee,
    required String subscription,
  }) async {
    final payload = buildRegistrationPayload(form, admissionFee: admissionFee, subscription: subscription);

    final formData = FormData();
    formData.fields.add(MapEntry('payload', jsonEncode(payload)));

    // Images were compressed at pick time (prepareImage in the bloc); docs and
    // the receipt pass through the ≤5MB/mime guard here.
    if (form.memberPhoto?.hasFile ?? false) {
      formData.files.add(MapEntry(
        'member_photo',
        toMultipart(await prepareAnyFile(form.memberPhoto!.path!, form.memberPhoto!.fileName ?? 'photo.jpg')),
      ));
    }
    if (form.receiptFile?.hasFile ?? false) {
      formData.files.add(MapEntry(
        'receipt_photo',
        toMultipart(await prepareAnyFile(form.receiptFile!.path!, form.receiptFile!.fileName ?? 'receipt.jpg')),
      ));
    }
    for (final property in form.properties) {
      for (final doc in property.applicableDocs) {
        if (doc.hasFile) {
          formData.files.add(MapEntry(
            'doc_files',
            toMultipart(await prepareAnyFile(doc.path!, doc.fileName.isNotEmpty ? doc.fileName : 'document')),
          ));
        }
      }
    }

    try {
      // Raw dio call so a 409 duplicate body ({detail:{code,message}}) and the
      // 422 detail list stay reachable for precise error mapping.
      final res = await _apiClient.dio.post('/submissions', data: formData);
      final data = res.data;
      return SubmissionResult(
        id: data is Map && data['id'] != null ? data['id'].toString() : '',
      );
    } on DioException catch (e) {
      throw _mapSubmitError(e);
    }
  }

  /// Maps a failed submit to the shapes the domain mapper/duplicate handler
  /// expect (mirrors what the Angular mapper reads off HttpErrorResponse).
  ApiException _mapSubmitError(DioException e) {
    final response = e.response;
    final code = response?.statusCode;
    final data = response?.data;

    if (code == 409 && data is Map) {
      final detail = data['detail'];
      if (detail is Map) {
        final kind = detail['code'] == 'ALREADY_REGISTERED'
            ? DuplicateSubmissionKind.alreadyRegistered
            : DuplicateSubmissionKind.applicationPending;
        throw DuplicateSubmissionException(
          kind,
          (detail['message'] ?? '').toString(),
        );
      }
    }

    final apiError = ApiException.fromDio(e);

    // Normalize 422 field errors to 'root' / 'root.index' keys so the domain
    // mapper can localize them (Angular detail.errors shape: {field, code}).
    if (code == 422 && data is Map) {
      final fieldErrors = _extractFieldErrors(data);
      if (fieldErrors.isNotEmpty) {
        return ApiException(
          type: ApiExceptionType.validation,
          statusCode: code,
          fieldErrors: fieldErrors,
        );
      }
    }

    // Business 400s whose body carries a code (FEE_NOT_CONFIGURED etc.).
    if (code == 400 && data is Map) {
      final detail = data['detail'];
      if (detail is Map && detail['code'] is String) {
        return ApiException(
          type: ApiExceptionType.business,
          statusCode: code,
          businessMessage: detail['code'] as String,
        );
      }
    }

    return apiError;
  }

  /// Accepts both the Angular shape {detail:{errors:[{field, code}]}} and the
  /// FastAPI shape {detail:[{loc:[..], msg}]}. Keys become 'root' or
  /// 'root.index' (snake_case preserved).
  Map<String, String> _extractFieldErrors(Map data) {
    final result = <String, String>{};
    final detail = data['detail'];

    void addField(String field, String value) {
      final segments = field.split('.');
      // root[.index]... keep root + first numeric index if present.
      if (segments.length == 1) {
        result.putIfAbsent(segments.first, () => value);
      } else {
        final indexPos = segments.indexWhere((s) => RegExp(r'^\d+$').hasMatch(s));
        final key = indexPos > 0 ? '${segments.first}.${segments[indexPos]}' : segments.first;
        result.putIfAbsent(key, () => value);
      }
    }

    if (detail is Map && detail['errors'] is List) {
      for (final item in detail['errors'] as List) {
        if (item is Map && item['field'] is String) {
          addField(item['field'] as String, (item['code'] ?? 'invalid').toString());
        }
      }
    } else if (detail is List) {
      for (final item in detail) {
        if (item is Map && item['loc'] is List && item['msg'] is String) {
          final loc = (item['loc'] as List).skip(1).map((s) => s.toString()).toList(); // drop 'body'
          if (loc.isNotEmpty) addField(loc.join('.'), item['msg'] as String);
        }
      }
    }
    return result;
  }
}
