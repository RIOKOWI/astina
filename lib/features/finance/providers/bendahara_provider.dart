import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/bendahara_data_source.dart';
import '../data/models/bendahara/due_model.dart';
import '../data/models/bendahara/expense_model.dart';
import '../data/models/payment_model.dart';

final bendaharaDataSourceProvider = Provider<BendaharaDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BendaharaDataSource(dioClient);
});

// Pending payments
final pendingPaymentsProvider = FutureProvider.autoDispose<List<PaymentModel>>((
  ref,
) async {
  final datasource = ref.watch(bendaharaDataSourceProvider);
  if (kDebugMode) developer.log('Loading pending payments', name: 'Bendahara');
  return datasource.getPendingPayments();
});

// All payments
final allPaymentsProvider = FutureProvider.autoDispose<List<PaymentModel>>((
  ref,
) async {
  final datasource = ref.watch(bendaharaDataSourceProvider);
  if (kDebugMode) developer.log('Loading all payments', name: 'Bendahara');
  return datasource.getAllPayments();
});

// Dues
final duesProvider = FutureProvider.autoDispose<List<DueModel>>((ref) async {
  final datasource = ref.watch(bendaharaDataSourceProvider);
  if (kDebugMode) developer.log('Loading dues', name: 'Bendahara');
  return datasource.getDues();
});

// Expenses
final expensesProvider = FutureProvider.autoDispose<List<ExpenseModel>>((
  ref,
) async {
  final datasource = ref.watch(bendaharaDataSourceProvider);
  if (kDebugMode) developer.log('Loading expenses', name: 'Bendahara');
  return datasource.getExpenses();
});

// Bendahara notifier
final bendaharaNotifierProvider =
    AsyncNotifierProvider<BendaharaNotifier, BendaharaState>(
      () => BendaharaNotifier(),
    );

class BendaharaState {
  final String? errorMessage;
  final bool isSubmitting;

  const BendaharaState({this.errorMessage, this.isSubmitting = false});

  BendaharaState copyWith({String? errorMessage, bool? isSubmitting}) {
    return BendaharaState(
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class BendaharaNotifier extends AsyncNotifier<BendaharaState> {
  @override
  BendaharaState build() => const BendaharaState();

  Future<void> approvePayment(int paymentId, {String? notes}) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      await datasource.approvePayment(paymentId, notes: notes);
      ref.invalidate(pendingPaymentsProvider);
      ref.invalidate(allPaymentsProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to approve payment',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> rejectPayment(int paymentId, String reason) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      await datasource.rejectPayment(paymentId, reason);
      ref.invalidate(pendingPaymentsProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to reject payment',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
    }
  }

  Future<DueModel?> createDue({
    required String name,
    required int amount,
    String? description,
    String? frequency,
    String? startDate,
    String? endDate,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      final due = await datasource.createDue({
        'name': name,
        'amount': amount,
        if (description != null) 'description': description,
        if (frequency != null) 'frequency': frequency,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      });
      ref.invalidate(duesProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return due;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to create due',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<DueModel?> updateDue(
    int id, {
    required String name,
    required int amount,
    String? description,
    String? frequency,
    bool? isActive,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      final due = await datasource.updateDue(id, {
        'name': name,
        'amount': amount,
        if (description != null) 'description': description,
        if (frequency != null) 'frequency': frequency,
        if (isActive != null) 'is_active': isActive,
      });
      ref.invalidate(duesProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return due;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to update due',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<void> deleteDue(int id) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      await datasource.deleteDue(id);
      ref.invalidate(duesProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to delete due',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
    }
  }

  Future<ExpenseModel?> createExpense({
    required String description,
    required int amount,
    required String category,
    required DateTime expenseDate,
    String? notes,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      final expense = await datasource.createExpense({
        'description': description,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
      });
      ref.invalidate(expensesProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return expense;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to create expense',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<void> deleteExpense(int id) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      await datasource.deleteExpense(id);
      ref.invalidate(expensesProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to delete expense',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
    }
  }

  Future<int?> generateBills({required int year, required int month}) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      final created = await datasource.generateBills(year: year, month: month);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return created;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to generate bills',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDueBillsByDue(int dueId) async {
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      return await datasource.getDueBillsByDue(dueId);
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to get due bills',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      return null;
    }
  }

  Future<bool> createTransaction(Map<String, dynamic> data) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(bendaharaDataSourceProvider);
      await datasource.createTransaction(data);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to create transaction',
          name: 'Bendahara',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return false;
    }
  }
}
