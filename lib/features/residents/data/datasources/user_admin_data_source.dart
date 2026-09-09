import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/admin_user_model.dart';

class UserAdminDataSource {
  UserAdminDataSource(this._client);
  final DioClient _client;

  Future<(List<AdminUser>, Map<String, dynamic>)> getUsers({
    int page = 1,
    int perPage = 15,
    String? search,
    bool? isActive,
    String? role,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'is_active': isActive ? 1 : 0,
      if (role != null && role.isNotEmpty) 'role': role,
    };
    final response = await _client.get(
      ApiConstants.users,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<AdminUser> getUser(int id) async {
    final response = await _client.get('${ApiConstants.users}/$id');
    final data = response.data as Map<String, dynamic>;
    return AdminUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminUser> updateUser(int id, Map<String, dynamic> body) async {
    final response = await _client.patch(
      '${ApiConstants.users}/$id',
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return AdminUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> resetPassword(
    int userId, {
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post(
      ApiConstants.userResetPassword(userId),
      data: {
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<AdminUser> createAccount(
    int residentId, {
    required String phone,
    String? email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      ApiConstants.residentAccount(residentId),
      data: {
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return AdminUser.fromJson(data['data'] as Map<String, dynamic>);
  }
}
