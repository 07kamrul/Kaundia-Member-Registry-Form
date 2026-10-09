/// Typed API errors, mapped from dio failures. 422 field errors carry a
/// snake_case field -> message map so the UI can jump to the offending step.
class ApiException implements Exception {
  const ApiException({
    required this.type,
    this.message,
    this.fieldErrors = const {},
    this.statusCode,
    this.businessMessage,
    this.errorCode,
  });

  final ApiExceptionType type;
  final String? message;

  /// Machine-readable code from a structured FastAPI `detail`
  /// (`{"detail": {"code": "...", "message": "..."}}`); null otherwise.
  final String? errorCode;

  /// 422-style errors: raw (snake_case) field name -> localized message key/raw text.
  final Map<String, String> fieldErrors;

  final int? statusCode;

  /// 400 business errors (e.g. duplicate NID) surfaced near the relevant field.
  final String? businessMessage;

  bool get isNetwork => type == ApiExceptionType.network;
  bool get isUnauthorized => type == ApiExceptionType.unauthorized;
  bool get isValidation => type == ApiExceptionType.validation;
  bool get isBusiness => type == ApiExceptionType.business;
  bool get isServer => type == ApiExceptionType.server;

  static ApiException fromDio(Object error) {
    final dioError = error as dynamic;
    final response = dioError.response as dynamic;
    final code = response?.statusCode as int?;
    if (response == null) {
      return const ApiException(type: ApiExceptionType.network);
    }
    final data = response.data;
    if (code == 422) {
      return ApiException(
        type: ApiExceptionType.validation,
        statusCode: code,
        fieldErrors: _extractFieldErrors(data),
        message: _extractDetail(data),
        errorCode: _extractCode(data),
      );
    }
    if (code == 401) {
      return ApiException(
        type: ApiExceptionType.unauthorized,
        statusCode: code,
        message: _extractDetail(data),
        errorCode: _extractCode(data),
      );
    }
    if (code == 400) {
      return ApiException(
        type: ApiExceptionType.business,
        statusCode: code,
        businessMessage: _extractDetail(data),
        errorCode: _extractCode(data),
      );
    }
    return ApiException(
      type: ApiExceptionType.server,
      statusCode: code,
      message: _extractDetail(data),
      errorCode: _extractCode(data),
    );
  }

  /// `{"detail": {"code": "SOME_CODE", ...}}` -> "SOME_CODE".
  static String? _extractCode(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is! Map) return null;
    final code = detail['code'];
    return code is String && code.isNotEmpty ? code : null;
  }

  static String? _extractDetail(dynamic data) {
    if (data is Map) {
      final detail = data['detail'] ?? data['message'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) return first['msg'] as String;
      }
    }
    return null;
  }

  /// FastAPI 422 `detail` is a list of {loc: [.., field], msg}. The last loc
  /// entry is the snake_case field name.
  static Map<String, String> _extractFieldErrors(dynamic data) {
    final result = <String, String>{};
    if (data is! Map) return result;
    final detail = data['detail'];
    if (detail is List) {
      for (final item in detail) {
        if (item is Map) {
          final loc = item['loc'];
          final msg = item['msg'];
          if (loc is List && loc.isNotEmpty && msg is String) {
            final field = loc.last.toString();
            result.putIfAbsent(field, () => msg);
          }
        }
      }
    } else if (detail is Map) {
      detail.forEach((k, v) {
        if (k is String && v != null) result[k] = v.toString();
      });
    }
    return result;
  }
}

enum ApiExceptionType { network, unauthorized, validation, business, server, unknown }
