class FinanceTransaction {
  final int id;
  final int createdBy;
  final int? paymentId;
  final String type;
  final int amount;
  final String category;
  final String? description;
  final DateTime transactionAt;
  final TransactionCreator? creator;
  final DateTime createdAt;

  const FinanceTransaction({
    required this.id,
    required this.createdBy,
    this.paymentId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.transactionAt,
    this.creator,
    required this.createdAt,
  });

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'] as int,
      createdBy: json['created_by'] as int,
      paymentId: json['payment_id'] as int?,
      type: json['type'] as String,
      amount: json['amount'] as int,
      category: json['category'] as String,
      description: json['description'] as String?,
      transactionAt: DateTime.parse(json['transaction_at'] as String),
      creator: json['creator'] != null
          ? TransactionCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}

class TransactionCreator {
  final int id;
  final String name;

  const TransactionCreator({required this.id, required this.name});

  factory TransactionCreator.fromJson(Map<String, dynamic> json) {
    return TransactionCreator(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
