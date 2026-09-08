import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/resident_model.dart';
import '../models/household_model.dart';
import '../models/document_model.dart';

class ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSource(this._dioClient);

  Future<ResidentModel> getResident() async {
    if (kDebugMode)
      developer.log('Fetching resident data', name: 'ProfileRemoteDataSource');
    final response = await _dioClient.get(ApiConstants.resident);
    return ResidentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ResidentModel> updateResident(Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log('Updating resident data', name: 'ProfileRemoteDataSource');
    final response = await _dioClient.patch(ApiConstants.resident, data: data);
    return ResidentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<HouseholdModel> getHousehold() async {
    if (kDebugMode)
      developer.log('Fetching household data', name: 'ProfileRemoteDataSource');
    final response = await _dioClient.get(ApiConstants.household);
    return HouseholdModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<DocumentModel>> getDocuments() async {
    if (kDebugMode)
      developer.log('Fetching documents', name: 'ProfileRemoteDataSource');
    final response = await _dioClient.get(ApiConstants.documents);
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentModel> uploadKtp(String filePath) async {
    if (kDebugMode)
      developer.log('Uploading KTP', name: 'ProfileRemoteDataSource');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dioClient.postFormData(
      '${ApiConstants.documents}/ktp',
      data: formData,
    );
    return DocumentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<DocumentModel> uploadKk(String filePath) async {
    if (kDebugMode)
      developer.log('Uploading KK', name: 'ProfileRemoteDataSource');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dioClient.postFormData(
      '${ApiConstants.documents}/kk',
      data: formData,
    );
    return DocumentModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<int>> downloadKtpFile() async {
    if (kDebugMode)
      developer.log('Downloading KTP file', name: 'ProfileRemoteDataSource');
    return _dioClient.downloadBytes('${ApiConstants.documents}/ktp/file');
  }

  Future<List<int>> downloadKkFile() async {
    if (kDebugMode)
      developer.log('Downloading KK file', name: 'ProfileRemoteDataSource');
    return _dioClient.downloadBytes('${ApiConstants.documents}/kk/file');
  }

  Future<List<int>> downloadDocument(String documentUrl) async {
    if (kDebugMode)
      developer.log(
        'Downloading document: $documentUrl',
        name: 'ProfileRemoteDataSource',
      );
    final response = await _dioClient.dio.get<List<int>>(
      documentUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
