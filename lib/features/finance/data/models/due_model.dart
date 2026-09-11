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
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'monthly':
        return 'Bulanan';
      case 'quarterly':
        return 'Triwulanan';
      case 'yearly':
        return 'Tahunan';
      case 'one-time':
      case 'one_time':
        return 'Sekali';
      default:
        return frequency ?? '-';
    }
  }
}
