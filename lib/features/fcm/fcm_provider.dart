import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/injection/dependency_injection.dart';
import 'package:astina/features/auth/data/datasources/auth_remote_data_source.dart';

final fcmMessageProvider = StateProvider<RemoteMessage?>((ref) => null);

final _fcmAuthDatasourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient);
});

Future<void> registerFcmToken(Ref ref) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;
  if (kDebugMode) developer.log('FCM register token: $token', name: 'FCM');

  try {
    final datasource = ref.read(_fcmAuthDatasourceProvider);
    await datasource.registerDeviceToken(token);
    if (kDebugMode) developer.log('FCM token registered', name: 'FCM');
  } catch (e, st) {
    if (kDebugMode) {
      developer.log(
        'FCM token registration failed',
        name: 'FCM',
        error: e,
        stackTrace: st,
      );
    }
  }
}

Future<void> unregisterFcmToken(Ref ref) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;
  if (kDebugMode) developer.log('FCM unregister token: $token', name: 'FCM');

  try {
    final datasource = ref.read(_fcmAuthDatasourceProvider);
    await datasource.unregisterDeviceToken(token);
  } catch (e) {
    if (kDebugMode)
      developer.log('FCM token unregister failed', name: 'FCM', error: e);
  }
}

typedef FcmNavigationCallback = void Function(String route);

FcmNavigationCallback? _onFcmNavigate;

void setFcmNavigationCallback(FcmNavigationCallback callback) {
  _onFcmNavigate = callback;
}

void _handleFcmMessage(RemoteMessage message) {
  if (kDebugMode) {
    developer.log('FCM message: ${message.notification?.title}', name: 'FCM');
  }

  // Dispatch to Riverpod state for UI to react
  // The app.dart Consumer will pick this up via fcmMessageProvider

  // Also navigate if we have a route
  final route = FCMService.instance.extractRoute(message);
  if (route != null) {
    _onFcmNavigate?.call(route);
  }
}

void initFcmListeners() {
  FCMService.instance.setMessageHandler(_handleFcmMessage);
}
