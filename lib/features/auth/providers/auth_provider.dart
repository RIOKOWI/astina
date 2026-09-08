import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../../../core/services/auth_state.dart';
import '../../../core/services/router_refresh_notifier.dart';
import '../../../core/services/secure_storage.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/models/user_model.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const Unauthenticated();
  }

  SecureStorageService get _storage => ref.read(secureStorageProvider);
  AuthRemoteDataSource get _ds => ref.read(authRemoteDataSourceProvider);

  Future<void> _init() async {
    if (kDebugMode) developer.log('Auth: initializing...', name: 'Auth');
    try {
      final token = await _storage.getToken();
      if (token == null) {
        _updateState(null);
        return;
      }
      final user = await _ds.getMe();
      await _storage.saveUser(user.toJsonString());
      _updateState(user);
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Auth init failed, clearing session',
          name: 'Auth',
          error: e,
          stackTrace: st,
        );
      }
      await _storage.clearAll();
      _updateState(null);
    }
  }

  void _updateState(UserModel? user) {
    state = user != null ? Authenticated(user) : const Unauthenticated();
    routerRefreshNotifier.update(state);
  }

  Future<void> login({required String phone, required String password}) async {
    if (kDebugMode) developer.log('Auth: login started', name: 'Auth');
    final (token, user) = await _ds.login(phone: phone, password: password);
    await _storage.saveToken(token);
    await _storage.saveUser(user.toJsonString());
    _updateState(user);
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
    _updateState(null);
    if (kDebugMode) developer.log('Auth: logged out', name: 'Auth');
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;
    try {
      final user = await _ds.getMe();
      await _storage.saveUser(user.toJsonString());
      _updateState(user);
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
