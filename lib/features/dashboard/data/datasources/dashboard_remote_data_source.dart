import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final DioClient _dio;

  Future<int> getLetterPendingCount() async {
    try {
      final resp = await _dio.get(
        ApiConstants.lettersPending,
        queryParameters: {'per_page': 1},
      );
      if (resp.data['meta'] != null) {
        return resp.data['meta']['total'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getComplaintPendingCount() async {
    try {
      final resp = await _dio.get(
        ApiConstants.complaints,
        queryParameters: {'status': 'submitted', 'per_page': 1},
      );
      if (resp.data['meta'] != null) {
        return resp.data['meta']['total'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getSosActiveCount() async {
    try {
      final resp = await _dio.get(ApiConstants.sosActive);
      if (resp.data['data'] != null) {
        return (resp.data['data'] as List).length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getActivityCount() async {
    try {
      final resp = await _dio.get(
        ApiConstants.activities,
        queryParameters: {'status': 'published', 'per_page': 1},
      );
      if (resp.data['meta'] != null) {
        return resp.data['meta']['total'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getPaymentPendingCount() async {
    try {
      final resp = await _dio.get(
        ApiConstants.pendingPayments,
        queryParameters: {'per_page': 1},
      );
      if (resp.data['meta'] != null) {
        return resp.data['meta']['total'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getCashBalance() async {
    try {
      final resp = await _dio.get(ApiConstants.financeSummary);
      if (resp.data['data'] != null) {
        return resp.data['data']['balance'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getMyDueBillAmount() async {
    try {
      final resp = await _dio.get(
        ApiConstants.dueBills,
        queryParameters: {'per_page': 100},
      );
      if (resp.data['data'] != null) {
        final bills = resp.data['data'] as List;
        int unpaidTotal = 0;
        for (final bill in bills) {
          if (bill['status'] == 'unpaid') {
            unpaidTotal += (bill['amount'] as num?)?.toInt() ?? 0;
          }
        }
        return unpaidTotal;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<DashboardSummary> getSummary() async {
    final results = await Future.wait([
      getLetterPendingCount(),
      getComplaintPendingCount(),
      getSosActiveCount(),
      getActivityCount(),
      getPaymentPendingCount(),
      getCashBalance(),
      getMyDueBillAmount(),
    ]);

    return DashboardSummary(
      letterPendingCount: results[0],
      complaintPendingCount: results[1],
      sosActiveCount: results[2],
      activityCount: results[3],
      paymentPendingCount: results[4],
      cashBalance: results[5],
      myDueBillAmount: results[6],
    );
  }
}
