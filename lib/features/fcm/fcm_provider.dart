import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/services/dio_client.dart';
import '../../core/services/secure_storage.dart';
import 'data/datasources/fcm_remote_data_source.dart';
import 'data/models/notification_model.dart';
import '../../core/services/fcm_service.dart';

final fcmRemoteDataSourceProvider = Provider<FcmRemoteDataSource>((ref) {
  final storage = SecureStorageService();
  final dioClient = DioClient(storage);
  return FcmRemoteDataSource(dioClient);
});

final fcmMessageProvider = StreamProvider<RemoteMessage?>((ref) {
  return fcmMessageStream;
});

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  FcmRemoteDataSource get _ds => ref.read(fcmRemoteDataSourceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (list, meta) = await _ds.getNotifications();
      state = state.copyWith(
        notifications: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _ds.markAsRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) {
            return AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _ds.markAllAsRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (!n.isRead) {
            return AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
      );
    } catch (_) {}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

// Device token management — call after login, before logout
String? _currentFcmToken;

Future<void> registerFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token == _currentFcmToken) return;
    _currentFcmToken = token;

    final ds = FcmRemoteDataSource(DioClient(SecureStorageService()));
    await ds.registerDeviceToken(
      token: token,
      platform: Platform.isAndroid ? 'android' : 'ios',
      deviceName: Platform.isAndroid ? 'Android Device' : 'iOS Device',
    );
    if (kDebugMode) debugPrint('FCM token registered');

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _currentFcmToken = newToken;
      try {
        await ds.registerDeviceToken(
          token: newToken,
          platform: Platform.isAndroid ? 'android' : 'ios',
          deviceName: Platform.isAndroid ? 'Android Device' : 'iOS Device',
        );
      } catch (e) {
        if (kDebugMode) debugPrint('FCM token refresh failed: $e');
      }
    });
  } catch (e) {
    if (kDebugMode) debugPrint('FCM token registration failed: $e');
  }
}

Future<void> revokeFcmToken() async {
  if (_currentFcmToken == null) return;
  try {
    final ds = FcmRemoteDataSource(DioClient(SecureStorageService()));
    await ds.revokeDeviceToken(_currentFcmToken!);
    _currentFcmToken = null;
    if (kDebugMode) debugPrint('FCM token revoked');
  } catch (e) {
    if (kDebugMode) debugPrint('FCM token revocation failed: $e');
  }
}
