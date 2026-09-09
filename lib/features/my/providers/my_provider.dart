import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/my_remote_data_source.dart';
import '../data/models/household_model.dart';

final myRemoteDataSourceProvider = Provider<MyRemoteDataSource>((ref) {
  return MyRemoteDataSource(ref.watch(dioClientProvider));
});

final myHouseholdProvider = FutureProvider.autoDispose<HouseholdModel?>((
  ref,
) async {
  final ds = ref.watch(myRemoteDataSourceProvider);
  return ds.getMyHousehold();
});
