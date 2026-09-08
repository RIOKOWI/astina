import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/activity_model.dart';

class ActivityRemoteDataSource {
  final DioClient _dioClient;

  ActivityRemoteDataSource(this._dioClient);

  Future<List<ActivityModel>> getActivities({
    String? search,
    String? status,
    int perPage = 15,
  }) async {
    if (kDebugMode)
      developer.log('Fetching activities', name: 'ActivityRemoteDataSource');
    final queryParams = <String, dynamic>{'per_page': perPage};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _dioClient.get(
      ApiConstants.activities,
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ActivityModel> getActivityDetail(int id) async {
    if (kDebugMode)
      developer.log(
        'Fetching activity detail: $id',
        name: 'ActivityRemoteDataSource',
      );
    final response = await _dioClient.get('${ApiConstants.activities}/$id');
    return ActivityModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> markAsRead(int id) async {
    if (kDebugMode)
      developer.log(
        'Marking activity as read: $id',
        name: 'ActivityRemoteDataSource',
      );
    await _dioClient.post('${ApiConstants.activities}/$id/read');
  }

  // === RT ADMIN ===

  Future<ActivityModel> createActivity(Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log('Creating activity', name: 'ActivityRemoteDataSource');
    final response = await _dioClient.post(ApiConstants.activities, data: data);
    return ActivityModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ActivityModel> updateActivity(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log('Updating activity: $id', name: 'ActivityRemoteDataSource');
    final response = await _dioClient.put(
      '${ApiConstants.activities}/$id',
      data: data,
    );
    return ActivityModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteActivity(int id) async {
    if (kDebugMode)
      developer.log('Deleting activity: $id', name: 'ActivityRemoteDataSource');
    await _dioClient.delete('${ApiConstants.activities}/$id');
  }

  Future<ActivityAttachment> uploadAttachment(
    int activityId,
    String filePath,
    String fileName,
  ) async {
    if (kDebugMode)
      developer.log(
        'Uploading attachment to activity: $activityId',
        name: 'ActivityRemoteDataSource',
      );
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dioClient.postFormData(
      '${ApiConstants.activities}/$activityId/attachments',
      data: formData,
    );
    return ActivityAttachment.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteAttachment(int activityId, int attachmentId) async {
    if (kDebugMode)
      developer.log(
        'Deleting attachment $attachmentId from activity $activityId',
        name: 'ActivityRemoteDataSource',
      );
    await _dioClient.delete(
      '${ApiConstants.activities}/$activityId/attachments/$attachmentId',
    );
  }
}
