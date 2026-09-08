class DueModel {
  final int id;
  final String name;
  final String? description;
  final int amount;
  final String? frequency;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final DateTime? createdAt;

  const DueModel({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    this.frequency,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.createdAt,
  });

  factory DueModel.fromJson(Map<String, dynamic> json) {
    return DueModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      amount: json['amount'] as int,
      frequency: json['frequency'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'amount': amount,
      'frequency': frequency,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
    };
  }

  String get formattedAmount {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'monthly':
        return 'Bulanan';
      case 'quarterly':
        return 'Per 3 Bulan';
      case 'yearly':
        return 'Tahunan';
      case 'one_time':
        return 'Sekali';
      default:
        return frequency ?? '-';
    }
  }
}
