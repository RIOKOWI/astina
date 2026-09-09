class CashSummary {
  final int balance;
  final int totalIncome;
  final int totalExpense;

  const CashSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory CashSummary.fromJson(Map<String, dynamic> json) {
    return CashSummary(
      balance: json['balance'] as int,
      totalIncome: json['total_income'] as int,
      totalExpense: json['total_expense'] as int,
    );
  }
}
