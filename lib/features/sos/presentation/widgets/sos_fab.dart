import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/sos_provider.dart';
import '../../services/sos_audio_service.dart';

final _sosFabNavigatorProvider = StateProvider<NavigatorState?>((_) => null);

class SosFab extends ConsumerWidget {
  const SosFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(_sosFabNavigatorProvider);

    return FloatingActionButton.large(
      heroTag: 'sos_fab',
      backgroundColor: AppColors.error,
      onPressed: nav == null ? null : () => _onPressed(context, ref, nav),
      child: const Icon(Icons.warning_rounded, size: 36, color: Colors.white),
    );
  }

  Future<void> _onPressed(BuildContext context, WidgetRef ref, NavigatorState nav) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SOS_CONFIRM',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim, secondaryAnim) => ScaleTransition(
        scale: anim,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              SizedBox(width: 8),
              Text('Konfirmasi SOS'),
            ],
          ),
          content: const Text(
            'Kirim peringatan SOS darurat ke semua warga?\n'
            'Lokasi Anda akan dikirimkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Kirim SOS'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    await _triggerSos(router, messenger, ref);
  }

  Future<void> _triggerSos(
    GoRouter router,
    ScaffoldMessengerState messenger,
    WidgetRef ref,
  ) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('GPS nonaktif. Aktifkan untuk mengirim SOS.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi ditolak permanen.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Mengirim SOS...'),
        backgroundColor: AppColors.dark,
      ),
    );

    HapticFeedback.heavyImpact();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final alert = await ref.read(sosNotifierProvider.notifier).triggerSos(
            latitude: position.latitude,
            longitude: position.longitude,
          );

      SosAudioService.instance.playSiren();

      messenger.showSnackBar(
        SnackBar(
          content: Text('SOS terkirim! oleh ${alert.triggeredBy.name}.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
      router.go('/sos/${alert.id}');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim SOS: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

