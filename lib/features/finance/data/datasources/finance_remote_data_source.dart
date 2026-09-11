import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/cash_summary_model.dart';
import '../models/finance_transaction_model.dart';
import '../models/payment_model.dart';
import '../models/due_model.dart';

class FinanceRemoteDataSource {
  FinanceRemoteDataSource(this._client);

  final DioClient _client;

  List<dynamic> _paginatedItems(Map<String, dynamic> responseData) {
    final body = responseData['data'];
    if (body is Map) {
      final items = body['data'];
      if (items is List<dynamic>) return items;
    }
    if (body is List<dynamic>) return body;
    return const [];
  }

  Map<String, dynamic> _paginationMeta(Map<String, dynamic> responseData) {
    final meta = responseData['meta'];
    if (meta is Map) return Map<String, dynamic>.from(meta);
    return {};
  }

  Future<CashSummary> getSummary({String? month}) async {
    final response = await _client.get(
      ApiConstants.financeSummary,
      queryParameters: month != null ? {'month': month} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return CashSummary.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<(List<FinanceTransaction>, Map<String, dynamic>)> getTransactions({
    String? type,
    String? category,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.financeTransactions,
      queryParameters: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (category != null && category.isNotEmpty) 'category': category,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = _paginatedItems(data)
        .map((e) => FinanceTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = _paginationMeta(data);
    return (list, meta);
  }

  Future<FinanceTransaction> createTransaction({
    required String type,
    required int amount,
    required String category,
    String? description,
    String? transactionAt,
  }) async {
    final response = await _client.post(
      ApiConstants.financeTransactions,
      data: {
        'type': type,
        'amount': amount,
        'category': category,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (transactionAt != null) 'transaction_at': transactionAt,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return FinanceTransaction.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<(List<PaymentModel>, Map<String, dynamic>)> getPendingPayments({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.pendingPayments,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = _paginatedItems(
      data,
    ).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
    final meta = _paginationMeta(data);
    return (list, meta);
  }

  Future<PaymentModel> approvePayment(int paymentId) async {
    final response = await _client.post(ApiConstants.paymentApprove(paymentId));
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PaymentModel> rejectPayment(int paymentId, String reason) async {
    final response = await _client.post(
      ApiConstants.paymentReject(paymentId),
      data: {'reason': reason},
    );
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<(List<DueModel>, Map<String, dynamic>)> getDues({
    bool includeInactive = false,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.dues,
      queryParameters: {
        'include_inactive': includeInactive,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = _paginatedItems(
      data,
    ).map((e) => DueModel.fromJson(e as Map<String, dynamic>)).toList();
    final meta = _paginationMeta(data);
    return (list, meta);
  }

  Future<DueModel> createDue({
    required String name,
    required int amount,
    String? description,
    String? frequency,
    String? startDate,
    String? endDate,
    bool isActive = true,
  }) async {
    final response = await _client.post(
      ApiConstants.dues,
      data: {
        'name': name,
        'amount': amount,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (frequency != null) 'frequency': frequency,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        'is_active': isActive,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return DueModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<DueModel> getDue(int dueId) async {
    final response = await _client.get(ApiConstants.dueDetail(dueId));
    final data = response.data as Map<String, dynamic>;
    return DueModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<DueModel> updateDue(
    int dueId, {
    String? name,
    int? amount,
    String? description,
    String? frequency,
    String? startDate,
    String? endDate,
    bool? isActive,
    bool includeDescription = false,
    bool includeStartDate = false,
    bool includeEndDate = false,
  }) async {
    final response = await _client.put(
      ApiConstants.dueDetail(dueId),
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (includeDescription || description != null)
          'description': description,
        if (frequency != null) 'frequency': frequency,
        if (includeStartDate || startDate != null) 'start_date': startDate,
        if (includeEndDate || endDate != null) 'end_date': endDate,
        if (isActive != null) 'is_active': isActive,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return DueModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteDue(int dueId) async {
    await _client.delete(ApiConstants.dueDetail(dueId));
  }

  Future<int> generateBills({required int year, required int month}) async {
    final response = await _client.post(
      ApiConstants.generateBills,
      data: {'year': year, 'month': month},
    );
    final data = response.data as Map<String, dynamic>;
    final result = data['data'];
    return result is Map ? result['created'] as int? ?? 0 : 0;
  }

  Future<(List<DueBillModel>, Map<String, dynamic>)> getDueBills(
    int dueId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.dueBillsList(dueId),
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = _paginatedItems(
      data,
    ).map((e) => DueBillModel.fromJson(e as Map<String, dynamic>)).toList();
    return (list, _paginationMeta(data));
  }

  // --- Warga endpoints ---

  Future<(List<DueBillModel>, Map<String, dynamic>)> getMyDueBills({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.dueBills,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = _paginatedItems(
      data,
    ).map((e) => DueBillModel.fromJson(e as Map<String, dynamic>)).toList();
    final meta = _paginationMeta(data);
    return (list, meta);
  }

  Future<(List<PaymentModel>, Map<String, dynamic>)> getMyPayments({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get(
      ApiConstants.myPayments,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data as Map<String, dynamic>;
    final list = _paginatedItems(
      data,
    ).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
    final meta = _paginationMeta(data);
    return (list, meta);
  }

  Future<PaymentModel> createPayment({
    required int dueBillId,
    required int amount,
    String? method,
  }) async {
    final response = await _client.post(
      ApiConstants.payments,
      data: {
        'due_bill_id': dueBillId,
        'amount': amount,
        if (method != null) 'method': method,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PaymentModel> getPayment(int paymentId) async {
    final response = await _client.get(ApiConstants.paymentDetail(paymentId));
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PaymentProof> uploadPaymentProof(
    int paymentId,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _client.postFormData(
      ApiConstants.paymentProof(paymentId),
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return PaymentProof.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<int>> downloadPaymentProof(String url) {
    return _client.downloadBytes(url);
  }
}

class DueBillModel {
  final int id;
  final int dueId;
  final DueInfo? due;
  final int residentId;
  final Resident? resident;
  final int amount;
  final String dueDate;
  final String status;
  final DateTime? createdAt;

  const DueBillModel({
    required this.id,
    required this.dueId,
    this.due,
    required this.residentId,
    this.resident,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.createdAt,
  });

  factory DueBillModel.fromJson(Map<String, dynamic> json) {
    return DueBillModel(
      id: json['id'] as int,
      dueId: json['due_id'] as int,
      due: json['due'] != null
          ? DueInfo.fromJson(json['due'] as Map<String, dynamic>)
          : null,
      residentId: json['resident_id'] as int,
      resident: json['resident'] != null
          ? Resident.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      amount: json['amount'] as int,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'unpaid':
        return 'Belum Bayar';
      case 'pending':
        return 'Menunggu';
      case 'approved':
      case 'paid':
        return 'Lunas';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  bool get isUnpaid => status == 'unpaid';
  bool get isPending => status == 'pending';
}
