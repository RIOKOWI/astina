import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/resident_model.dart';

class MeResidentDataSource {
  MeResidentDataSource(this._client);
  final DioClient _client;

  Future<MeResident?> getMeResident() async {
    final response = await _client.get(ApiConstants.resident);
    final data = response.data as Map<String, dynamic>;
    if (data['data'] == null) return null;
    return MeResident.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<MeResident> updateMeResident(Map<String, dynamic> body) async {
    final response = await _client.patch(ApiConstants.resident, data: body);
    final data = response.data as Map<String, dynamic>;
    return MeResident.fromJson(data['data'] as Map<String, dynamic>);
  }
}
