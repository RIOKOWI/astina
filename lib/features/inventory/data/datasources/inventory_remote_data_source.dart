import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/asset_model.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._client);
  final DioClient _client;

  Future<(List<Asset>, Map<String, dynamic>)> getAssets({
    String? search,
    String? category,
    String? condition,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await _client.get(
      ApiConstants.assets,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => Asset.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<Asset> getAsset(int id) async {
    final response = await _client.get(ApiConstants.assetDetail(id));
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Asset> createAsset({
    required String name,
    required String category,
    required String unit,
    String? description,
    int? quantity,
    int? purchasePrice,
    String? purchaseDate,
    String? condition,
    String? status,
  }) async {
    final response = await _client.post(
      ApiConstants.assets,
      data: {
        'name': name,
        'category': category,
        'unit': unit,
        if (description != null && description.isNotEmpty) 'description': description,
        if (quantity != null) 'quantity': quantity,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (purchaseDate != null) 'purchase_date': purchaseDate,
        if (condition != null) 'condition': condition,
        if (status != null) 'status': status,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Asset> updateAsset(
    int id, {
    String? name,
    String? category,
    String? unit,
    String? description,
    int? purchasePrice,
    String? purchaseDate,
    String? condition,
    String? status,
  }) async {
    final response = await _client.put(
      ApiConstants.assetDetail(id),
      data: {
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (unit != null) 'unit': unit,
        if (description != null) 'description': description,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (purchaseDate != null) 'purchase_date': purchaseDate,
        if (condition != null) 'condition': condition,
        if (status != null) 'status': status,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAsset(int id) async {
    await _client.delete(ApiConstants.assetDetail(id));
  }

  Future<(List<AssetMovement>, Map<String, dynamic>)> getMovements(
    int assetId, {
    String? type,
    String? from,
    String? to,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (type != null && type.isNotEmpty) 'type': type,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await _client.get(
      ApiConstants.assetMovements(assetId),
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => AssetMovement.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<AssetMovement> createMovement(
    int assetId, {
    required String type,
    required int quantity,
    String? description,
    String? movementAt,
  }) async {
    final response = await _client.post(
      ApiConstants.assetMovements(assetId),
      data: {
        'type': type,
        'quantity': quantity,
        if (description != null && description.isNotEmpty) 'description': description,
        if (movementAt != null) 'movement_at': movementAt,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return AssetMovement.fromJson(data['data'] as Map<String, dynamic>);
  }
}
