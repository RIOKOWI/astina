import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationDisplayService {
  NotificationDisplayService._();

  static final NotificationDisplayService instance =
      NotificationDisplayService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'high_importance_channel';
  static const _androidChannelName = 'Notifikasi ASTINA';
  static const _sosChannelId = 'astina_sos_emergency_v1';
  static const _sosChannelName = 'SOS Darurat ASTINA';

  static const _sosSound = RawResourceAndroidNotificationSound(
    'astina_sos_siren',
  );

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Non-SOS channel: finance, activity, complaint, etc.
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: 'Notifikasi penting ASTINA.',
          importance: Importance.high,
        ),
      );

      // SOS emergency channel with custom siren.
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _sosChannelId,
          _sosChannelName,
          description: 'Notifikasi SOS darurat ASTINA.',
          importance: Importance.max,
          playSound: true,
          sound: _sosSound,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('Notification tapped, payload: $payload');
    }
  }

  /// Shows a local notification from an FCM message.
  ///
  /// SOS foreground: do NOT call this — stream handler plays just_audio.
  /// SOS background/terminated: do NOT call this — FCM shows system notification.
  /// Non-SOS foreground: call this to show in notification tray.
  Future<void> showFromFcm(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final isSos = _isSosAlert(message);

    final androidDetails = AndroidNotificationDetails(
      isSos ? _sosChannelId : _androidChannelId,
      isSos ? _sosChannelName : _androidChannelName,
      importance: isSos ? Importance.max : Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      color: const Color(0xFF008DFF),
      playSound: !isSos,
      sound: isSos ? _sosSound : null,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _buildPayload(message),
    );

    debugPrint(
      'Notification shown: ${notification.title} - ${notification.body}',
    );
  }

  bool _isSosAlert(RemoteMessage message) {
    final type = message.data['type'] as String?;
    return type == 'sos_alert' || type == 'sos_resolved';
  }

  String? _buildPayload(RemoteMessage message) {
    return message.data['type'] as String?;
  }
}

/// Background handler: FCM shows system notification automatically when app
/// is terminated/background. No need to call showFromFcm here (would duplicate).
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // FCM auto-displays the notification via the Android system when app is
  // backgrounded/terminated. Backend sends android.notification.sound for siren.
  // Just log for visibility.
  debugPrint('[FCM][BG] SOS notification received, system handles display.');
}

void registerFcmBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
}
