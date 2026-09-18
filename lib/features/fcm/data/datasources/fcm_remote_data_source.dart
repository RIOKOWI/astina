import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/notification_model.dart';

class FcmRemoteDataSource {
  FcmRemoteDataSource(this._client);
  final DioClient _client;

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceName,
  }) async {
    await _client.post(
      ApiConstants.deviceTokens,
      data: {
        'token': token,
        'platform': platform,
        if (deviceName != null) 'device_name': deviceName,
      },
    );
  }

  Future<void> revokeDeviceToken(String token) async {
    await _client.delete(ApiConstants.deviceToken(token));
  }

  Future<(List<AppNotification>, Map<String, dynamic>)> getNotifications({
    int perPage = 20,
  }) async {
    final response = await _client.get(
      ApiConstants.notifications,
      queryParameters: {'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<void> markAsRead(int notificationId) async {
    await _client.patch(ApiConstants.notificationMarkRead(notificationId));
  }

  Future<void> markAllAsRead() async {
    await _client.patch(ApiConstants.notificationMarkAllRead);
  }
}
