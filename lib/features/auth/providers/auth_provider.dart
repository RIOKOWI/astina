import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../../../core/services/router_refresh_notifier.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/models/user_model.dart';
import '../../fcm/fcm_provider.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient);
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  const AuthState._({this.user, this.isAuthenticated = false});

  const AuthState.initial() : this._();

  const AuthState.authenticated(UserModel user)
    : this._(user: user, isAuthenticated: true);

  const AuthState.unauthenticated() : this._(isAuthenticated: false);

  final UserModel? user;
  final bool isAuthenticated;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  AuthState build() {
    _initAsync();
    return const AuthState.initial();
  }

  Future<void> _initAsync() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (token == null) {
      if (kDebugMode) {
        developer.log('No token found, unauthenticated', name: 'Auth');
      }
      routerRefreshNotifier.update(const AuthState.unauthenticated());
    }

    // Load cached user immediately
    final cachedUserJson = await storage.getUser();
    UserModel? cachedUser;
    if (cachedUserJson != null) {
      try {
        cachedUser = UserModel.fromJson(
          jsonDecode(cachedUserJson) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    if (cachedUser != null) {
      routerRefreshNotifier.update(AuthState.authenticated(cachedUser));
    } else {
      state = const AsyncValue.data(AuthState.unauthenticated());
      routerRefreshNotifier.update(const AuthState.unauthenticated());
    }

    // Validate token in background
    if (kDebugMode) {
      developer.log('Validating session...', name: 'Auth');
    }
    try {
      final datasource = ref.read(authRemoteDataSourceProvider);
      final user = await datasource.getMe();
      await storage.saveUser(user.toJsonString());
      if (kDebugMode) {
        developer.log('Session valid: ${user.phone}', name: 'Auth');
      }
      routerRefreshNotifier.update(AuthState.authenticated(user));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (kDebugMode) {
          developer.log('Token expired, clearing session', name: 'Auth');
        }
        await storage.deleteToken();
        await storage.clearUser();
        state = const AsyncValue.data(AuthState.unauthenticated());
        routerRefreshNotifier.update(const AuthState.unauthenticated());
      } else if (kDebugMode) {
        developer.log('Session check failed (network)', name: 'Auth', error: e);
      }
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Session check failed',
          name: 'Auth',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (kDebugMode) {
        developer.log('Attempting login: $phone', name: 'Auth');
      }
      final datasource = ref.read(authRemoteDataSourceProvider);
      final storage = ref.read(secureStorageProvider);
      final response = await datasource.login(phone, password);
      await storage.saveToken(response.token);
      await storage.saveUser(response.user.toJsonString());
      if (kDebugMode) {
        developer.log('Login successful: ${response.user.phone}', name: 'Auth');
      }
      // Register FCM token after login
      await registerFcmToken(ref);
      return AuthState.authenticated(response.user);
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final datasource = ref.read(authRemoteDataSourceProvider);
      if (kDebugMode) {
        developer.log('Attempting logout', name: 'Auth');
      }
      await unregisterFcmToken(ref);
      await datasource.logout();
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Logout API failed, clearing local session',
          name: 'Auth',
          error: e,
        );
      }
    } finally {
      final storage = ref.read(secureStorageProvider);
      await storage.clearAll();
      if (kDebugMode) {
        developer.log('Logout complete', name: 'Auth');
      }
      state = const AsyncValue.data(AuthState.unauthenticated());
    }
  }

  Future<void> refreshUser() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.isAuthenticated) return;

    try {
      final datasource = ref.read(authRemoteDataSourceProvider);
      final user = await datasource.getMe();
      final storage = ref.read(secureStorageProvider);
      await storage.saveUser(user.toJsonString());
      state = AsyncValue.data(AuthState.authenticated(user));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (kDebugMode) {
          developer.log('Refresh failed (401), clearing session', name: 'Auth');
        }
        final storage = ref.read(secureStorageProvider);
        await storage.clearAll();
        state = const AsyncValue.data(AuthState.unauthenticated());
      }
    }
  }
}
