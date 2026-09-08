import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.errors, this.statusCode});
  final String message;
  final Map<String, List<String>>? errors;
  final int? statusCode;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<(String token, UserModel user)> login({
    required String phone,
    required String password,
  }) async {
    if (kDebugMode) {
      developer.log('Attempting login', name: 'Auth');
    }
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {'phone': phone, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ApiException(
          data['message'] as String? ?? 'Login gagal.',
          statusCode: response.statusCode,
        );
      }
      final payload = data['data'] as Map<String, dynamic>;
      final token = payload['token'] as String;
      final user = UserModel.fromJson(payload['user'] as Map<String, dynamic>);
      if (kDebugMode) {
        developer.log('Login successful for user: ${user.id}', name: 'Auth');
      }
      return (token, user);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> logout() async {
    if (kDebugMode) {
      developer.log('Attempting logout', name: 'Auth');
    }
    try {
      await _dioClient.post(ApiConstants.logout);
      if (kDebugMode) {
        developer.log('Logout successful', name: 'Auth');
      }
    } on DioException catch (e) {
      // Logout endpoint returns 204 on success, 401 if already unauthenticated
      if (e.response?.statusCode == 401) {
        if (kDebugMode) {
          developer.log('Logout: already unauthenticated', name: 'Auth');
        }
        return;
      }
      _handleDioError(e);
    }
  }

  Future<UserModel> getMe() async {
    if (kDebugMode) {
      developer.log('Fetching current user', name: 'Auth');
    }
    try {
      final response = await _dioClient.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ApiException(
          data['message'] as String? ?? 'Gagal mengambil data user.',
          statusCode: response.statusCode,
        );
      }
      final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
      if (kDebugMode) {
        developer.log('User fetched: ${user.id}', name: 'Auth');
      }
      return user;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<UserModel> updateMe({
    String? phone,
    String? email,
    String? currentPassword,
  }) async {
    if (kDebugMode) {
      developer.log('Updating account', name: 'Auth');
    }
    try {
      final body = <String, dynamic>{};
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;
      if (currentPassword != null) body['current_password'] = currentPassword;

      final response = await _dioClient.patch(ApiConstants.me, data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ApiException(
          data['message'] as String? ?? 'Gagal update akun.',
          errors: _parseErrors(data),
          statusCode: response.statusCode,
        );
      }
      final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
      if (kDebugMode) {
        developer.log('Account updated: ${user.id}', name: 'Auth');
      }
      return user;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    if (kDebugMode) {
      developer.log('Changing password', name: 'Auth');
    }
    try {
      final response = await _dioClient.patch(
        ApiConstants.password,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': passwordConfirmation,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ApiException(
          data['message'] as String? ?? 'Gagal ubah password.',
          errors: _parseErrors(data),
          statusCode: response.statusCode,
        );
      }
      if (kDebugMode) {
        developer.log('Password changed successfully', name: 'Auth');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (statusCode == 401) {
      throw const ApiException(
        'Sesi habis. Silakan login ulang.',
        statusCode: 401,
      );
    }
    if (statusCode == 422 && data is Map<String, dynamic>) {
      throw ApiException(
        data['message'] as String? ?? 'Validasi gagal.',
        errors: _parseErrors(data),
        statusCode: 422,
      );
    }
    if (statusCode == 422 && data == null) {
      // Laravel-style validation error without full structure
      throw const ApiException('Validasi gagal.', statusCode: 422);
    }

    throw ApiException(
      e.message ?? 'Terjadi kesalahan. Silakan coba lagi.',
      statusCode: statusCode,
    );
  }

  Map<String, List<String>>? _parseErrors(Map<String, dynamic> data) {
    final errorsRaw = data['errors'];
    if (errorsRaw is! Map<String, dynamic>) return null;
    return errorsRaw.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((e) => e.toString()).toList());
      }
      return MapEntry(key, [value.toString()]);
    });
  }
}
