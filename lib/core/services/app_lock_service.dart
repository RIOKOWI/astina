import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

enum BiometricAuthResult {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  error,
}

class AppLockService {
  AppLockService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  bool _isLocked = true;
  bool _isAuthenticating = false;
  DateTime? _backgroundTimestamp;

  bool get isLocked => _isLocked;
  bool get isAuthenticating => _isAuthenticating;

  void initialize({required bool appLockEnabled}) {
    _isLocked = appLockEnabled;
    if (kDebugMode) {
      debugPrint('[APP_LOCK] initialized, locked=$_isLocked');
    }
  }

  Future<bool> isDeviceSupported() async {
    return _localAuth.isDeviceSupported();
  }

  Future<bool> canAuthenticate() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canAuth && !isSupported) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return isSupported;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[APP_LOCK] canAuthenticate error: $e');
      return false;
    }
  }

  Future<BiometricAuthResult> authenticate() async {
    if (_isAuthenticating) return BiometricAuthResult.cancelled;

    _isAuthenticating = true;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk melanjutkan.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isLocked = false;
        _backgroundTimestamp = null;
        if (kDebugMode) debugPrint('[APP_LOCK] authentication success');
        return BiometricAuthResult.success;
      } else {
        if (kDebugMode) debugPrint('[APP_LOCK] authentication failed');
        return BiometricAuthResult.failed;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[APP_LOCK] PlatformException: ${e.code}');
      return _mapPlatformException(e);
    } catch (e) {
      if (kDebugMode) debugPrint('[APP_LOCK] unexpected error: $e');
      return BiometricAuthResult.error;
    } finally {
      _isAuthenticating = false;
    }
  }

  void onBackground() {
    _backgroundTimestamp = DateTime.now();
    if (kDebugMode) debugPrint('[APP_LOCK] background timestamp recorded');
  }

  bool onForeground() {
    if (_backgroundTimestamp == null) {
      if (kDebugMode)
        debugPrint('[APP_LOCK] no background timestamp, not locking');
      return false;
    }

    final elapsed = DateTime.now().difference(_backgroundTimestamp!);
    final shouldLock = elapsed.inSeconds >= 30;

    if (kDebugMode) {
      debugPrint(
        '[APP_LOCK] foreground after ${elapsed.inSeconds}s, locking=$shouldLock',
      );
    }

    if (shouldLock) {
      _isLocked = true;
    }

    _backgroundTimestamp = null;
    return shouldLock;
  }

  void lock() {
    _isLocked = true;
    _backgroundTimestamp = null;
    if (kDebugMode) debugPrint('[APP_LOCK] locked');
  }

  void unlock() {
    _isLocked = false;
    _backgroundTimestamp = null;
    if (kDebugMode) debugPrint('[APP_LOCK] unlocked');
  }

  BiometricAuthResult _mapPlatformException(PlatformException e) {
    if (kDebugMode) {
      debugPrint('[APP_LOCK] PlatformException code: ${e.code}');
    }
    switch (e.code) {
      case 'NotAvailable':
        return BiometricAuthResult.notAvailable;
      case 'NotEnrolled':
        return BiometricAuthResult.notEnrolled;
      case 'LockedOut':
        return BiometricAuthResult.lockedOut;
      case 'PermanentlyLockedOut':
        return BiometricAuthResult.permanentlyLockedOut;
      case 'PasscodeNotSet':
        return BiometricAuthResult.passcodeNotSet;
      default:
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('cancel') || msg.contains('cancelled')) {
          return BiometricAuthResult.cancelled;
        }
        return BiometricAuthResult.error;
    }
  }
}
