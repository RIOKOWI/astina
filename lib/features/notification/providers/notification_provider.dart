import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/notification_remote_data_source.dart';
import '../data/models/notification_model.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      final dioClient = ref.watch(dioClientProvider);
      return NotificationRemoteDataSource(dioClient);
    });

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
      final datasource = ref.watch(notificationRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading notifications', name: 'NotificationProvider');
      return datasource.getNotifications();
    });

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
      () => NotificationNotifier(),
    );

class NotificationState {
  final int unreadCount;

  const NotificationState({this.unreadCount = 0});

  NotificationState copyWith({int? unreadCount}) {
    return NotificationState(unreadCount: unreadCount ?? this.unreadCount);
  }
}

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  Future<void> markAsRead(int notificationId) async {
    final datasource = ref.read(notificationRemoteDataSourceProvider);
    try {
      await datasource.markAsRead(notificationId);
      ref.invalidate(notificationsProvider);
      final current = state.valueOrNull?.unreadCount ?? 0;
      state = AsyncValue.data(
        state.value!.copyWith(unreadCount: current > 0 ? current - 1 : 0),
      );
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to mark notification as read',
          name: 'NotificationProvider',
          error: e,
          stackTrace: st,
        );
    }
  }

  Future<void> markAllAsRead() async {
    final datasource = ref.read(notificationRemoteDataSourceProvider);
    try {
      await datasource.markAllAsRead();
      ref.invalidate(notificationsProvider);
      state = AsyncValue.data(state.value!.copyWith(unreadCount: 0));
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to mark all as read',
          name: 'NotificationProvider',
          error: e,
          stackTrace: st,
        );
    }
  }
}
