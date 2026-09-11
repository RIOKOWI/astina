import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/activity_model.dart';

class ActivityDataSource {
  ActivityDataSource(this._client);
  final DioClient _client;

  Future<(List<Activity>, Map<String, dynamic>)> getActivities({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await _client.get(
      ApiConstants.activities,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<Activity> getActivity(int id) async {
    final response = await _client.get(ApiConstants.activityDetail(id));
    final data = response.data as Map<String, dynamic>;
    return Activity.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Activity> createActivity({
    required String title,
    String? description,
    String? location,
    required String startAt,
    String? endAt,
    String? status,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      'start_at': startAt,
      if (endAt != null && endAt.isNotEmpty) 'end_at': endAt,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await _client.post(ApiConstants.activities, data: body);
    final data = response.data as Map<String, dynamic>;
    return Activity.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Activity> updateActivity(
    int id, {
    String? title,
    String? description,
    String? location,
    String? startAt,
    String? endAt,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (title != null && title.isNotEmpty) 'title': title,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await _client.put(
      ApiConstants.activityDetail(id),
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return Activity.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteActivity(int id) async {
    await _client.delete(ApiConstants.activityDetail(id));
  }

  Future<void> markAsRead(int id) async {
    await _client.post(ApiConstants.activityRead(id));
  }

  Future<ActivityAttachment> uploadAttachment(int activityId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _client.postFormData(
      ApiConstants.activityAttachments(activityId),
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return ActivityAttachment.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAttachment(int activityId, int attachmentId) async {
    await _client.delete(
      ApiConstants.activityAttachment(activityId, attachmentId),
    );
  }

  Future<List<int>> downloadAttachment(String url) async {
    return _client.downloadBytes(url);
  }
}
