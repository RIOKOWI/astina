import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/user_admin_data_source.dart';
import '../data/models/admin_user_model.dart';

final userAdminDataSourceProvider = Provider<UserAdminDataSource>((ref) {
  return UserAdminDataSource(ref.watch(dioClientProvider));
});

class UsersListState {
  final List<AdminUser> users;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const UsersListState({
    this.users = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  UsersListState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return UsersListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class UsersListNotifier extends Notifier<UsersListState> {
  @override
  UsersListState build() => const UsersListState();

  Future<void> load({String? search, bool? isActive, String? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(userAdminDataSourceProvider);
      final (list, meta) = await ds.getUsers(
        search: search,
        isActive: isActive,
        role: role,
        page: 1,
      );
      state = state.copyWith(
        users: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? search, bool? isActive, String? role}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(userAdminDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getUsers(
        search: search,
        isActive: isActive,
        role: role,
        page: nextPage,
      );
      state = state.copyWith(
        users: [...state.users, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final usersListProvider = NotifierProvider<UsersListNotifier, UsersListState>(
  UsersListNotifier.new,
);

final userDetailProvider = FutureProvider.autoDispose.family<AdminUser, int>((
  ref,
  id,
) async {
  final ds = ref.watch(userAdminDataSourceProvider);
  return ds.getUser(id);
});
