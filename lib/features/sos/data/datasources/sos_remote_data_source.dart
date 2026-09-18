import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/sos_alert_model.dart';

class SosRemoteDataSource {
  SosRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<SosAlertModel>> getActiveAlerts() async {
    final response = await _client.get(ApiConstants.sosActive);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SosAlertModel> getAlert(int id) async {
    final response = await _client.get('${ApiConstants.sosAlerts}/$id');
    final data = response.data as Map<String, dynamic>;
    return SosAlertModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<SosAlertModel> createAlert({
    required double latitude,
    required double longitude,
    String? locationText,
  }) async {
    final response = await _client.post(
      ApiConstants.sosAlerts,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (locationText != null) 'location_text': locationText,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return SosAlertModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<SosAlertModel> resolveAlert(int id) async {
    final response = await _client.post(
      '${ApiConstants.sosAlerts}/$id/resolve',
    );
    final data = response.data as Map<String, dynamic>;
    return SosAlertModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<SosResponse> respondToAlert(int id, String response) async {
    final res = await _client.post(
      '${ApiConstants.sosAlerts}/$id/responses',
      data: {'response': response},
    );
    final data = res.data as Map<String, dynamic>;
    return SosResponse.fromJson(data['data'] as Map<String, dynamic>);
  }
}
