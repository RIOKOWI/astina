import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/fcm_service.dart';
import 'features/sos/services/sos_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  await FCMService.instance.initialize();

  fcmMessageStream.listen((message) {
    final type = message.data['type'] as String?;
    if (type == 'sos_alert') {
      SosAudioService.instance.playSiren();
    }
  });

  runApp(const ProviderScope(child: AstinaApp()));
}
