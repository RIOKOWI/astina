import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'features/fcm/fcm_provider.dart';

class AstinaApp extends ConsumerStatefulWidget {
  const AstinaApp({super.key});

  @override
  ConsumerState<AstinaApp> createState() => _AstinaAppState();
}

class _AstinaAppState extends ConsumerState<AstinaApp> {
  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    initFcmListeners();
    setFcmNavigationCallback((route) {
      if (mounted) appRouter.go(route);
    });

    // Handle notification that opened the app (cold start)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && mounted) {
      final route = FCMService.instance.extractRoute(initialMessage);
      if (route != null) appRouter.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch FCM messages for deep linking (foreground)
    ref.listen(fcmMessageProvider, (prev, next) {
      if (next != null) {
        final route = FCMService.instance.extractRoute(next);
        if (route != null && mounted) appRouter.go(route);
      }
    });

    return MaterialApp.router(
      title: 'ASTINA',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
