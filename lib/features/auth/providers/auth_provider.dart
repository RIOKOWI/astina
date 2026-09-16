import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../../../core/services/auth_state.dart';
import '../../../core/services/router_refresh_notifier.dart';
import '../../../core/services/secure_storage.dart';
import '../../fcm/fcm_provider.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/models/user_model.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _updateState(const AuthLoading());
    _init();
    return const AuthLoading();
  }

  SecureStorageService get _storage => ref.read(secureStorageProvider);
  AuthRemoteDataSource get _ds => ref.read(authRemoteDataSourceProvider);

  Future<void> _init() async {
    if (kDebugMode) developer.log('Auth: initializing...', name: 'Auth');
    try {
      final token = await _storage.getToken();
      if (token == null) {
        _updateState(const Unauthenticated());
        return;
      }
      final user = await _ds.getMe();
      await _storage.saveUser(user.toJsonString());
      _updateState(Authenticated(user));
      registerFcmToken();
    } catch (e, st) {
      final isUnauthorized = e is DioException && e.response?.statusCode == 401;
      if (kDebugMode) {
        developer.log(
          'Auth init failed: $e${isUnauthorized ? ' (clearing session)' : ' (keeping session)'}',
          name: 'Auth',
          error: e,
          stackTrace: st,
        );
      }
      if (isUnauthorized) {
        await _storage.clearAll();
      }
      _updateState(const Unauthenticated());
    }
  }

  void _updateState(AuthState authState) {
    state = authState;
    routerRefreshNotifier.update(state);
  }

  /// Exposed as protected for test subclassing. Use [_updateState] in production.
  @visibleForTesting
  void updateAuthState(UserModel? user) =>
      _updateState(user != null ? Authenticated(user) : const Unauthenticated());

  Future<void> login({required String phone, required String password}) async {
    if (kDebugMode) developer.log('Auth: login started', name: 'Auth');
    final (token, user) = await _ds.login(phone: phone, password: password);
    await _storage.saveToken(token);
    await _storage.saveUser(user.toJsonString());
    _updateState(Authenticated(user));
    registerFcmToken();
    if (kDebugMode) developer.log('Auth: login success', name: 'Auth');
  }

  Future<void> logout() async {
    if (kDebugMode) developer.log('Auth: logout started', name: 'Auth');
    try {
      await _ds.logout();
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Auth: logout API call failed',
          name: 'Auth',
          error: e,
          stackTrace: st,
        );
      }
    }
    await _storage.clearAll();
    _updateState(const Unauthenticated());
    if (kDebugMode) developer.log('Auth: logged out', name: 'Auth');
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;
    try {
      final user = await _ds.getMe();
      await _storage.saveUser(user.toJsonString());
      _updateState(Authenticated(user));
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Auth: refresh user failed',
          name: 'Auth',
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

enum UserRole { warga, rt, bendahara, unknown }

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final code = ref.watch(authProvider).user?.primaryRoleCode;
  switch (code) {
    case 'rt':
      return UserRole.rt;
    case 'bendahara':
      return UserRole.bendahara;
    case 'warga':
      return UserRole.warga;
    default:
      return UserRole.unknown;
  }
});
