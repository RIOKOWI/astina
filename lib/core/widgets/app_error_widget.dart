import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Convert any error to a user-friendly message.
/// Raw error is logged to terminal for debugging.
String friendlyErrorMessage(Object error) {
  try {
    if (error is DioException) {
      final msg = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        DioExceptionType.cancel => 'Permintaan dibatalkan.',
        DioExceptionType.badCertificate => 'Sertifikat keamanan tidak valid.',
        DioExceptionType.badResponse =>
          error.response?.data?['message'] as String? ??
              'Server mengembalikan respons yang tidak diharapkan.',
        DioExceptionType.unknown || DioExceptionType.transformTimeout =>
          error.message?.contains('host lookup') == true ||
                  error.message?.contains('connection') == true
              ? 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'
              : 'Terjadi kesalahan. Silakan coba beberapa saat lagi.',
      };
      if (kDebugMode) debugPrint('[AppError] DioException: $error');
      return msg;
    }
  } catch (_) {
    // ApiException or other runtime types
  }

  // Handle ApiException (defined in auth_remote_data_source.dart)
  try {
    final msg = (error as dynamic).message as String?;
    if (msg != null) {
      if (kDebugMode) debugPrint('[AppError] ApiException: $msg');
      return msg;
    }
  } catch (_) {}

  if (error is String) {
    if (kDebugMode) debugPrint('[AppError] String error: $error');
    if (error.contains('SocketException') ||
        error.contains('Connection') ||
        error.contains('timeout') ||
        error.contains('Lookup failed') ||
        error.contains('Failed host')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return error;
  }

  if (kDebugMode) debugPrint('[AppError] Unknown error: $error');
  return 'Terjadi kesalahan. Silakan coba beberapa saat lagi.';
}

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.title,
    required this.onRetry,
    this.message,
  });

  final String? title;
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              title ?? 'Terjadi kesalahan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrap content with RefreshIndicator + error handling.
class AppRefreshWrapper extends StatelessWidget {
  const AppRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}
