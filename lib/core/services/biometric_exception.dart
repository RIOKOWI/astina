/// Exception terstruktur untuk error biometrik.
/// Memiliki kode error spesifik agar UI bisa branching dengan tepat.
class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  const BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  factory BiometricException.fromPlatformException(
    String code,
    String? message,
  ) {
    final errorCode = _mapCode(code, message);
    return BiometricException(
      code: errorCode,
      message: message ?? 'Unknown biometric error',
      userMessage: _getUserMessage(errorCode),
    );
  }

  static BiometricErrorCode _mapCode(String code, String? message) {
    switch (code) {
      case 'NotAvailable':
        return BiometricErrorCode.noBiometricHardware;
      case 'NotEnrolled':
        return BiometricErrorCode.notEnrolled;
      case 'LockedOut':
        return BiometricErrorCode.temporaryLockout;
      case 'PermanentlyLockedOut':
        return BiometricErrorCode.biometricLockout;
      case 'PasscodeNotSet':
        return BiometricErrorCode.notEnrolled;
      default:
        final msg = message?.toLowerCase() ?? '';
        if (msg.contains('cancel')) {
          return BiometricErrorCode.userCanceled;
        }
        return BiometricErrorCode.unknown;
    }
  }

  static String _getUserMessage(BiometricErrorCode code) {
    switch (code) {
      case BiometricErrorCode.noBiometricHardware:
        return 'Autentikasi tidak tersedia di perangkat ini.';
      case BiometricErrorCode.notEnrolled:
        return 'Atur PIN, pola, kata sandi, atau sidik jari pada pengaturan perangkat terlebih dahulu.';
      case BiometricErrorCode.temporaryLockout:
        return 'Terlalu banyak percobaan. Coba kembali beberapa saat lagi.';
      case BiometricErrorCode.biometricLockout:
        return 'Autentikasi dinonaktifkan. Atur ulang keamanan perangkat.';
      case BiometricErrorCode.userCanceled:
        return '';
      case BiometricErrorCode.systemCanceled:
        return 'Autentikasi dibatalkan sistem. Silakan coba kembali.';
      case BiometricErrorCode.unknown:
        return 'Verifikasi gagal. Silakan coba kembali.';
    }
  }

  /// Apakah user boleh coba lagi setelah error ini.
  bool get isRetryable => switch (code) {
    BiometricErrorCode.userCanceled => true,
    BiometricErrorCode.systemCanceled => true,
    BiometricErrorCode.unknown => true,
    _ => false,
  };

  /// Apakah perlu buka pengaturan perangkat (biometrik belum terdaftar).
  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  /// Apakah perlu fallback ke password (device tidak support / lockout permanen).
  bool get requiresFallback => switch (code) {
    BiometricErrorCode.noBiometricHardware => true,
    BiometricErrorCode.biometricLockout => true,
    _ => false,
  };
}

enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}
