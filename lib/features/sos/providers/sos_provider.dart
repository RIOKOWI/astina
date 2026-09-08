import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/sos_data_source.dart';
import '../data/models/sos_alert_model.dart';

final sosDataSourceProvider = Provider<SosDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SosDataSource(dioClient);
});

// Active alerts
final activeSosAlertsProvider = FutureProvider.autoDispose<List<SosAlertModel>>(
  (ref) async {
    final datasource = ref.watch(sosDataSourceProvider);
    if (kDebugMode) developer.log('Loading active SOS alerts', name: 'SOS');
    return datasource.getActiveAlerts();
  },
);

// Alert detail
final sosDetailProvider = FutureProvider.autoDispose.family<SosAlertModel, int>(
  (ref, sosId) async {
    final datasource = ref.watch(sosDataSourceProvider);
    if (kDebugMode) developer.log('Loading SOS detail: $sosId', name: 'SOS');
    return datasource.getAlertDetail(sosId);
  },
);

// SOS notifier
final sosNotifierProvider = AsyncNotifierProvider<SosNotifier, SosState>(
  () => SosNotifier(),
);

class SosState {
  final String? errorMessage;
  final bool isSending;
  final bool lastTriggerSuccess;

  const SosState({
    this.errorMessage,
    this.isSending = false,
    this.lastTriggerSuccess = false,
  });

  SosState copyWith({
    String? errorMessage,
    bool? isSending,
    bool? lastTriggerSuccess,
  }) {
    return SosState(
      errorMessage: errorMessage ?? this.errorMessage,
      isSending: isSending ?? this.isSending,
      lastTriggerSuccess: lastTriggerSuccess ?? this.lastTriggerSuccess,
    );
  }
}

class SosNotifier extends AsyncNotifier<SosState> {
  @override
  SosState build() => const SosState();

  Future<bool> triggerSos({String? locationText}) async {
    state = AsyncValue.data(
      state.value!.copyWith(
        isSending: true,
        errorMessage: null,
        lastTriggerSuccess: false,
      ),
    );
    try {
      final datasource = ref.read(sosDataSourceProvider);
      final position = await datasource.getCurrentLocation();
      await datasource.triggerSos(
        latitude: position.latitude,
        longitude: position.longitude,
        locationText: locationText,
      );
      ref.invalidate(activeSosAlertsProvider);
      state = AsyncValue.data(
        state.value!.copyWith(isSending: false, lastTriggerSuccess: true),
      );
      if (kDebugMode) developer.log('SOS triggered successfully', name: 'SOS');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to trigger SOS',
          name: 'SOS',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isSending: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          lastTriggerSuccess: false,
        ),
      );
      return false;
    }
  }

  Future<bool> respondToSos(int sosId, bool isComing) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSending: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(sosDataSourceProvider);
      await datasource.respondToSos(sosId, isComing ? 'coming' : 'decline');
      ref.invalidate(sosDetailProvider(sosId));
      ref.invalidate(activeSosAlertsProvider);
      state = AsyncValue.data(state.value!.copyWith(isSending: false));
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to respond to SOS',
          name: 'SOS',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSending: false, errorMessage: e.toString()),
      );
      return false;
    }
  }

  Future<bool> resolveSos(int sosId) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSending: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(sosDataSourceProvider);
      await datasource.resolveSos(sosId);
      ref.invalidate(sosDetailProvider(sosId));
      ref.invalidate(activeSosAlertsProvider);
      state = AsyncValue.data(state.value!.copyWith(isSending: false));
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to resolve SOS',
          name: 'SOS',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSending: false, errorMessage: e.toString()),
      );
      return false;
    }
  }
}
