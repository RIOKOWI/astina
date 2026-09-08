class AssetMovementModel {
  final int id;
  final int assetId;
  final String type;
  final int quantity;
  final String? description;
  final String movementAt;
  final String createdAt;
  final _MovementCreator? createdBy;

  const AssetMovementModel({
    required this.id,
    required this.assetId,
    required this.type,
    required this.quantity,
    this.description,
    required this.movementAt,
    required this.createdAt,
    this.createdBy,
  });

  factory AssetMovementModel.fromJson(Map<String, dynamic> json) {
    return AssetMovementModel(
      id: json['id'] as int,
      assetId: json['asset_id'] as int,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      description: json['description'] as String?,
      movementAt: json['movement_at'] as String,
      createdAt: json['created_at'] as String,
      createdBy: json['created_by'] != null
          ? _MovementCreator.fromJson(
              json['created_by'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'in':
        return 'Masuk';
      case 'out':
        return 'Keluar';
      case 'adjustment':
        return 'Penyesuaian';
      default:
        return type;
    }
  }

  String get formattedDate {
    try {
      final dateStr = movementAt.split('T')[0];
      final parts = dateStr.split('-');
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${parts[2]} ${months[int.parse(parts[1])]} ${parts[0]}';
    } catch (_) {
      return movementAt;
    }
  }

  String get formattedTime {
    try {
      final timeStr = movementAt.split('T')[1].split('+')[0];
      return timeStr.substring(0, 5);
    } catch (_) {
      return '';
    }
  }
}

class _MovementCreator {
  final int id;
  final String name;

  const _MovementCreator({required this.id, required this.name});

  factory _MovementCreator.fromJson(Map<String, dynamic> json) {
    return _MovementCreator(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
