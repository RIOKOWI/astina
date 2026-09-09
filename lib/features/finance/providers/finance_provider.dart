import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/finance_remote_data_source.dart';
import '../data/models/cash_summary_model.dart';
import '../data/models/finance_transaction_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/due_model.dart';

final financeRemoteDataSourceProvider = Provider<FinanceRemoteDataSource>((
  ref,
) {
  return FinanceRemoteDataSource(ref.watch(dioClientProvider));
});

final financeSummaryProvider = FutureProvider.autoDispose
    .family<CashSummary, String?>((ref, month) async {
      final ds = ref.watch(financeRemoteDataSourceProvider);
      return ds.getSummary(month: month);
    });

final financeTransactionsProvider = FutureProvider.autoDispose
    .family<List<FinanceTransaction>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final ds = ref.watch(financeRemoteDataSourceProvider);
      return ds.getTransactions(
        type: filters['type'],
        dateFrom: filters['dateFrom'],
        dateTo: filters['dateTo'],
      );
    });

final pendingPaymentsProvider = FutureProvider.autoDispose<List<PaymentModel>>((
  ref,
) async {
  final ds = ref.watch(financeRemoteDataSourceProvider);
  return ds.getPendingPayments();
});

final duesProvider = FutureProvider.autoDispose<List<DueModel>>((ref) async {
  final ds = ref.watch(financeRemoteDataSourceProvider);
  return ds.getDues();
});
