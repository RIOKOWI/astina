import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import 'secure_storage.dart';

class DioClient {
  DioClient(this._storage) {
    _dio = Dio(_options);
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_ApiLoggingInterceptor());
  }

  final SecureStorageService _storage;
  late final Dio _dio;
  final _options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  );

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  Future<Response<T>> postFormData<T>(String path, {required FormData data}) =>
      _dio.post<T>(
        path,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );

  Future<List<int>> downloadBytes(String path) async {
    final token = await _storage.getToken();
    final response = await _dio.get<List<int>>(
      path,
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': '*/*',
        },
        responseType: ResponseType.bytes,
      ),
    );
    return response.data ?? [];
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);

  final SecureStorageService _storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.clearAll();
    }
    handler.next(err);
  }
}

const _sensitiveKeys = {
  'password',
  'password_confirmation',
  'current_password',
  'token',
  'access_token',
  'refresh_token',
  'authorization',
  'device_token',
  'fcm_token',
  'secret',
  'private_key',
  'client_secret',
  'bearer',
};

const _redacted = '***REDACTED***';
const _maxLogLength = 4000;

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 0, lineLength: 120),
);

dynamic _sanitize(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      if (_sensitiveKeys.any((s) => key.contains(s))) {
        result[entry.key] = _redacted;
      } else if (entry.value is Map || entry.value is List) {
        result[entry.key] = _sanitize(entry.value);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
  if (value is List) {
    return value.map((e) => _sanitize(e)).toList();
  }
  return value;
}

String _prettyJson(dynamic data) {
  try {
    final encoded = jsonEncode(data);
    if (encoded.length > _maxLogLength) {
      return '${encoded.substring(0, _maxLogLength)}\n... <TRUNCATED: ${encoded.length} characters total>';
    }
    final decoded = jsonDecode(encoded);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    return data.toString();
  }
}

String _formatPayload(dynamic data) {
  if (data == null) return 'null';
  if (data is FormData) {
    final fields = <String, dynamic>{};
    for (final field in data.fields) {
      fields[field.key] = field.value;
    }
    final files = <String>[];
    for (final file in data.files) {
      files.add(
        '${file.key}: {filename: ${file.value.filename}, content_type: ${file.value.contentType}}',
      );
    }
    final sanitized = _sanitize(fields) as Map<String, dynamic>;
    if (files.isNotEmpty) {
      sanitized['_files'] = files;
    }
    return _prettyJson(sanitized);
  }
  return _prettyJson(_sanitize(data));
}

class _ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    options.extra['_started_at'] = DateTime.now().millisecondsSinceEpoch;

    final method = options.method;
    final path = options.path;
    final query = options.queryParameters.isNotEmpty
        ? '\nQuery:\n${_formatPayload(options.queryParameters)}'
        : '';

    if (options.data is FormData) {
      _log.d('╔══ API REQUEST ═══════════════════════════════════');
      _log.d('╠→ $method ${options.baseUrl}$path');
      _log.d('╠ FormData:$query');
      _log.d('╚═══════════════════════════════════════════════════');
    } else if (options.data != null) {
      _log.d('╔══ API REQUEST ═══════════════════════════════════');
      _log.d('╠→ $method ${options.baseUrl}$path$query');
      _log.d('╠ Body:\n${_formatPayload(options.data)}');
      _log.d('╚═══════════════════════════════════════════════════');
    } else {
      _log.d('╔══ API REQUEST ═══════════════════════════════════');
      _log.d('╠→ $method ${options.baseUrl}$path$query');
      _log.d('╚═══════════════════════════════════════════════════');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    final startedAt = response.requestOptions.extra['_started_at'] as int?;
    final duration = startedAt != null
        ? DateTime.now().millisecondsSinceEpoch - startedAt
        : 0;

    final status = response.statusCode ?? 0;
    final method = response.requestOptions.method;
    final path = response.requestOptions.path;

    if (response.data is List<int>) {
      _log.d('╔══ API RESPONSE ════════════════════════════════');
      _log.d('╠← $status $method $path ($duration ms)');
      _log.d('╠ <BINARY RESPONSE OMITTED>');
      _log.d('╚═══════════════════════════════════════════════════');
      handler.next(response);
      return;
    }

    _log.d('╔══ API RESPONSE ══════════════════════════════════');
    _log.d('╠← $status $method $path ($duration ms)');
    _log.d('╠ Response:\n${_formatPayload(response.data)}');
    _log.d('╚═══════════════════════════════════════════════════');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }

    final startedAt = err.requestOptions.extra['_started_at'] as int?;
    final duration = startedAt != null
        ? DateTime.now().millisecondsSinceEpoch - startedAt
        : 0;

    final status = err.response?.statusCode ?? 0;
    final method = err.requestOptions.method;
    final path = err.requestOptions.path;

    final errData = err.response?.data != null
        ? '╠ Response:\n${_formatPayload(err.response?.data)}'
        : '';

    _log.e(
      '╔══ API ERROR ══════════════════════════════════════\n'
      '╠✕ $status $method $path ($duration ms)\n'
      '╠ Error: ${err.message}\n'
      '$errData\n'
      '╚═══════════════════════════════════════════════════',
    );

    handler.next(err);
  }
}
