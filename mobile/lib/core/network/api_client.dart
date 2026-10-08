import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin dio wrapper: Bearer token attach, 401 -> onUnauthorized callback
/// (mirrors Angular auth.interceptor.ts), error mapping to [ApiException].
class ApiClient {
  ApiClient({
    required TokenProvider tokenProvider,
    required void Function() onUnauthorized,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            validateStatus: (status) => status != null && status >= 200 && status < 300,
          ),
        )
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ));
    if (kDebugMode && AppConfig.flavor == 'dev') {
      _dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
    }
  }

  final TokenProvider _tokenProvider;
  final void Function() _onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<dynamic> getUri(
    String path, {
    Map<String, dynamic>? query,
    ResponseType responseType = ResponseType.json,
  }) async {
    try {
      final res = await _dio.get<PathSegment>(
        path,
        queryParameters: query,
        options: Options(responseType: responseType),
      );
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> post(
    String path,
    dynamic body, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.post(path, data: body, queryParameters: query);
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> put(
    String path,
    dynamic body, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.put(path, data: body, queryParameters: query);
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> patch(String path, dynamic body) async {
    try {
      final res = await _dio.patch(path, data: body);
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  /// Multipart upload mirroring the Angular FormData submissions.
  Future<dynamic> postMultipart(
    String path,
    FormData formData,
  ) async {
    try {
      final res = await _dio.post(path, data: formData);
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> putMultipart(String path, FormData formData) async {
    try {
      final res = await _dio.put(path, data: formData);
      return res.data;
    } catch (e) {
      throw _map(e);
    }
  }

  /// Blob download (PDFs, attachments).
  Future<List<int>> downloadBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data ?? const [];
    } catch (e) {
      throw _map(e);
    }
  }

  ApiException _map(Object e) {
    final mapped = ApiException.fromDio(e);
    if (mapped.isUnauthorized) _onUnauthorized();
    return mapped;
  }
}

typedef TokenProvider = Future<String?> Function();
typedef PathSegment = dynamic;
