import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/activity_remote_data_source.dart';
import '../data/models/activity_model.dart';

final activityRemoteDataSourceProvider = Provider<ActivityRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return ActivityRemoteDataSource(dioClient);
});

final activitiesProvider = FutureProvider.autoDispose<List<ActivityModel>>((
  ref,
) async {
  final datasource = ref.watch(activityRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading activities', name: 'ActivityProvider');
  return datasource.getActivities(status: 'published');
});

final activityDetailProvider = FutureProvider.autoDispose
    .family<ActivityModel, int>((ref, id) async {
      final datasource = ref.watch(activityRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading activity detail: $id', name: 'ActivityProvider');
      return datasource.getActivityDetail(id);
    });

final activityNotifierProvider =
    AsyncNotifierProvider<ActivityNotifier, ActivityState>(
      () => ActivityNotifier(),
    );

class ActivityState {
  final int unreadCount;

  const ActivityState({this.unreadCount = 0});

  ActivityState copyWith({int? unreadCount}) {
    return ActivityState(unreadCount: unreadCount ?? this.unreadCount);
  }
}

class ActivityNotifier extends AsyncNotifier<ActivityState> {
  @override
  ActivityState build() => const ActivityState();

  Future<void> markAsRead(int activityId) async {
    final datasource = ref.read(activityRemoteDataSourceProvider);
    try {
      await datasource.markAsRead(activityId);
      ref.invalidate(activitiesProvider);
      final current = state.valueOrNull?.unreadCount ?? 0;
      state = AsyncValue.data(
        state.value!.copyWith(unreadCount: current > 0 ? current - 1 : 0),
      );
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to mark activity as read',
          name: 'ActivityProvider',
          error: e,
          stackTrace: st,
        );
    }
  }
}

// === RT ADMIN ===

final rtActivityNotifierProvider =
    AsyncNotifierProvider<RtActivityNotifier, RtActivityState>(
      () => RtActivityNotifier(),
    );

class RtActivityState {
  final String? errorMessage;
  final bool isProcessing;

  const RtActivityState({this.errorMessage, this.isProcessing = false});

  RtActivityState copyWith({String? errorMessage, bool? isProcessing}) {
    return RtActivityState(
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class RtActivityNotifier extends AsyncNotifier<RtActivityState> {
  @override
  RtActivityState build() => const RtActivityState();

  Future<ActivityModel?> createActivity(Map<String, dynamic> data) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(activityRemoteDataSourceProvider);
      final activity = await datasource.createActivity(data);
      ref.invalidate(activitiesProvider);
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
      return activity;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to create activity',
          name: 'ActivityProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }

  Future<ActivityModel?> updateActivity(
    int id,
    Map<String, dynamic> data,
  ) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(activityRemoteDataSourceProvider);
      final activity = await datasource.updateActivity(id, data);
      ref.invalidate(activitiesProvider);
      ref.invalidate(activityDetailProvider(id));
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
      return activity;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to update activity',
          name: 'ActivityProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }

  Future<bool> deleteActivity(int id) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(activityRemoteDataSourceProvider);
      await datasource.deleteActivity(id);
      ref.invalidate(activitiesProvider);
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to delete activity',
          name: 'ActivityProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<ActivityAttachment?> uploadAttachment(
    int activityId,
    String filePath,
    String fileName,
  ) async {
    try {
      final datasource = ref.read(activityRemoteDataSourceProvider);
      final attachment = await datasource.uploadAttachment(
        activityId,
        filePath,
        fileName,
      );
      ref.invalidate(activityDetailProvider(activityId));
      return attachment;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to upload attachment',
          name: 'ActivityProvider',
          error: e,
          stackTrace: st,
        );
      return null;
    }
  }

  Future<bool> deleteAttachment(int activityId, int attachmentId) async {
    try {
      final datasource = ref.read(activityRemoteDataSourceProvider);
      await datasource.deleteAttachment(activityId, attachmentId);
      ref.invalidate(activityDetailProvider(activityId));
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to delete attachment',
          name: 'ActivityProvider',
          error: e,
          stackTrace: st,
        );
      return false;
    }
  }
}
