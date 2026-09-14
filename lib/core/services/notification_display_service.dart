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
  static const _androidChannelName = 'High Importance Notifications';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: 'Notifikasi penting seperti SOS dan pengumuman RT.',
          importance: Importance.high,
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

  Future<void> showFromFcm(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      color: const Color(0xFF008DFF),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: _isHighPriority(message),
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
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: _buildPayload(message),
    );

    debugPrint(
      'Notification shown: ${notification.title} - ${notification.body}',
    );
  }

  bool _isHighPriority(RemoteMessage message) {
    final type = message.data['type'] as String?;
    return type == 'sos_alert' || type == 'sos_resolved';
  }

  String? _buildPayload(RemoteMessage message) {
    return message.data['type'] as String?;
  }
}

/// Must be top-level or static for FCM background handler.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await NotificationDisplayService.instance.showFromFcm(message);
}

void registerFcmBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
}
