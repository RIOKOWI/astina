import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/me_household_data_source.dart';
import '../data/models/household_model.dart';

final meHouseholdDataSourceProvider = Provider<MeHouseholdDataSource>((ref) {
  return MeHouseholdDataSource(ref.watch(dioClientProvider));
});

final meHouseholdProvider = FutureProvider.autoDispose<HouseholdModel?>((
  ref,
) async {
  final ds = ref.watch(meHouseholdDataSourceProvider);
  return ds.getMyHousehold();
});
