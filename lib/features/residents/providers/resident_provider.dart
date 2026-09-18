import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/me_resident_data_source.dart';
import '../data/models/resident_model.dart';

final meResidentDataSourceProvider = Provider<MeResidentDataSource>((ref) {
  return MeResidentDataSource(ref.watch(dioClientProvider));
});

final meResidentProvider = FutureProvider.autoDispose<MeResident?>((ref) async {
  final ds = ref.watch(meResidentDataSourceProvider);
  return ds.getMeResident();
});
