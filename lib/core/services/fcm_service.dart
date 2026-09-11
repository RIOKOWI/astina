import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef FcmMessageHandler = void Function(RemoteMessage message);

class FCMService {
  FCMService._();

  static final FCMService instance = FCMService._();

  FcmMessageHandler? _messageHandler;

  void setMessageHandler(FcmMessageHandler handler) {
    _messageHandler = handler;
  }

  Future<void> initialize() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      developer.log(
        'FCM permission: ${settings.authorizationStatus.name}',
        name: 'FCM',
      );
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _listenForeground();
      _listenOpenedApp();
    }
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        developer.log(
          'FCM foreground: ${message.notification?.title}',
          name: 'FCM',
        );
      }
      _dispatch(message);
    });
  }

  void _listenOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        developer.log(
          'FCM opened app: ${message.notification?.title}',
          name: 'FCM',
        );
      }
      _dispatch(message);
    });
  }

  void _dispatch(RemoteMessage message) {
    _messageHandler?.call(message);
  }

  String? extractRoute(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    if (kDebugMode) {
      developer.log('FCM data: $data', name: 'FCM');
    }

    if (type == null) return null;

    final id =
        data['id']?.toString() ??
        data['activity_id']?.toString() ??
        data['letter_id']?.toString() ??
        data['payment_id']?.toString() ??
        data['complaint_id']?.toString() ??
        data['sos_id']?.toString();

    switch (type) {
      case 'activity_created':
        return id != null ? '/activities/$id' : '/activities';
      case 'letter_submitted':
      case 'letter_approved':
      case 'letter_rejected':
      case 'letter_completed':
        return id != null ? '/letters/$id' : '/letters';
      case 'payment_submitted':
      case 'payment_approved':
      case 'payment_rejected':
        return id != null ? '/finance/payments/$id' : '/finance';
      case 'complaint_created':
      case 'complaint_updated':
        return id != null ? '/complaints/$id' : '/complaints';
      case 'sos_alert':
        return id != null ? '/sos/$id' : '/sos';
      default:
        return '/notifications';
    }
  }
}

// Top-level functions for app initialization
void initFcmListeners() {
  FCMService.instance.setMessageHandler((message) {
    _fcmMessageController.add(message);
  });
}

final _fcmMessageController = StreamController<RemoteMessage>.broadcast();

Stream<RemoteMessage> get fcmMessageStream => _fcmMessageController.stream;
