import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'features/fcm/fcm_provider.dart';
import 'features/sos/services/sos_audio_service.dart';
import 'features/sos/data/datasources/sos_remote_data_source.dart';
import 'core/injection/dependency_injection.dart';

class AstinaApp extends ConsumerStatefulWidget {
  const AstinaApp({super.key});

  @override
  ConsumerState<AstinaApp> createState() => _AstinaAppState();
}

class _AstinaAppState extends ConsumerState<AstinaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFcm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSosAndStopSiren();
    }
  }

  Future<void> _checkSosAndStopSiren() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final ds = SosRemoteDataSource(dioClient);
      final active = await ds.getActiveAlerts();
      if (active.isEmpty && SosAudioService.instance.isPlaying) {
        SosAudioService.instance.stopSiren();
      }
    } catch (_) {}
  }

  Future<void> _initFcm() async {
    initFcmListeners();
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && mounted) {
      final route = FCMService.instance.extractRoute(initialMessage);
      if (route != null) appRouter.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fcmMessageProvider, (prev, next) {
      next.whenData((message) {
        if (message != null) {
          final route = FCMService.instance.extractRoute(message);
          if (route != null && mounted) appRouter.go(route);
        }
      });
    });

    return MaterialApp.router(
      title: 'Astina Smart Mobile',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
