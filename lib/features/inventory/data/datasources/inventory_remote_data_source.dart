import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/asset_model.dart';
import '../models/asset_movement_model.dart';

class InventoryRemoteDataSource {
  final DioClient _client;

  InventoryRemoteDataSource(this._client);

  Future<AssetListResponse> getAssets({Map<String, dynamic>? query}) async {
    final response = await _client.get(
      ApiConstants.assets,
      queryParameters: query,
    );
    final data = response.data['data'] as List;
    return AssetListResponse.fromJson(response.data, data);
  }

  Future<AssetModel> getAssetDetail(int id) async {
    final response = await _client.get('${ApiConstants.assets}/$id');
    return AssetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AssetModel> createAsset(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.assets, data: data);
    return AssetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AssetModel> updateAsset(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '${ApiConstants.assets}/$id',
      data: data,
    );
    return AssetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AssetModel> retireAsset(int id) async {
    final response = await _client.delete('${ApiConstants.assets}/$id');
    return AssetModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<AssetMovementModel>> getAssetMovements(
    int assetId, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get(
      '${ApiConstants.assets}/$assetId/movements',
      queryParameters: query,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => AssetMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssetMovementModel> createMovement(
    int assetId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      '${ApiConstants.assets}/$assetId/movements',
      data: data,
    );
    return AssetMovementModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
