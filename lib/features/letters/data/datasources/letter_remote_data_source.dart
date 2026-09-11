import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/letter_model.dart';
import '../models/letter_type_model.dart';

class LetterRemoteDataSource {
  LetterRemoteDataSource(this._client);
  final DioClient _client;

  Future<List<LetterType>> getLetterTypes() async {
    final response = await _client.get(ApiConstants.letterTypes);
    final data = response.data as Map<String, dynamic>;
    final listData = data['data'];
    final items = listData is List
        ? listData
        : (listData as Map<String, dynamic>)['data'];
    return (items as List<dynamic>)
        .map((e) => LetterType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LetterType> getLetterTypeDetail(int id) async {
    final response = await _client.get(ApiConstants.letterType(id));
    final data = response.data as Map<String, dynamic>;
    return LetterType.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<LetterListItem>> getMyLetters({
    String? status,
    int? letterTypeId,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null) 'status': status,
      if (letterTypeId != null) 'letter_type_id': letterTypeId,
    };
    final response = await _client.get(
      ApiConstants.myLetters,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final listData = data['data'];
    final items = listData is List
        ? listData
        : (listData as Map<String, dynamic>)['data'];
    return (items as List<dynamic>)
        .map((e) => LetterListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LetterListItem>> getPendingLetters({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.lettersPending,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final listData = data['data'];
    final items = listData is List
        ? listData
        : (listData as Map<String, dynamic>)['data'];
    return (items as List<dynamic>)
        .map((e) => LetterListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Letter> createLetter({
    required int letterTypeId,
    String? purpose,
    required Map<String, dynamic> fields,
  }) async {
    final body = <String, dynamic>{
      'letter_type_id': letterTypeId,
      if (purpose != null) 'purpose': purpose,
      'fields': fields,
    };
    final response = await _client.post(ApiConstants.letters, data: body);
    final data = response.data as Map<String, dynamic>;
    return Letter.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Letter> getLetter(int id) async {
    final response = await _client.get(ApiConstants.letterDetail(id));
    final data = response.data as Map<String, dynamic>;
    return Letter.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Letter> approveLetter(int id) async {
    final response = await _client.post(ApiConstants.letterApprove(id));
    final data = response.data as Map<String, dynamic>;
    return Letter.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Letter> rejectLetter(int id, String reason) async {
    final response = await _client.post(
      ApiConstants.letterReject(id),
      data: {'reason': reason},
    );
    final data = response.data as Map<String, dynamic>;
    return Letter.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<int>> downloadDocument(int letterId) async {
    return _client.downloadBytes(ApiConstants.letterDocument(letterId));
  }
}
