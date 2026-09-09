import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/household_model.dart';

class MyRemoteDataSource {
  MyRemoteDataSource(this._client);

  final DioClient _client;

  Future<HouseholdModel?> getMyHousehold() async {
    final response = await _client.get(ApiConstants.household);
    final data = response.data as Map<String, dynamic>;
    if (data['data'] == null) return null;
    return HouseholdModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
