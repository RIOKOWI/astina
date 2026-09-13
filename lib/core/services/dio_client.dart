import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import 'secure_storage.dart';

class DioClient {
  DioClient(this._storage) {
    _dio = Dio(_options);
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_RetryInterceptor());
    _dio.interceptors.add(_ApiLoggingInterceptor());
  }

  final SecureStorageService _storage;
  late final Dio _dio;
  static final int _timeoutMs =
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 90000;

  final _options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: Duration(milliseconds: _timeoutMs),
    receiveTimeout: Duration(milliseconds: _timeoutMs),
    sendTimeout: Duration(milliseconds: _timeoutMs),
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

class _RetryInterceptor extends Interceptor {
  static final int _retryCount =
      int.tryParse(dotenv.env['API_RETRY'] ?? '') ?? 3;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final extra = err.requestOptions.extra;
      final attempt = (extra['_retry_count'] as int?) ?? 0;

      if (attempt < _retryCount) {
        final delay = Duration(milliseconds: (attempt + 1) * 1000);
        err.requestOptions.extra['_retry_count'] = attempt + 1;

        if (kDebugMode) {
          _log.d(
            '╠🔄 Retrying ($attempt + 1 / $_retryCount) in ${delay.inSeconds}s...',
          );
        }
        await Future.delayed(delay);

        try {
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(e as DioException);
          return;
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (err.response != null) {
      final status = err.response!.statusCode;
      if (status != null && status >= 400 && status < 500) {
        return false;
      }
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      default:
        return true;
    }
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

String _errorType(DioException err) {
  if (err.response != null) {
    return 'HTTP ${err.response!.statusCode}';
  }

  final rawError = '${err.message ?? ''} ${err.error ?? ''}'.toLowerCase();

  switch (err.type) {
    case DioExceptionType.connectionTimeout:
      return 'CONNECTION TIMEOUT';
    case DioExceptionType.sendTimeout:
      return 'SEND TIMEOUT';
    case DioExceptionType.receiveTimeout:
      return 'RECEIVE TIMEOUT';
    case DioExceptionType.connectionError:
      return 'CONNECTION ERROR (no response from server)';
    case DioExceptionType.cancel:
      return 'REQUEST CANCELLED';
    case DioExceptionType.badCertificate:
      return 'BAD CERTIFICATE';
    case DioExceptionType.badResponse:
      return 'BAD RESPONSE';
    case DioExceptionType.transformTimeout:
      return 'TRANSFORM TIMEOUT';
    case DioExceptionType.unknown:
      if (rawError.contains('handshake')) return 'HANDSHAKE ERROR (TLS/SSL)';
      if (rawError.contains('socket') ||
          rawError.contains('connection refused')) {
        return 'NETWORK ERROR';
      }
      if (rawError.isEmpty) return 'UNKNOWN (DioExceptionType.unknown)';
      return 'UNKNOWN';
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

    final errType = _errorType(err);

    _log.e(
      '╔══ API ERROR ══════════════════════════════════════\n'
      '╠✕ $status $method $path ($duration ms)\n'
      '╠ Error: ${err.message ?? err.error ?? 'null'}\n'
      '╠ Type: $errType\n'
      '$errData\n'
      '╚═══════════════════════════════════════════════════',
    );

    handler.next(err);
  }
}
