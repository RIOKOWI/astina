class FinanceSummaryModel {
  final int balance;
  final int incomeThisMonth;
  final int expenseThisMonth;

  const FinanceSummaryModel({
    required this.balance,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
  });

  factory FinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinanceSummaryModel(
      balance: json['balance'] as int? ?? 0,
      incomeThisMonth: json['income_this_month'] as int? ?? 0,
      expenseThisMonth: json['expense_this_month'] as int? ?? 0,
    );
  }

  String get formattedBalance {
    final str = balance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String formatAmount(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }
}

class FinanceTransactionModel {
  final int id;
  final int? createdBy;
  final int? paymentId;
  final String type;
  final int amount;
  final String? category;
  final String? description;
  final DateTime? transactionAt;
  final _FinanceCreator? creator;
  final DateTime? createdAt;

  const FinanceTransactionModel({
    required this.id,
    this.createdBy,
    this.paymentId,
    required this.type,
    required this.amount,
    this.category,
    this.description,
    this.transactionAt,
    this.creator,
    this.createdAt,
  });

  factory FinanceTransactionModel.fromJson(Map<String, dynamic> json) {
    return FinanceTransactionModel(
      id: json['id'] as int,
      createdBy: json['created_by'] as int?,
      paymentId: json['payment_id'] as int?,
      type: json['type'] as String,
      amount: json['amount'] as int,
      category: json['category'] as String?,
      description: json['description'] as String?,
      transactionAt: json['transaction_at'] != null
          ? DateTime.parse(json['transaction_at'] as String)
          : null,
      creator: json['creator'] != null
          ? _FinanceCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  String get formattedAmount {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String get typeLabel => type == 'income' ? 'Pemasukan' : 'Pengeluaran';
  bool get isIncome => type == 'income';
}

class _FinanceCreator {
  final int id;
  final String name;

  const _FinanceCreator({required this.id, required this.name});

  factory _FinanceCreator.fromJson(Map<String, dynamic> json) {
    return _FinanceCreator(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'RT',
    );
  }
}
