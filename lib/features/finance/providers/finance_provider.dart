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

// --- Transaction list (paginated) ---
class TransactionListState {
  const TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<FinanceTransaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  TransactionListState copyWith({
    List<FinanceTransaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class TransactionListNotifier extends Notifier<TransactionListState> {
  @override
  TransactionListState build() => const TransactionListState();

  Future<void> load({String? type, String? dateFrom, String? dateTo}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final (list, meta) = await ds.getTransactions(
        type: type,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: 1,
      );
      state = state.copyWith(
        transactions: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? type,
    String? dateFrom,
    String? dateTo,
  }) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getTransactions(
        type: type,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: nextPage,
      );
      state = state.copyWith(
        transactions: [...state.transactions, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final transactionListProvider =
    NotifierProvider<TransactionListNotifier, TransactionListState>(
      TransactionListNotifier.new,
    );

// --- Pending payments (paginated) ---
class PendingPaymentsState {
  const PendingPaymentsState({
    this.payments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<PaymentModel> payments;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  PendingPaymentsState copyWith({
    List<PaymentModel>? payments,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PendingPaymentsState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class PendingPaymentsNotifier extends Notifier<PendingPaymentsState> {
  @override
  PendingPaymentsState build() => const PendingPaymentsState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final (list, meta) = await ds.getPendingPayments(page: 1);
      state = state.copyWith(
        payments: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getPendingPayments(page: nextPage);
      state = state.copyWith(
        payments: [...state.payments, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void removePayment(int id) {
    state = state.copyWith(
      payments: state.payments.where((p) => p.id != id).toList(),
    );
  }
}

final pendingPaymentsProvider =
    NotifierProvider<PendingPaymentsNotifier, PendingPaymentsState>(
      PendingPaymentsNotifier.new,
    );

// --- Dues (paginated) ---
class DuesListState {
  const DuesListState({
    this.dues = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<DueModel> dues;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  DuesListState copyWith({
    List<DueModel>? dues,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return DuesListState(
      dues: dues ?? this.dues,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class DuesListNotifier extends Notifier<DuesListState> {
  @override
  DuesListState build() => const DuesListState();

  Future<void> load({bool includeInactive = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final (list, meta) = await ds.getDues(
        includeInactive: includeInactive,
        page: 1,
      );
      state = state.copyWith(
        dues: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({bool includeInactive = false}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getDues(
        includeInactive: includeInactive,
        page: nextPage,
      );
      state = state.copyWith(
        dues: [...state.dues, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final duesListProvider = NotifierProvider<DuesListNotifier, DuesListState>(
  DuesListNotifier.new,
);

// --- Warga: My Due Bills (paginated) ---
class MyDueBillsState {
  const MyDueBillsState({
    this.bills = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<DueBillModel> bills;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  MyDueBillsState copyWith({
    List<DueBillModel>? bills,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return MyDueBillsState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class MyDueBillsNotifier extends Notifier<MyDueBillsState> {
  @override
  MyDueBillsState build() => const MyDueBillsState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final (list, meta) = await ds.getMyDueBills(page: 1);
      state = state.copyWith(
        bills: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getMyDueBills(page: nextPage);
      state = state.copyWith(
        bills: [...state.bills, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void markAsPaid(int id) {
    state = state.copyWith(
      bills: state.bills.map((b) {
        if (b.id == id) {
          return DueBillModel(
            id: b.id,
            dueId: b.dueId,
            due: b.due,
            amount: b.amount,
            dueDate: b.dueDate,
            status: 'pending',
          );
        }
        return b;
      }).toList(),
    );
  }
}

final myDueBillsProvider =
    NotifierProvider<MyDueBillsNotifier, MyDueBillsState>(
      MyDueBillsNotifier.new,
    );

// --- Warga: My Payments (paginated) ---
class MyPaymentsState {
  const MyPaymentsState({
    this.payments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<PaymentModel> payments;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  MyPaymentsState copyWith({
    List<PaymentModel>? payments,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return MyPaymentsState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class MyPaymentsNotifier extends Notifier<MyPaymentsState> {
  @override
  MyPaymentsState build() => const MyPaymentsState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final (list, meta) = await ds.getMyPayments(page: 1);
      state = state.copyWith(
        payments: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getMyPayments(page: nextPage);
      state = state.copyWith(
        payments: [...state.payments, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addPayment(PaymentModel payment) {
    state = state.copyWith(payments: [payment, ...state.payments]);
  }
}

final myPaymentsProvider =
    NotifierProvider<MyPaymentsNotifier, MyPaymentsState>(
      MyPaymentsNotifier.new,
    );
