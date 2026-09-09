import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/activity_data_source.dart';
import '../data/models/activity_model.dart';

final activityDataSourceProvider = Provider<ActivityDataSource>((ref) {
  return ActivityDataSource(ref.watch(dioClientProvider));
});

class ActivitiesListState {
  const ActivitiesListState({
    this.activities = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<Activity> activities;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  ActivitiesListState copyWith({
    List<Activity>? activities,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ActivitiesListState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class ActivitiesListNotifier extends Notifier<ActivitiesListState> {
  @override
  ActivitiesListState build() => const ActivitiesListState();

  Future<void> load({String? search, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(activityDataSourceProvider);
      final (list, meta) = await ds.getActivities(
        search: search,
        status: status,
        page: 1,
      );
      state = state.copyWith(
        activities: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? search, String? status}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(activityDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getActivities(
        search: search,
        status: status,
        page: nextPage,
      );
      state = state.copyWith(
        activities: [...state.activities, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final activitiesListProvider =
    NotifierProvider<ActivitiesListNotifier, ActivitiesListState>(
      ActivitiesListNotifier.new,
    );

final activityDetailProvider = FutureProvider.autoDispose.family<Activity, int>(
  (ref, id) async {
    final ds = ref.watch(activityDataSourceProvider);
    return ds.getActivity(id);
  },
);
