import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/complaint_model.dart';

class ComplaintDataSource {
  ComplaintDataSource(this._client);
  final DioClient _client;

  Future<(List<Complaint>, Map<String, dynamic>)> getComplaints({
    String? search,
    String? status,
    String? category,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final response = await _client.get(
      ApiConstants.complaints,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, data['meta'] as Map<String, dynamic>? ?? {});
  }

  Future<Complaint> getComplaint(int id) async {
    final response = await _client.get(ApiConstants.complaintDetail(id));
    final data = response.data as Map<String, dynamic>;
    return Complaint.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Complaint> createComplaint({
    required String title,
    String? description,
    required String category,
  }) async {
    final response = await _client.post(
      ApiConstants.complaints,
      data: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'category': category,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return Complaint.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Complaint> updateStatus(
    int id, {
    required String status,
    String? rejectionReason,
    int? assignedTo,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      if (rejectionReason != null && rejectionReason.isNotEmpty)
        'rejection_reason': rejectionReason,
      if (assignedTo != null) 'assigned_to': assignedTo,
    };
    final response = await _client.patch(
      ApiConstants.complaintStatus(id),
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return Complaint.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ComplaintAttachment> uploadAttachment(int complaintId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _client.postFormData(
      ApiConstants.complaintAttachments(complaintId),
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return ComplaintAttachment.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<int>> downloadAttachment(String url) async {
    return _client.downloadBytes(url);
  }

  Future<void> deleteAttachment(int complaintId, int attachmentId) async {
    await _client.delete(
      ApiConstants.complaintAttachment(complaintId, attachmentId),
    );
  }

  Future<List<ComplaintComment>> getComments(int complaintId) async {
    final response = await _client.get(
      ApiConstants.complaintComments(complaintId),
    );
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => ComplaintComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ComplaintComment> addComment(int complaintId, String comment) async {
    final response = await _client.post(
      ApiConstants.complaintComments(complaintId),
      data: {'comment': comment},
    );
    final data = response.data as Map<String, dynamic>;
    return ComplaintComment.fromJson(data['data'] as Map<String, dynamic>);
  }
}
