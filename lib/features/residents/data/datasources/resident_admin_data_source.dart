import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/admin_resident_model.dart';

class ResidentAdminDataSource {
  ResidentAdminDataSource(this._client);
  final DioClient _client;

  Future<(List<AdminResidentListItem>, Map<String, dynamic>)> getResidents({
    String? search,
    String? status,
    bool? hasAccount,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (hasAccount != null) 'has_account': hasAccount ? '1' : '0',
    };
    final response = await _client.get(
      ApiConstants.residents,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => AdminResidentListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<AdminResident> getResident(int id) async {
    final response = await _client.get(ApiConstants.residentDetail(id));
    final data = response.data as Map<String, dynamic>;
    return AdminResident.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminResident> createResident(Map<String, dynamic> body) async {
    final response = await _client.post(ApiConstants.residents, data: body);
    final data = response.data as Map<String, dynamic>;
    return AdminResident.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminResident> updateResident(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      ApiConstants.residentDetail(id),
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return AdminResident.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<int>> downloadKtpFile(int residentId) async {
    return _client.downloadBytes(ApiConstants.residentKtpFile(residentId));
  }

  Future<List<int>> downloadKkFile(int residentId) async {
    return _client.downloadBytes(ApiConstants.residentKkFile(residentId));
  }

  Future<void> createAccount(int residentId, Map<String, dynamic> body) async {
    await _client.post(ApiConstants.residentAccount(residentId), data: body);
  }
}
