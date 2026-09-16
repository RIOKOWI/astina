import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final storage = ref.read(secureStorageProvider);
    final biometricEnabled = await storage.isBiometricEnabled();
    if (!biometricEnabled) return;

    final biometric = ref.read(biometricServiceProvider);
    final canAuth = await biometric.canCheckBiometrics();
    if (!canAuth) return;

    try {
      await biometric.authenticate(
        reason: 'Verifikasi sidik jari untuk masuk aplikasi',
      );
    } catch (_) {
      // Fallback to login on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/lottie/searching-for-profile.json',
                repeat: true,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
