import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/inventory_remote_data_source.dart';
import '../data/models/asset_model.dart';
import '../data/models/asset_movement_model.dart';

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return InventoryRemoteDataSource(dioClient);
});

final assetsProvider = FutureProvider.autoDispose
    .family<AssetListResponse, AssetFilter>((ref, filter) async {
      final datasource = ref.watch(inventoryRemoteDataSourceProvider);
      if (kDebugMode) developer.log('Loading assets', name: 'Inventory');
      return datasource.getAssets(query: filter.toQuery());
    });

final assetDetailProvider = FutureProvider.autoDispose.family<AssetModel, int>((
  ref,
  id,
) async {
  final datasource = ref.watch(inventoryRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading asset detail: $id', name: 'Inventory');
  return datasource.getAssetDetail(id);
});

final assetMovementsProvider = FutureProvider.autoDispose
    .family<List<AssetMovementModel>, AssetMovementKey>((ref, key) async {
      final datasource = ref.watch(inventoryRemoteDataSourceProvider);
      if (kDebugMode) {
        developer.log(
          'Loading movements for asset: ${key.assetId}',
          name: 'Inventory',
        );
      }
      return datasource.getAssetMovements(
        key.assetId,
        query: key.filter.toQuery(),
      );
    });

class AssetMovementKey {
  final int assetId;
  final MovementFilter filter;

  const AssetMovementKey({required this.assetId, required this.filter});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssetMovementKey &&
        other.assetId == assetId &&
        other.filter == filter;
  }

  @override
  int get hashCode => Object.hash(assetId, filter);
}

class InventoryMutationState {
  final bool isProcessing;
  final String? error;

  const InventoryMutationState({this.isProcessing = false, this.error});

  InventoryMutationState copyWith({bool? isProcessing, String? error}) {
    return InventoryMutationState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class InventoryNotifier extends AsyncNotifier<InventoryMutationState> {
  @override
  Future<InventoryMutationState> build() async {
    return const InventoryMutationState();
  }

  Future<AssetModel?> createAsset(Map<String, dynamic> data) async {
    state = const AsyncValue.data(InventoryMutationState(isProcessing: true));
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      if (kDebugMode) developer.log('Creating asset', name: 'Inventory');
      final asset = await datasource.createAsset(data);
      state = const AsyncValue.data(InventoryMutationState());
      ref.invalidate(assetsProvider);
      return asset;
    } catch (e, st) {
      state = AsyncValue.data(InventoryMutationState(error: e.toString()));
      if (kDebugMode) {
        developer.log(
          'Failed to create asset',
          name: 'Inventory',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }

  Future<AssetModel?> updateAsset(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.data(InventoryMutationState(isProcessing: true));
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      if (kDebugMode) developer.log('Updating asset: $id', name: 'Inventory');
      final asset = await datasource.updateAsset(id, data);
      state = const AsyncValue.data(InventoryMutationState());
      ref.invalidate(assetsProvider);
      ref.invalidate(assetDetailProvider(id));
      return asset;
    } catch (e, st) {
      state = AsyncValue.data(InventoryMutationState(error: e.toString()));
      if (kDebugMode) {
        developer.log(
          'Failed to update asset',
          name: 'Inventory',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }

  Future<AssetModel?> retireAsset(int id) async {
    state = const AsyncValue.data(InventoryMutationState(isProcessing: true));
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      if (kDebugMode) developer.log('Retiring asset: $id', name: 'Inventory');
      final asset = await datasource.retireAsset(id);
      state = const AsyncValue.data(InventoryMutationState());
      ref.invalidate(assetsProvider);
      ref.invalidate(assetDetailProvider(id));
      return asset;
    } catch (e, st) {
      state = AsyncValue.data(InventoryMutationState(error: e.toString()));
      if (kDebugMode) {
        developer.log(
          'Failed to retire asset',
          name: 'Inventory',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }

  Future<AssetMovementModel?> createMovement(
    int assetId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.data(InventoryMutationState(isProcessing: true));
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      if (kDebugMode) {
        developer.log(
          'Creating movement for asset: $assetId',
          name: 'Inventory',
        );
      }
      final movement = await datasource.createMovement(assetId, data);
      state = const AsyncValue.data(InventoryMutationState());
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(
        assetMovementsProvider(
          AssetMovementKey(assetId: assetId, filter: const MovementFilter()),
        ),
      );
      ref.invalidate(assetsProvider);
      return movement;
    } catch (e, st) {
      state = AsyncValue.data(InventoryMutationState(error: e.toString()));
      if (kDebugMode) {
        developer.log(
          'Failed to create movement',
          name: 'Inventory',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }
}

final inventoryNotifierProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryMutationState>(
      InventoryNotifier.new,
    );
