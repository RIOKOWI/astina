import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/household_admin_data_source.dart';
import '../data/models/admin_household_model.dart';

final householdAdminDataSourceProvider = Provider<HouseholdAdminDataSource>((
  ref,
) {
  return HouseholdAdminDataSource(ref.watch(dioClientProvider));
});

class HouseholdsListState {
  final List<AdminHousehold> households;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const HouseholdsListState({
    this.households = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  HouseholdsListState copyWith({
    List<AdminHousehold>? households,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return HouseholdsListState(
      households: households ?? this.households,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class HouseholdsListNotifier extends Notifier<HouseholdsListState> {
  @override
  HouseholdsListState build() => const HouseholdsListState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(householdAdminDataSourceProvider);
      final (list, meta) = await ds.getHouseholds(page: 1);
      state = state.copyWith(
        households: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(householdAdminDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getHouseholds(page: nextPage);
      state = state.copyWith(
        households: [...state.households, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final householdsListProvider =
    NotifierProvider<HouseholdsListNotifier, HouseholdsListState>(
      HouseholdsListNotifier.new,
    );

final householdDetailProvider = FutureProvider.autoDispose
    .family<AdminHousehold, int>((ref, id) async {
      final ds = ref.watch(householdAdminDataSourceProvider);
      return ds.getHousehold(id);
    });
