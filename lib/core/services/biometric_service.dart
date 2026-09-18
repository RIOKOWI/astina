import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  Future<bool> canCheckBiometrics() async {
    final canAuthWithBiometrics = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return canAuthWithBiometrics && isDeviceSupported;
  }

  Future<List<BiometricType>> getAvailableBiometrics() =>
      _auth.getAvailableBiometrics();

  Future<bool> authenticate({required String reason}) => _auth.authenticate(
    localizedReason: reason,
    options: const AuthenticationOptions(
      stickyAuth: true,
      biometricOnly: false,
    ),
  );
}
