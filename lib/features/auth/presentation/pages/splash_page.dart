import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _biometricTriggered = false;

  @override
  void initState() {
    super.initState();
    // Defer to next frame so widget is fully built before showing dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_biometricTriggered) {
        _biometricTriggered = true;
        _triggerBiometric();
      }
    });
  }

  Future<void> _triggerBiometric() async {
    final biometric = ref.read(biometricServiceProvider);
    try {
      final success = await biometric.authenticate(
        reason: 'Verifikasi sidik jari untuk masuk aplikasi',
      );
      if (success && mounted) {
        await ref.read(authProvider.notifier).verifyBiometric();
      }
      // If cancelled/failed: stays on splash, user can retry
    } catch (e) {
      // Error — stays on splash, user can retry
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
            const SizedBox(height: 16),
            const Text(
              'Memverifikasi...',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
