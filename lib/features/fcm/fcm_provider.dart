import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/services/fcm_service.dart';

final fcmMessageProvider = StreamProvider<RemoteMessage?>((ref) {
  return fcmMessageStream;
});
