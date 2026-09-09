import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/sos_remote_data_source.dart';
import '../data/models/sos_alert_model.dart';

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
