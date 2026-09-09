import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/document_model.dart';

class MeDocumentDataSource {
  MeDocumentDataSource(this._client);
  final DioClient _client;

  Future<MeDocument?> getMyDocuments() async {
    final response = await _client.get(ApiConstants.documents);
    final data = response.data as Map<String, dynamic>;
    if (data['data'] == null) return null;
    return MeDocument.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<MeDocumentFile> uploadKtp(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _client.postFormData(
      ApiConstants.meKtp,
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return MeDocumentFile.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<MeDocumentFile> uploadKk(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _client.postFormData(
      ApiConstants.meKk,
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return MeDocumentFile.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<int>> downloadKtp() async {
    return _client.downloadBytes(ApiConstants.meKtpFile);
  }

  Future<List<int>> downloadKk() async {
    return _client.downloadBytes(ApiConstants.meKkFile);
  }
}
