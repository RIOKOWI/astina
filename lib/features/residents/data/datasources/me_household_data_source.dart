import 'dart:developer' as developer;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/household_model.dart';

class MeHouseholdDataSource {
  MeHouseholdDataSource(this._client);

  final DioClient _client;

  Future<HouseholdModel?> getMyHousehold() async {
    final response = await _client.get(ApiConstants.household);
    developer.log('household raw response: ${response.data}', name: 'MeHouseholdDS');
    final data = response.data as Map<String, dynamic>;
    developer.log('household data key: ${data.keys.toList()}', name: 'MeHouseholdDS');
    final householdData = data['data'] as Map<String, dynamic>?;
    developer.log('household parsed: $householdData', name: 'MeHouseholdDS');
    if (householdData == null) return null;
    return HouseholdModel.fromJson(householdData);
  }
}
