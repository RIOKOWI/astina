class DueBillModel {
  final int id;
  final int dueId;
  final _Due? due;
  final int residentId;
  final int amount;
  final String dueDate;
  final String status;
  final DateTime createdAt;

  const DueBillModel({
    required this.id,
    required this.dueId,
    this.due,
    required this.residentId,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory DueBillModel.fromJson(Map<String, dynamic> json) {
    return DueBillModel(
      id: json['id'] as int,
      dueId: json['due_id'] as int,
      due: json['due'] != null
          ? _Due.fromJson(json['due'] as Map<String, dynamic>)
          : null,
      residentId: json['resident_id'] as int,
      amount: json['amount'] as int,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedAmount {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
}

class _Due {
  final int id;
  final String name;
  final String? description;
  final int amount;
  final String? frequency;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  const _Due({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    this.frequency,
    this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory _Due.fromJson(Map<String, dynamic> json) {
    return _Due(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      amount: json['amount'] as int,
      frequency: json['frequency'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
