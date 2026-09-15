import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_exception.dart';

/// Service layer yang membungkus LocalAuthentication.
/// UI tidak pernah memanggil LocalAuthentication langsung.
class BiometricService {
  BiometricService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Cek apakah device support biometric.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Ambil tipe biometric yang tersedia.
  /// Returns list kosong jika tidak ada biometric terdaftar.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Autentikasi dengan biometric.
  /// Throws [BiometricException] jika gagal.
  Future<bool> authenticate({required String reason}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw const BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'Biometric not available',
          userMessage: 'Autentikasi tidak tersedia di perangkat ini.',
        );
      }

      final available = await getAvailableBiometrics();
      if (available.isEmpty) {
        throw const BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled',
          userMessage:
              'Atur PIN, pola, kata sandi, atau sidik jari pada pengaturan perangkat terlebih dahulu.',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!authenticated) {
        throw const BiometricException(
          code: BiometricErrorCode.unknown,
          message: 'Authentication failed',
          userMessage: 'Verifikasi gagal. Silakan coba kembali.',
        );
      }

      return true;
    } on BiometricException {
      rethrow;
    } on PlatformException catch (e) {
      throw BiometricException.fromPlatformException(e.code, e.message);
    } catch (_) {
      throw const BiometricException(
        code: BiometricErrorCode.unknown,
        message: 'Unexpected error',
        userMessage: 'Verifikasi gagal. Silakan coba kembali.',
      );
    }
  }
}
