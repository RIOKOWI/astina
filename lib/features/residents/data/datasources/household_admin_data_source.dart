import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/admin_household_model.dart';

class HouseholdAdminDataSource {
  HouseholdAdminDataSource(this._client);
  final DioClient _client;

  Future<(List<AdminHousehold>, Map<String, dynamic>)> getHouseholds({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.households,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => AdminHousehold.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<AdminHousehold> getHousehold(int id) async {
    final response = await _client.get(ApiConstants.householdDetail(id));
    final data = response.data as Map<String, dynamic>;
    return AdminHousehold.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminHousehold> createHousehold(Map<String, dynamic> body) async {
    final response = await _client.post(ApiConstants.households, data: body);
    final data = response.data as Map<String, dynamic>;
    return AdminHousehold.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminHousehold> updateHousehold(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      ApiConstants.householdDetail(id),
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return AdminHousehold.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminHouseholdMember> addMember(
    int householdId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      ApiConstants.householdMembers(householdId),
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return AdminHouseholdMember.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> removeMember(int householdId, int residentId) async {
    await _client.delete(ApiConstants.householdMember(householdId, residentId));
  }
}
