import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/bendahara/due_model.dart';
import '../models/bendahara/expense_model.dart';
import '../models/payment_model.dart';

class BendaharaDataSource {
  final DioClient _dio;

  BendaharaDataSource(this._dio);

  // Pending payments for approval
  Future<List<PaymentModel>> getPendingPayments() async {
    final response = await _dio.get(ApiConstants.pendingPayments);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approvePayment(int paymentId, {String? notes}) async {
    await _dio.post(
      '${ApiConstants.payments}/$paymentId/approve',
      data: {if (notes != null) 'notes': notes},
    );
  }

  Future<void> rejectPayment(int paymentId, String reason) async {
    await _dio.post(
      '${ApiConstants.payments}/$paymentId/reject',
      data: {'reason': reason},
    );
  }

  // Dues management
  Future<List<DueModel>> getDues() async {
    final response = await _dio.get(ApiConstants.dues);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => DueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DueModel> createDue(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.dues, data: data);
    return DueModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DueModel> updateDue(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.dues}/$id', data: data);
    return DueModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteDue(int id) async {
    await _dio.delete('${ApiConstants.dues}/$id');
  }

  Future<int> generateBills({required int year, required int month}) async {
    final response = await _dio.post(
      ApiConstants.generateBills,
      data: {'year': year, 'month': month},
    );
    return response.data['data']['created'] as int;
  }

  Future<Map<String, dynamic>> getDueBillsByDue(int dueId) async {
    final response = await _dio.get(ApiConstants.dueBillsByDue(dueId));
    return response.data as Map<String, dynamic>;
  }

  // Expenses
  Future<List<ExpenseModel>> getExpenses() async {
    final response = await _dio.get(ApiConstants.expenses);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.expenses, data: data);
    return ExpenseModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteExpense(int id) async {
    await _dio.delete('${ApiConstants.expenses}/$id');
  }

  // Manual finance transaction
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      ApiConstants.financeTransactions,
      data: data,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // All payments (for bendahara view)
  Future<List<PaymentModel>> getAllPayments() async {
    final response = await _dio.get(ApiConstants.payments);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
