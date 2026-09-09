import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/resident_admin_data_source.dart';
import '../data/models/admin_resident_model.dart';

final residentAdminDataSourceProvider = Provider<ResidentAdminDataSource>((
  ref,
) {
  return ResidentAdminDataSource(ref.watch(dioClientProvider));
});

class ResidentsListState {
  final List<AdminResidentListItem> residents;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ResidentsListState({
    this.residents = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ResidentsListState copyWith({
    List<AdminResidentListItem>? residents,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ResidentsListState(
      residents: residents ?? this.residents,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class ResidentsListNotifier extends Notifier<ResidentsListState> {
  @override
  ResidentsListState build() => const ResidentsListState();

  Future<void> load({String? search, String? status, bool? hasAccount}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      final (list, meta) = await ds.getResidents(
        search: search,
        status: status,
        hasAccount: hasAccount,
        page: 1,
      );
      state = state.copyWith(
        residents: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? search,
    String? status,
    bool? hasAccount,
  }) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getResidents(
        search: search,
        status: status,
        hasAccount: hasAccount,
        page: nextPage,
      );
      state = state.copyWith(
        residents: [...state.residents, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final residentsListProvider =
    NotifierProvider<ResidentsListNotifier, ResidentsListState>(
      ResidentsListNotifier.new,
    );

final residentDetailProvider = FutureProvider.autoDispose
    .family<AdminResident, int>((ref, id) async {
      final ds = ref.watch(residentAdminDataSourceProvider);
      return ds.getResident(id);
    });
