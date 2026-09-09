import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/cash_summary_model.dart';
import '../models/finance_transaction_model.dart';
import '../models/payment_model.dart';
import '../models/due_model.dart';

class FinanceRemoteDataSource {
  FinanceRemoteDataSource(this._client);

  final DioClient _client;

  Future<CashSummary> getSummary({String? month}) async {
    final response = await _client.get(
      ApiConstants.financeSummary,
      queryParameters: month != null ? {'month': month} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return CashSummary.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<FinanceTransaction>> getTransactions({
    String? type,
    String? dateFrom,
    String? dateTo,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.financeTransactions,
      queryParameters: {
        if (type != null) 'type': type,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        'per_page': perPage,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data']['data'] as List<dynamic>;
    return list
        .map((e) => FinanceTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentModel>> getPendingPayments({int perPage = 15}) async {
    final response = await _client.get(
      ApiConstants.pendingPayments,
      queryParameters: {'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data']['data'] as List<dynamic>;
    return list
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentModel> approvePayment(int paymentId) async {
    final response = await _client.post('/payments/$paymentId/approve');
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PaymentModel> rejectPayment(int paymentId, String reason) async {
    final response = await _client.post(
      '/payments/$paymentId/reject',
      data: {'reason': reason},
    );
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<DueModel>> getDues({bool includeInactive = false}) async {
    final response = await _client.get(
      ApiConstants.dues,
      queryParameters: {'include_inactive': includeInactive},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data']['data'] as List<dynamic>;
    return list
        .map((e) => DueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> generateBills({required int year, required int month}) async {
    await _client.post(
      ApiConstants.generateBills,
      data: {'year': year, 'month': month},
    );
  }
}
