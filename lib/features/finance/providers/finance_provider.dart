import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/finance_remote_data_source.dart';
import '../data/models/due_bill_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/finance_summary_model.dart';

final financeRemoteDataSourceProvider = Provider<FinanceRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return FinanceRemoteDataSource(dioClient);
});

// Due Bills
final dueBillsProvider = FutureProvider.autoDispose<List<DueBillModel>>((
  ref,
) async {
  final datasource = ref.watch(financeRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading due bills', name: 'Finance');
  return datasource.getDueBills();
});

// Payments
final myPaymentsProvider = FutureProvider.autoDispose<List<PaymentModel>>((
  ref,
) async {
  final datasource = ref.watch(financeRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading my payments', name: 'Finance');
  return datasource.getMyPayments();
});

final paymentDetailProvider = FutureProvider.autoDispose
    .family<PaymentModel, int>((ref, id) async {
      final datasource = ref.watch(financeRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading payment detail: $id', name: 'Finance');
      return datasource.getPaymentDetail(id);
    });

// Cash Transparency
final financeSummaryProvider = FutureProvider.autoDispose<FinanceSummaryModel>((
  ref,
) async {
  final datasource = ref.watch(financeRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading finance summary', name: 'Finance');
  return datasource.getFinanceSummary();
});

final financeTransactionsProvider =
    FutureProvider.autoDispose<List<FinanceTransactionModel>>((ref) async {
      final datasource = ref.watch(financeRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading finance transactions', name: 'Finance');
      return datasource.getFinanceTransactions();
    });

// Notifier for mutations
final financeNotifierProvider =
    AsyncNotifierProvider<FinanceNotifier, FinanceState>(
      () => FinanceNotifier(),
    );

class FinanceState {
  final String? errorMessage;
  final bool isSubmitting;

  const FinanceState({this.errorMessage, this.isSubmitting = false});

  FinanceState copyWith({String? errorMessage, bool? isSubmitting}) {
    return FinanceState(
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class FinanceNotifier extends AsyncNotifier<FinanceState> {
  @override
  FinanceState build() => const FinanceState();

  Future<PaymentModel?> createPayment({
    required int dueBillId,
    required int amount,
    String? method,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(financeRemoteDataSourceProvider);
      final payment = await datasource.createPayment(
        dueBillId: dueBillId,
        amount: amount,
        method: method,
      );
      ref.invalidate(myPaymentsProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return payment;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to create payment',
          name: 'Finance',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<PaymentProofModel?> uploadPaymentProof({
    required int paymentId,
    required String filePath,
    required String fileName,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(financeRemoteDataSourceProvider);
      final proof = await datasource.uploadPaymentProof(
        paymentId: paymentId,
        filePath: filePath,
        fileName: fileName,
      );
      ref.invalidate(paymentDetailProvider(paymentId));
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return proof;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to upload payment proof',
          name: 'Finance',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }
}
