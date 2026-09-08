import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/letter_model.dart';
import '../models/letter_type_model.dart';

class LetterRemoteDataSource {
  final DioClient _dioClient;

  LetterRemoteDataSource(this._dioClient);

  // === WARGA ===

  Future<List<LetterTypeModel>> getLetterTypes() async {
    if (kDebugMode)
      developer.log('Fetching letter types', name: 'LetterDataSource');
    final response = await _dioClient.get(ApiConstants.letterTypes);
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => LetterTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LetterModel>> getMyLetters({
    String? status,
    int perPage = 15,
  }) async {
    if (kDebugMode)
      developer.log('Fetching my letters', name: 'LetterDataSource');
    final queryParams = <String, dynamic>{'per_page': perPage};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await _dioClient.get(
      ApiConstants.myLetters,
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => LetterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LetterModel> submitLetter({
    required int letterTypeId,
    required Map<String, dynamic> fields,
    String? purpose,
  }) async {
    if (kDebugMode)
      developer.log(
        'Submitting letter type=$letterTypeId',
        name: 'LetterDataSource',
      );
    final response = await _dioClient.post(
      ApiConstants.letters,
      data: {
        'letter_type_id': letterTypeId,
        'fields': fields,
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      },
    );
    return LetterModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<LetterModel> getLetterDetail(int id) async {
    if (kDebugMode)
      developer.log('Fetching letter detail: $id', name: 'LetterDataSource');
    final response = await _dioClient.get('${ApiConstants.letters}/$id');
    return LetterModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // === RT ADMIN ===

  Future<List<LetterModel>> getPendingLetters({int perPage = 15}) async {
    if (kDebugMode)
      developer.log('Fetching pending letters', name: 'LetterDataSource');
    final response = await _dioClient.get(
      ApiConstants.lettersPending,
      queryParameters: {'per_page': perPage},
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => LetterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LetterModel> approveLetter(int id) async {
    if (kDebugMode)
      developer.log('Approving letter: $id', name: 'LetterDataSource');
    final response = await _dioClient.post(
      '${ApiConstants.letters}/$id/approve',
    );
    return LetterModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<LetterModel> rejectLetter(int id, String reason) async {
    if (kDebugMode)
      developer.log('Rejecting letter: $id', name: 'LetterDataSource');
    final response = await _dioClient.post(
      '${ApiConstants.letters}/$id/reject',
      data: {'reason': reason},
    );
    return LetterModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<int>> downloadDocument(int letterId) async {
    if (kDebugMode)
      developer.log(
        'Downloading document for letter: $letterId',
        name: 'LetterDataSource',
      );
    return _dioClient.downloadBytes(
      '${ApiConstants.letters}/$letterId/document',
    );
  }

  // === RT ADMIN: LETTER TYPES ===

  Future<LetterTypeModel> createLetterType(Map<String, dynamic> data) async {
    if (kDebugMode)
      developer.log('Creating letter type', name: 'LetterDataSource');
    final response = await _dioClient.post(
      ApiConstants.letterTypes,
      data: data,
    );
    return LetterTypeModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<LetterTypeModel> updateLetterType(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log('Updating letter type: $id', name: 'LetterDataSource');
    final response = await _dioClient.put(
      '${ApiConstants.letterTypes}/$id',
      data: data,
    );
    return LetterTypeModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteLetterType(int id) async {
    if (kDebugMode)
      developer.log('Deleting letter type: $id', name: 'LetterDataSource');
    await _dioClient.delete('${ApiConstants.letterTypes}/$id');
  }

  Future<LetterFieldModel> addField(
    int letterTypeId,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log(
        'Adding field to letter type: $letterTypeId',
        name: 'LetterDataSource',
      );
    final response = await _dioClient.post(
      '${ApiConstants.letterTypes}/$letterTypeId/fields',
      data: data,
    );
    return LetterFieldModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<LetterFieldModel> updateField(
    int letterTypeId,
    int fieldId,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      developer.log(
        'Updating field $fieldId in letter type: $letterTypeId',
        name: 'LetterDataSource',
      );
    final response = await _dioClient.put(
      '${ApiConstants.letterTypes}/$letterTypeId/fields/$fieldId',
      data: data,
    );
    return LetterFieldModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteField(int letterTypeId, int fieldId) async {
    if (kDebugMode)
      developer.log(
        'Deleting field $fieldId from letter type: $letterTypeId',
        name: 'LetterDataSource',
      );
    await _dioClient.delete(
      '${ApiConstants.letterTypes}/$letterTypeId/fields/$fieldId',
    );
  }

  Future<List<int>> generateDocument(int letterId) async {
    if (kDebugMode)
      developer.log(
        'Generating document for letter: $letterId',
        name: 'LetterDataSource',
      );
    return _dioClient.downloadBytes(ApiConstants.generateDocument(letterId));
  }
}
