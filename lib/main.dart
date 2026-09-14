import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_display_service.dart';
import 'features/sos/services/sos_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  // Must register before FCMService.initialize (which calls requestPermission)
  registerFcmBackgroundHandler();
  await NotificationDisplayService.instance.initialize();

  await FCMService.instance.initialize();

  fcmMessageStream.listen((message) {
    final type = message.data['type'] as String?;
    if (type == 'sos_alert') {
      SosAudioService.instance.playSiren();
    } else if (type == 'sos_resolved') {
      SosAudioService.instance.stopSiren();
    }
  });

  // Foreground: handle non-SOS FCM locally. SOS handled by stream above.
  FirebaseMessaging.onMessage.listen((message) async {
    final type = message.data['type'] as String?;
    if (type != 'sos_alert' && type != 'sos_resolved') {
      // Non-SOS: show local notification.
      await NotificationDisplayService.instance.showFromFcm(message);
    }
    // SOS: handled by fcmMessageStream → SosAudioService (no double siren).
  });

  runApp(const ProviderScope(child: AstinaApp()));
}
