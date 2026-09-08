class ExpenseModel {
  final int id;
  final String description;
  final int amount;
  final String category;
  final String? notes;
  final int recordedBy;
  final _ExpenseRecorder? recorder;
  final DateTime expenseDate;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    this.notes,
    required this.recordedBy,
    this.recorder,
    required this.expenseDate,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as int,
      description: json['description'] as String,
      amount: json['amount'] as int,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as int,
      recorder: json['recorder'] != null
          ? _ExpenseRecorder.fromJson(json['recorder'] as Map<String, dynamic>)
          : null,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category': category,
      'notes': notes,
      'expense_date': expenseDate.toIso8601String().split('T').first,
    };
  }

  String get formattedAmount {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String get categoryLabel {
    switch (category) {
      case 'maintenance':
        return 'Perawatan';
      case 'supplies':
        return 'Perlengkapan';
      case 'event':
        return 'Kegiatan';
      case 'utility':
        return 'Utilitas';
      case 'honor':
        return 'Honor';
      case 'other':
        return 'Lainnya';
      default:
        return category;
    }
  }
}

class _ExpenseRecorder {
  final int id;
  final String name;

  const _ExpenseRecorder({required this.id, required this.name});

  factory _ExpenseRecorder.fromJson(Map<String, dynamic> json) {
    return _ExpenseRecorder(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Bendahara',
    );
  }
}
