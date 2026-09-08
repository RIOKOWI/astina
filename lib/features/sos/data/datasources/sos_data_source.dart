import 'package:geolocator/geolocator.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/sos_alert_model.dart';

class SosDataSource {
  final DioClient _dio;

  SosDataSource(this._dio);

  Future<SosAlertModel> triggerSos({
    required double latitude,
    required double longitude,
    String? locationText,
  }) async {
    final response = await _dio.post(
      ApiConstants.sosAlerts,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (locationText != null) 'location_text': locationText,
      },
    );
    return SosAlertModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<SosAlertModel>> getActiveAlerts() async {
    final response = await _dio.get(ApiConstants.sosActive);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SosAlertModel> getAlertDetail(int sosId) async {
    final response = await _dio.get('${ApiConstants.sosAlerts}/$sosId');
    return SosAlertModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> respondToSos(int sosId, String response) async {
    await _dio.post(
      '${ApiConstants.sosAlerts}/$sosId/responses',
      data: {'response': response},
    );
  }

  Future<void> resolveSos(int sosId) async {
    await _dio.post('${ApiConstants.sosAlerts}/$sosId/resolve');
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Lokasi tidak aktif');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi dinonaktifkan permanen');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
