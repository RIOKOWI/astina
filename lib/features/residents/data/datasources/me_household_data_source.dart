import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/household_model.dart';

final _dsLog = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 0),
);

class MeHouseholdDataSource {
  MeHouseholdDataSource(this._client);

  final DioClient _client;

  Future<HouseholdModel?> getMyHousehold() async {
    try {
      final response = await _client.get(ApiConstants.household);
      final data = response.data as Map<String, dynamic>;
      final householdData = data['data'] as Map<String, dynamic>?;
      if (householdData == null) return null;
      return HouseholdModel.fromJson(householdData);
    } catch (e, st) {
      if (kDebugMode) {
        _dsLog.e(
          '[MeHouseholdDataSource] getMyHousehold failed',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }
}
