import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class AppLockService {
  AppLockService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  bool _isLocked = true;
  bool _isAuthenticating = false;
  DateTime? _backgroundTimestamp;

  bool get isLocked => _isLocked;
  bool get isAuthenticating => _isAuthenticating;

  /// Must be called before using authenticate() to initialize locked state.
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

  /// Returns friendly error message or null if user cancelled.
  Future<String?> authenticate({
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (_isAuthenticating) return null;

    _isAuthenticating = true;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk melanjutkan.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        _isLocked = false;
        _backgroundTimestamp = null;
        if (kDebugMode) debugPrint('[APP_LOCK] authentication success');
        onSuccess();
        return null;
      } else {
        if (kDebugMode) debugPrint('[APP_LOCK] authentication failed');
        onError('Verifikasi gagal. Silakan coba kembali.');
        return 'Verifikasi gagal. Silakan coba kembali.';
      }
    } on PlatformException catch (e) {
      final message = _mapPlatformException(e);
      if (kDebugMode) debugPrint('[APP_LOCK] authentication error: $message');
      onError(message);
      return message;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[APP_LOCK] authentication unexpected error: $e');
      onError('Verifikasi gagal. Silakan coba kembali.');
      return 'Verifikasi gagal. Silakan coba kembali.';
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Call when app goes to background.
  void onBackground() {
    _backgroundTimestamp = DateTime.now();
    if (kDebugMode) debugPrint('[APP_LOCK] background timestamp recorded');
  }

  /// Call when app resumes. Returns true if should lock.
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
        '[APP_LOCK] foreground after ${elapsed.inSeconds}s, shouldLock=$shouldLock',
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

  String _mapPlatformException(PlatformException e) {
    if (kDebugMode) {
      debugPrint('[APP_LOCK] PlatformException code: ${e.code}, message: ${e.message}');
    }
    switch (e.code) {
      case 'NotAvailable':
        return 'Autentikasi tidak tersedia di perangkat ini.';
      case 'NotEnrolled':
        return 'Atur PIN, pola, kata sandi, atau sidik jari pada pengaturan perangkat terlebih dahulu.';
      case 'LockedOut':
        return 'Terlalu banyak percobaan. Coba kembali beberapa saat lagi.';
      case 'PermanentlyLockedOut':
        return 'Autentikasi dinonaktifkan. Atur ulang keamanan perangkat.';
      case 'PasscodeNotSet':
        return 'Atur PIN, pola, kata sandi, atau sidik jari pada pengaturan perangkat terlebih dahulu.';
      default:
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('cancel') || msg.contains('cancelled')) {
          return '';
        }
        return 'Verifikasi gagal. Silakan coba kembali.';
    }
  }
}
