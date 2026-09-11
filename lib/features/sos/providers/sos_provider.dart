import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/sos_remote_data_source.dart';
import '../data/models/sos_alert_model.dart';
import '../services/sos_audio_service.dart';

final sosRemoteDataSourceProvider = Provider<SosRemoteDataSource>((ref) {
  return SosRemoteDataSource(ref.watch(dioClientProvider));
});

final sosActiveAlertsProvider = FutureProvider.autoDispose<List<SosAlertModel>>(
  (ref) async {
    final ds = ref.watch(sosRemoteDataSourceProvider);
    return ds.getActiveAlerts();
  },
);

final sosAlertDetailProvider = FutureProvider.autoDispose
    .family<SosAlertModel, int>((ref, id) async {
      final ds = ref.watch(sosRemoteDataSourceProvider);
      return ds.getAlert(id);
    });

class SosNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<SosAlertModel> triggerSos({
    required double latitude,
    required double longitude,
    String? locationText,
  }) async {
    final ds = ref.read(sosRemoteDataSourceProvider);
    final alert = await ds.createAlert(
      latitude: latitude,
      longitude: longitude,
      locationText: locationText,
    );
    SosAudioService.instance.playSiren();
    ref.invalidate(sosActiveAlertsProvider);
    return alert;
  }

  void stopSiren() {
    SosAudioService.instance.stopSiren();
  }
}

final sosNotifierProvider = NotifierProvider<SosNotifier, void>(
  SosNotifier.new,
);
