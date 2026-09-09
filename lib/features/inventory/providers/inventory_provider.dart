import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/inventory_remote_data_source.dart';
import '../data/models/asset_model.dart';

final inventoryDataSourceProvider =
    Provider<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource(ref.watch(dioClientProvider));
});

class InventoryListState {
  const InventoryListState({
    this.assets = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<Asset> assets;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  InventoryListState copyWith({
    List<Asset>? assets,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return InventoryListState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class InventoryListNotifier extends Notifier<InventoryListState> {
  @override
  InventoryListState build() => const InventoryListState();

  Future<void> load({
    String? search,
    String? category,
    String? condition,
    String? status,
  }) async {
    if (kDebugMode) debugPrint('InventoryListNotifier.load called');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(inventoryDataSourceProvider);
      if (kDebugMode) debugPrint('Fetching assets from API...');
      final (list, meta) = await ds.getAssets(
        search: search,
        category: category,
        condition: condition,
        status: status,
        page: 1,
      );
      if (kDebugMode) debugPrint('Got ${list.length} assets, meta: $meta');
      state = state.copyWith(
        assets: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('InventoryListNotifier.load error: $e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? search,
    String? category,
    String? condition,
    String? status,
  }) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(inventoryDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getAssets(
        search: search,
        category: category,
        condition: condition,
        status: status,
        page: nextPage,
      );
      state = state.copyWith(
        assets: [...state.assets, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final inventoryListProvider =
    NotifierProvider<InventoryListNotifier, InventoryListState>(
  InventoryListNotifier.new,
);

final assetDetailProvider =
    FutureProvider.autoDispose.family<Asset, int>((ref, id) async {
  final ds = ref.watch(inventoryDataSourceProvider);
  return ds.getAsset(id);
});

class MovementsState {
  const MovementsState({
    this.movements = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<AssetMovement> movements;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  MovementsState copyWith({
    List<AssetMovement>? movements,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return MovementsState(
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class MovementsNotifier extends FamilyNotifier<MovementsState, int> {
  @override
  MovementsState build(int arg) => const MovementsState();

  Future<void> load({String? type, String? from, String? to}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(inventoryDataSourceProvider);
      final (list, meta) = await ds.getMovements(
        arg,
        type: type,
        from: from,
        to: to,
        page: 1,
      );
      state = state.copyWith(
        movements: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final movementsProvider =
    NotifierProvider.family<MovementsNotifier, MovementsState, int>(
  MovementsNotifier.new,
);
