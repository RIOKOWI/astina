import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/rt_resident_model.dart';
import '../models/rt_household_model.dart';
import '../models/rt_user_model.dart';

class RtAdminDataSource {
  final DioClient _dioClient;

  RtAdminDataSource(this._dioClient);

  // === RESIDENTS ===

  Future<List<RtResidentModel>> getResidents({
    String? search,
    String? status,
    bool? hasAccount,
    int perPage = 20,
  }) async {
    if (kDebugMode)
      developer.log(
        'Fetching residents for RT admin',
        name: 'RtAdminDataSource',
      );
    final queryParams = <String, dynamic>{'per_page': perPage};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (hasAccount != null) queryParams['has_account'] = hasAccount;

    final response = await _dioClient.get(
      ApiConstants.residents,
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => RtResidentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RtResidentModel> getResidentDetail(int id) async {
    if (kDebugMode)
      developer.log('Fetching resident detail: $id', name: 'RtAdminDataSource');
    final response = await _dioClient.get('${ApiConstants.residents}/$id');
    return RtResidentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<RtResidentModel> createResident(Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log('Creating resident', name: 'RtAdminDataSource');
    final response = await _dioClient.post(ApiConstants.residents, data: data);
    return RtResidentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<RtResidentModel> updateResident(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log('Updating resident: $id', name: 'RtAdminDataSource');
    final response = await _dioClient.patch(
      '${ApiConstants.residents}/$id',
      data: data,
    );
    return RtResidentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // === HOUSEHOLDS ===

  Future<List<RtHouseholdModel>> getHouseholds({int perPage = 20}) async {
    if (kDebugMode)
      developer.log(
        'Fetching households for RT admin',
        name: 'RtAdminDataSource',
      );
    final response = await _dioClient.get(
      ApiConstants.households,
      queryParameters: {'per_page': perPage},
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => RtHouseholdModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RtHouseholdModel> getHouseholdDetail(int id) async {
    if (kDebugMode)
      developer.log(
        'Fetching household detail: $id',
        name: 'RtAdminDataSource',
      );
    final response = await _dioClient.get('${ApiConstants.households}/$id');
    return RtHouseholdModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<RtHouseholdModel> createHousehold(Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log('Creating household', name: 'RtAdminDataSource');
    final response = await _dioClient.post(ApiConstants.households, data: data);
    return RtHouseholdModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<RtHouseholdModel> updateHousehold(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log('Updating household: $id', name: 'RtAdminDataSource');
    final response = await _dioClient.patch(
      '${ApiConstants.households}/$id',
      data: data,
    );
    return RtHouseholdModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> addHouseholdMember(
    int householdId,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log(
        'Adding member to household: $householdId',
        name: 'RtAdminDataSource',
      );
    await _dioClient.post(
      '${ApiConstants.households}/$householdId/members',
      data: data,
    );
  }

  Future<void> removeHouseholdMember(int householdId, int residentId) async {
    if (kDebugMode)
      developer.log(
        'Removing member $residentId from household: $householdId',
        name: 'RtAdminDataSource',
      );
    await _dioClient.delete(
      '${ApiConstants.households}/$householdId/members/$residentId',
    );
  }

  // === USERS ===

  Future<List<RtUserModel>> getUsers({
    String? search,
    bool? isActive,
    String? role,
    int perPage = 20,
  }) async {
    if (kDebugMode)
      developer.log('Fetching users for RT admin', name: 'RtAdminDataSource');
    final queryParams = <String, dynamic>{'per_page': perPage};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (isActive != null) queryParams['is_active'] = isActive;
    if (role != null && role.isNotEmpty) queryParams['role'] = role;

    final response = await _dioClient.get(
      ApiConstants.users,
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => RtUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RtUserModel> getUserDetail(int id) async {
    if (kDebugMode)
      developer.log('Fetching user detail: $id', name: 'RtAdminDataSource');
    final response = await _dioClient.get('${ApiConstants.users}/$id');
    return RtUserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RtUserModel> updateUser(int id, Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log('Updating user: $id', name: 'RtAdminDataSource');
    final response = await _dioClient.patch(
      '${ApiConstants.users}/$id',
      data: data,
    );
    return RtUserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RtUserModel> createResidentAccount(
    int residentId,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log(
        'Creating account for resident: $residentId',
        name: 'RtAdminDataSource',
      );
    final response = await _dioClient.post(
      ApiConstants.residentAccount(residentId),
      data: data,
    );
    return RtUserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> resetUserPassword(int userId, Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log(
        'Resetting password for user: $userId',
        name: 'RtAdminDataSource',
      );
    await _dioClient.post(ApiConstants.userResetPassword(userId), data: data);
  }
}
