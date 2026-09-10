import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/household_model.dart';

class MyRemoteDataSource {
  MyRemoteDataSource(this._client);

  final DioClient _client;

  Future<HouseholdModel?> getMyHousehold() async {
    final response = await _client.get(ApiConstants.household);
    final data = response.data as Map<String, dynamic>;

    // Response format: {success, message, data: {...}}
    final householdData = data['data'];
    if (householdData == null) return null;

    if (householdData is! Map<String, dynamic>) {
      throw Exception('Format response tidak valid: data bukan object');
    }

    // Some API versions wrap household in a 'household' key
    final inner = householdData.containsKey('household')
        ? householdData['household'] as Map<String, dynamic>
        : householdData;

    if (inner == null) return null;

    return HouseholdModel.fromJson(inner);
  }
}
