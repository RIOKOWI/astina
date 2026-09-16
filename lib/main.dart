import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_display_service.dart';
import 'features/sos/services/sos_audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch native crashes and log before app dies
  SystemChannels.platform.setMethodCallHandler((call) async {
    debugPrint('[SYSTEM] ${call.method}: ${call.arguments}');
    return null;
  });

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[MAIN] dotenv load failed: $e');
  }

  try {
    await Firebase.initializeApp();
    debugPrint('[MAIN] Firebase.initializeApp OK');
  } catch (e, st) {
    debugPrint('[MAIN] Firebase.initializeApp FAILED: $e\n$st');
  }

  try {
    registerFcmBackgroundHandler();
    debugPrint('[MAIN] FCM background handler registered');
  } catch (e) {
    debugPrint('[MAIN] FCM background handler FAILED: $e');
  }

  try {
    await NotificationDisplayService.instance.initialize();
    debugPrint('[MAIN] NotificationDisplayService initialized OK');
  } catch (e, st) {
    debugPrint('[MAIN] NotificationDisplayService FAILED: $e\n$st');
  }

  try {
    await FCMService.instance.initialize();
    debugPrint('[MAIN] FCMService initialized OK');
  } catch (e, st) {
    debugPrint('[MAIN] FCMService FAILED: $e\n$st');
  }

  try {
    fcmMessageStream.listen((message) {
      final type = message.data['type'] as String?;
      if (type == 'sos_alert') {
        SosAudioService.instance.playSiren();
      } else if (type == 'sos_resolved') {
        SosAudioService.instance.stopSiren();
      }
    });
    debugPrint('[MAIN] FCM stream subscribed OK');
  } catch (e) {
    debugPrint('[MAIN] FCM stream FAILED: $e');
  }

  try {
    FirebaseMessaging.onMessage.listen((message) async {
      final type = message.data['type'] as String?;
      if (type != 'sos_alert' && type != 'sos_resolved') {
        await NotificationDisplayService.instance.showFromFcm(message);
      }
    });
    debugPrint('[MAIN] FirebaseMessaging.onMessage subscribed OK');
  } catch (e) {
    debugPrint('[MAIN] FirebaseMessaging.onMessage FAILED: $e');
  }

  runApp(const ProviderScope(child: AstinaApp()));
}
