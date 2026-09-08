import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/complaint_model.dart';
import '../models/complaint_comment_model.dart';
import '../models/complaint_attachment_model.dart';

class ComplaintRemoteDataSource {
  final DioClient _dioClient;

  ComplaintRemoteDataSource(this._dioClient);

  Future<List<ComplaintModel>> getComplaints({
    String? search,
    String? status,
    String? category,
    int perPage = 15,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;
    queryParams['per_page'] = perPage;

    if (kDebugMode)
      developer.log('Fetching complaints: $queryParams', name: 'Complaint');

    final response = await _dioClient.get(
      ApiConstants.complaints,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ComplaintModel> getComplaintDetail(int id) async {
    if (kDebugMode)
      developer.log('Fetching complaint detail: $id', name: 'Complaint');

    final response = await _dioClient.get('${ApiConstants.complaints}/$id');
    return ComplaintModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ComplaintModel> createComplaint({
    required String title,
    String? description,
    required String category,
  }) async {
    if (kDebugMode)
      developer.log('Creating complaint: $title', name: 'Complaint');

    final response = await _dioClient.post(
      ApiConstants.complaints,
      data: {'title': title, 'description': description, 'category': category},
    );

    return ComplaintModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ComplaintModel> updateStatus({
    required int complaintId,
    required String status,
    String? rejectionReason,
    int? assignedTo,
  }) async {
    if (kDebugMode)
      developer.log(
        'Updating complaint $complaintId status to $status',
        name: 'Complaint',
      );

    final data = <String, dynamic>{'status': status};
    if (rejectionReason != null) data['rejection_reason'] = rejectionReason;
    if (assignedTo != null) data['assigned_to'] = assignedTo;

    final response = await _dioClient.patch(
      '${ApiConstants.complaints}/$complaintId/status',
      data: data,
    );

    return ComplaintModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ComplaintCommentModel>> getComments(int complaintId) async {
    if (kDebugMode)
      developer.log(
        'Fetching comments for complaint: $complaintId',
        name: 'Complaint',
      );

    final response = await _dioClient.get(
      '${ApiConstants.complaints}/$complaintId/comments',
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map(
          (json) =>
              ComplaintCommentModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ComplaintCommentModel> postComment({
    required int complaintId,
    required String comment,
  }) async {
    if (kDebugMode)
      developer.log(
        'Posting comment on complaint: $complaintId',
        name: 'Complaint',
      );

    final response = await _dioClient.post(
      '${ApiConstants.complaints}/$complaintId/comments',
      data: {'comment': comment},
    );

    return ComplaintCommentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ComplaintAttachmentModel> uploadAttachment({
    required int complaintId,
    required String filePath,
    required String fileName,
  }) async {
    if (kDebugMode)
      developer.log(
        'Uploading attachment to complaint: $complaintId',
        name: 'Complaint',
      );

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dioClient.postFormData(
      '${ApiConstants.complaints}/$complaintId/attachments',
      data: formData,
    );

    return ComplaintAttachmentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteAttachment({
    required int complaintId,
    required int attachmentId,
  }) async {
    if (kDebugMode)
      developer.log(
        'Deleting attachment $attachmentId from complaint $complaintId',
        name: 'Complaint',
      );

    await _dioClient.delete(
      '${ApiConstants.complaints}/$complaintId/attachments/$attachmentId',
    );
  }
}
