import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSource(this._dioClient);

  Future<List<NotificationModel>> getNotifications({int perPage = 20}) async {
    if (kDebugMode)
      developer.log(
        'Fetching notifications',
        name: 'NotificationRemoteDataSource',
      );
    final response = await _dioClient.get(
      ApiConstants.notifications,
      queryParameters: {'per_page': perPage},
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    if (kDebugMode)
      developer.log(
        'Marking notification as read: $id',
        name: 'NotificationRemoteDataSource',
      );
    await _dioClient.patch('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllAsRead() async {
    if (kDebugMode)
      developer.log(
        'Marking all notifications as read',
        name: 'NotificationRemoteDataSource',
      );
    await _dioClient.patch('${ApiConstants.notifications}/read-all');
  }
}
