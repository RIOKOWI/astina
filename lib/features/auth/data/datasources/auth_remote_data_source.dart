import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<LoginResponse> login(String phone, String password) async {
    final res = await _dioClient.post(
      ApiConstants.login,
      data: {'phone': phone, 'password': password},
    );
    return LoginResponse.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dioClient.post(ApiConstants.logout);
  }

  Future<UserModel> getMe() async {
    final res = await _dioClient.get(ApiConstants.me);
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateMe(Map<String, dynamic> data) async {
    final res = await _dioClient.patch(ApiConstants.me, data: data);
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _dioClient.patch(
      ApiConstants.password,
      data: {'current_password': currentPassword, 'password': newPassword},
    );
  }

  Future<void> registerDeviceToken(String token) async {
    await _dioClient.post(ApiConstants.deviceTokens, data: {'token': token});
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _dioClient.delete('${ApiConstants.deviceTokens}/$token');
  }
}
