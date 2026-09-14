import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/secure_storage.dart';
import '../../../core/services/app_lock_state.dart';
import '../../../core/injection/dependency_injection.dart';

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

  /// Enable app lock - requires successful authentication first.
  Future<bool> enable() async {
    if (state.authenticating) return false;

    // Check if device can authenticate first
    final canAuth = await _service.canAuthenticate();
    if (!canAuth) {
      return false;
    }

    state = state.copyWith(authenticating: true);
    _notifyState();

    final success = await _authenticateAndSave(enabled: true);

    state = state.copyWith(
      enabled: success,
      locked: !success,
      authenticating: false,
    );
    _notifyState();

    if (success) {
      _service.unlock();
    }

    return success;
  }

  /// Disable app lock - requires successful authentication first.
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

    if (success) {
      _service.unlock();
    }

    return success;
  }

  /// Returns true if auth succeeded.
  Future<bool> _authenticateAndSave({required bool enabled}) async {
    final completer = Completer<bool>();

    await _service.authenticate(
      onSuccess: () {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onError: (msg) {
        if (!completer.isCompleted && msg.isNotEmpty) {
          completer.complete(false);
        }
      },
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );

    if (result) {
      await _setAppLockEnabled(enabled);
      if (kDebugMode) {
        debugPrint('[APP_LOCK] ${enabled ? 'enabled' : 'disabled'}');
      }
    }

    return result;
  }

  /// Authenticate to unlock. Called when user taps "Buka ASTINA".
  Future<String?> authenticate() async {
    if (!state.enabled) return null;

    state = state.copyWith(authenticating: true);
    _notifyState();

    final completer = Completer<String?>();

    await _service.authenticate(
      onSuccess: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      onError: (msg) {
        if (!completer.isCompleted) {
          completer.complete(msg);
        }
      },
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => 'Verifikasi gagal. Silakan coba kembali.',
    );

    state = state.copyWith(locked: result != null, authenticating: false);
    _notifyState();

    if (result == null) {
      _service.unlock();
    }

    return result;
  }

  /// Called by app.dart when app goes to background.
  void onBackground() {
    _service.onBackground();
  }

  /// Called by app.dart when app comes to foreground.
  /// Returns true if app should be locked.
  bool onForeground() {
    return _service.onForeground();
  }

  /// Check and apply foreground lock if needed.
  void checkForegroundLock() {
    if (state.enabled && !state.locked) {
      final shouldLock = _service.onForeground();
      if (shouldLock) {
        state = state.copyWith(locked: true);
        _notifyState();
      }
    }
  }

  /// Called by auth logout to reset app lock state.
  void reset() {
    _resetAppLockEnabled();
    _service.unlock();
    state = const AppLockState();
    _notifyState();
  }

  /// Refresh capability check (e.g., after returning from device settings).
  Future<void> refreshCapability() async {
    final canUse = await _service.canAuthenticate();
    state = state.copyWith(canUseBiometric: canUse);
    _notifyState();
  }

  /// Check if device can use biometric/lock screen authentication.
  Future<bool> checkCanUse() async {
    return _service.canAuthenticate();
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
