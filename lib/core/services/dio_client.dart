import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'secure_storage.dart';

class DioClient {
  DioClient(this._storage) {
    _dio = Dio(_options);
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_LoggingInterceptor());
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

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTime[options] = DateTime.now();
    if (kDebugMode) {
      final method = options.method;
      final path = options.path;
      final query = options.queryParameters.isNotEmpty
          ? '?$options.queryParameters'
          : '';
      developer.log(
        '→ HTTP $method ${options.baseUrl}$path$query',
        name: 'DioClient',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final duration = DateTime.now().difference(
        _requestTime[response.requestOptions] ?? DateTime.now(),
      );
      developer.log(
        '← HTTP ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.path} (${duration.inMilliseconds}ms)',
        name: 'DioClient',
      );
      _requestTime.remove(response.requestOptions);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final duration = DateTime.now().difference(
        _requestTime[err.requestOptions] ?? DateTime.now(),
      );
      final statusCode = err.response?.statusCode?.toString() ?? 'NO_RESPONSE';
      developer.log(
        '← HTTP $statusCode ${err.requestOptions.method} '
        '${err.requestOptions.path} (${duration.inMilliseconds}ms) '
        'ERROR: ${err.message}',
        name: 'DioClient',
        error: err,
      );
      _requestTime.remove(err.requestOptions);
    }
    handler.next(err);
  }

  static final Map<RequestOptions, DateTime> _requestTime = {};
}
