import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/due_bill_model.dart';
import '../models/payment_model.dart';
import '../models/finance_summary_model.dart';

class FinanceRemoteDataSource {
  final DioClient _dioClient;

  FinanceRemoteDataSource(this._dioClient);

  // Due Bills
  Future<List<DueBillModel>> getDueBills({int perPage = 15}) async {
    if (kDebugMode) developer.log('Fetching due bills', name: 'Finance');

    final response = await _dioClient.get(
      ApiConstants.dueBills,
      queryParameters: {'per_page': perPage},
    );

    final data = response.data['data']['data'] as List<dynamic>;
    return data
        .map((json) => DueBillModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Payments
  Future<List<PaymentModel>> getMyPayments({int perPage = 15}) async {
    if (kDebugMode) developer.log('Fetching my payments', name: 'Finance');

    final response = await _dioClient.get(
      ApiConstants.myPayments,
      queryParameters: {'per_page': perPage},
    );

    final data = response.data['data']['data'] as List<dynamic>;
    return data
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentModel> getPaymentDetail(int id) async {
    if (kDebugMode)
      developer.log('Fetching payment detail: $id', name: 'Finance');

    final response = await _dioClient.get('${ApiConstants.payments}/$id');
    return PaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaymentModel> createPayment({
    required int dueBillId,
    required int amount,
    String? method,
  }) async {
    if (kDebugMode)
      developer.log(
        'Creating payment for due bill: $dueBillId',
        name: 'Finance',
      );

    final response = await _dioClient.post(
      ApiConstants.payments,
      data: {
        'due_bill_id': dueBillId,
        'amount': amount,
        if (method != null) 'method': method,
      },
    );

    return PaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaymentProofModel> uploadPaymentProof({
    required int paymentId,
    required String filePath,
    required String fileName,
  }) async {
    if (kDebugMode)
      developer.log('Uploading payment proof for: $paymentId', name: 'Finance');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dioClient.postFormData(
      '${ApiConstants.payments}/$paymentId/proof',
      data: formData,
    );

    return PaymentProofModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // Cash Transparency
  Future<FinanceSummaryModel> getFinanceSummary({String? month}) async {
    if (kDebugMode) developer.log('Fetching finance summary', name: 'Finance');

    final params = month != null ? {'month': month} : <String, dynamic>{};
    final response = await _dioClient.get(
      ApiConstants.financeSummary,
      queryParameters: params,
    );

    return FinanceSummaryModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<FinanceTransactionModel>> getFinanceTransactions({
    String? type,
    String? category,
    String? dateFrom,
    String? dateTo,
    int perPage = 15,
  }) async {
    if (kDebugMode)
      developer.log('Fetching finance transactions', name: 'Finance');

    final params = <String, dynamic>{'per_page': perPage};
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (dateFrom != null && dateFrom.isNotEmpty) params['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) params['date_to'] = dateTo;

    final response = await _dioClient.get(
      ApiConstants.financeTransactions,
      queryParameters: params,
    );

    final data = response.data['data']['data'] as List<dynamic>;
    return data
        .map(
          (json) =>
              FinanceTransactionModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
