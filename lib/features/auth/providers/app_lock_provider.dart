import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/secure_storage.dart';
import '../../../core/services/app_lock_state.dart';
import '../../../core/injection/dependency_injection.dart';

enum AppLockAuthStatus {
  success,
  sessionInvalid,
  networkError,
  biometricFailed,
  biometricCancelled,
  biometricNotAvailable,
  biometricNotEnrolled,
  biometricLockedOut,
  biometricPermanentlyLocked,
  biometricPasscodeNotSet,
  error,
}

class AppLockAuthResult {
  final AppLockAuthStatus status;
  final String? message;

  const AppLockAuthResult({required this.status, this.message});
}

class AppLockNotifier extends Notifier<AppLockState> {
  late final AppLockService _service;
  late final SecureStorageService _storage;

  static const _appLockKey = 'app_lock_enabled';

  @override
  AppLockState build() {
    _service = AppLockService();
    _storage = ref.read(secureStorageProvider);
    _init();
    return const AppLockState();
  }

  void _notifyState() {
    appLockStateHolder.update(state);
  }

  Future<void> _init() async {
    final enabled = await _getAppLockEnabledFromStorage();
    final canUse = await _service.canAuthenticate();

    state = state.copyWith(
      enabled: enabled,
      locked: enabled,
      canUseBiometric: canUse,
    );

    _service.initialize(appLockEnabled: enabled);
    _notifyState();
  }

  Future<bool> _getAppLockEnabledFromStorage() async {
    final val = await _storage.getValue(_appLockKey);
    return val == 'true';
  }

  Future<void> _setAppLockEnabled(bool value) async {
    await _storage.setValue(_appLockKey, value.toString());
  }

  Future<void> _resetAppLockEnabled() async {
    await _storage.delete(_appLockKey);
  }

  Future<bool> enable() async {
    if (state.authenticating) return false;

    final canAuth = await _service.canAuthenticate();
    if (!canAuth) return false;

    state = state.copyWith(authenticating: true);
    _notifyState();

    final success = await _authenticateAndSave(enabled: true);

    state = state.copyWith(
      enabled: success,
      locked: !success,
      authenticating: false,
    );
    _notifyState();

    if (success) _service.unlock();

    return success;
  }

  Future<bool> disable() async {
    if (state.authenticating) return false;

    state = state.copyWith(authenticating: true);
    _notifyState();

    final success = await _authenticateAndSave(enabled: false);

    state = state.copyWith(
      enabled: success,
      locked: false,
      authenticating: false,
    );
    _notifyState();

    if (success) _service.unlock();

    return success;
  }

  Future<bool> _authenticateAndSave({required bool enabled}) async {
    final result = await _service.authenticate();
    if (result == BiometricAuthResult.success) {
      await _setAppLockEnabled(enabled);
      if (kDebugMode)
        debugPrint('[APP_LOCK] ${enabled ? 'enabled' : 'disabled'}');
      return true;
    }
    return false;
  }

  Future<AppLockAuthResult> authenticate() async {
    if (!state.enabled) {
      return const AppLockAuthResult(status: AppLockAuthStatus.success);
    }

    state = state.copyWith(authenticating: true);
    _notifyState();

    final biometricResult = await _service.authenticate();

    if (biometricResult == BiometricAuthResult.success) {
      final sessionResult = await _validateBackendSession();
      state = state.copyWith(authenticating: false);
      _notifyState();

      if (sessionResult.status == AppLockAuthStatus.success) {
        _service.unlock();
        return sessionResult;
      }
      return sessionResult;
    }

    state = state.copyWith(locked: true, authenticating: false);
    _notifyState();

    return _mapBiometricToAuthResult(biometricResult);
  }

  Future<AppLockAuthResult> _validateBackendSession() async {
    try {
      final ds = ref.read(authRemoteDataSourceProvider);
      await ds.getMe();
      if (kDebugMode) debugPrint('[APP_LOCK] backend session valid');
      return const AppLockAuthResult(status: AppLockAuthStatus.success);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (kDebugMode) debugPrint('[APP_LOCK] backend session invalid (401)');
        await _storage.clearAll();
        return const AppLockAuthResult(
          status: AppLockAuthStatus.sessionInvalid,
          message: 'Sesi habis. Silakan login ulang.',
        );
      }
      if (kDebugMode) debugPrint('[APP_LOCK] network error: ${e.type}');
      return const AppLockAuthResult(
        status: AppLockAuthStatus.networkError,
        message: 'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[APP_LOCK] session validation error: $e');
      return const AppLockAuthResult(
        status: AppLockAuthStatus.networkError,
        message: 'Tidak dapat terhubung ke server.',
      );
    }
  }

  AppLockAuthResult _mapBiometricToAuthResult(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.success:
        return const AppLockAuthResult(status: AppLockAuthStatus.success);
      case BiometricAuthResult.failed:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricFailed,
          message: 'Verifikasi gagal. Silakan coba kembali.',
        );
      case BiometricAuthResult.cancelled:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricCancelled,
          message: null,
        );
      case BiometricAuthResult.notAvailable:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricNotAvailable,
          message: 'Autentikasi tidak tersedia di perangkat ini.',
        );
      case BiometricAuthResult.notEnrolled:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricNotEnrolled,
          message:
              'Biometrik belum dikonfigurasi. Tambahkan fingerprint atau Face ID di pengaturan perangkat.',
        );
      case BiometricAuthResult.lockedOut:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricLockedOut,
          message:
              'Autentikasi biometrik sementara dikunci. Coba kembali beberapa saat lagi.',
        );
      case BiometricAuthResult.permanentlyLockedOut:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricPermanentlyLocked,
          message: 'Autentikasi dinonaktifkan. Atur ulang keamanan perangkat.',
        );
      case BiometricAuthResult.passcodeNotSet:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.biometricPasscodeNotSet,
          message:
              'Atur PIN, pola, kata sandi, atau sidik jari di pengaturan perangkat.',
        );
      case BiometricAuthResult.error:
        return const AppLockAuthResult(
          status: AppLockAuthStatus.error,
          message: 'Verifikasi gagal. Silakan coba kembali.',
        );
    }
  }

  void onBackground() {
    _service.onBackground();
  }

  bool onForeground() {
    return _service.onForeground();
  }

  void checkForegroundLock() {
    if (state.enabled && !state.locked) {
      final shouldLock = _service.onForeground();
      if (shouldLock) {
        state = state.copyWith(locked: true);
        _notifyState();
      }
    }
  }

  void reset() {
    _resetAppLockEnabled();
    _service.unlock();
    state = const AppLockState();
    _notifyState();
  }

  Future<void> refreshCapability() async {
    final canUse = await _service.canAuthenticate();
    state = state.copyWith(canUseBiometric: canUse);
    _notifyState();
  }

  Future<bool> checkCanUse() async {
    return _service.canAuthenticate();
  }

  Future<void> clearSessionAndGoToLogin() async {
    await _storage.clearAll();
    _service.unlock();
    state = const AppLockState();
    _notifyState();
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
