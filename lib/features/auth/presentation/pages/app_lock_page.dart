import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/app_lock_provider.dart';

class AppLockPage extends ConsumerStatefulWidget {
  final VoidCallback? onUnlocked;
  final VoidCallback? onSessionInvalid;

  const AppLockPage({super.key, this.onUnlocked, this.onSessionInvalid});

  @override
  ConsumerState<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends ConsumerState<AppLockPage> {
  String? _errorMessage;
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _showRetry = false;
    });

    final authNotifier = ref.read(appLockProvider.notifier);
    final result = await authNotifier.authenticate();

    if (!mounted) return;

    switch (result.status) {
      case AppLockAuthStatus.success:
        widget.onUnlocked?.call();
        break;
      case AppLockAuthStatus.sessionInvalid:
        await authNotifier.clearSessionAndGoToLogin();
        widget.onSessionInvalid?.call();
        if (mounted) context.go('/login');
        break;
      case AppLockAuthStatus.networkError:
        setState(() {
          _errorMessage = result.message ?? 'Tidak dapat terhubung ke server.';
          _showRetry = true;
        });
        break;
      case AppLockAuthStatus.biometricCancelled:
        break;
      case AppLockAuthStatus.biometricNotEnrolled:
      case AppLockAuthStatus.biometricPasscodeNotSet:
        setState(() {
          _errorMessage = result.message;
        });
        break;
      case AppLockAuthStatus.biometricLockedOut:
      case AppLockAuthStatus.biometricPermanentlyLocked:
      case AppLockAuthStatus.biometricNotAvailable:
        setState(() {
          _errorMessage = result.message;
        });
        break;
      case AppLockAuthStatus.biometricFailed:
      case AppLockAuthStatus.error:
        setState(() {
          _errorMessage = result.message ?? 'Verifikasi gagal.';
        });
        break;
    }
  }

  Future<void> _loginWithPassword() async {
    final authNotifier = ref.read(appLockProvider.notifier);
    await authNotifier.clearSessionAndGoToLogin();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final appLockState = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'ASTINA Terkunci',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gunakan sidik jari atau biometrik perangkat\nuntuk melanjutkan.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: appLockState.authenticating ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: appLockState.authenticating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : const Text(
                          'Gunakan Biometric',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              if (_showRetry) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextButton(
                    onPressed: appLockState.authenticating
                        ? null
                        : _authenticate,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: appLockState.authenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: appLockState.authenticating
                    ? null
                    : _loginWithPassword,
                child: const Text(
                  'Login dengan password',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
