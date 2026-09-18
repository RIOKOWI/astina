class AssetCreatedBy {
  const AssetCreatedBy({required this.id, required this.name});

  final int id;
  final String name;

  factory AssetCreatedBy.fromJson(Map<String, dynamic> json) {
    return AssetCreatedBy(id: json['id'] as int, name: json['name'] as String);
  }
}

class AssetMovement {
  const AssetMovement({
    required this.id,
    required this.assetId,
    required this.type,
    required this.quantity,
    this.description,
    required this.movementAt,
    required this.createdAt,
    this.createdBy,
  });

  final int id;
  final int assetId;
  final String type;
  final int quantity;
  final String? description;
  final DateTime movementAt;
  final DateTime createdAt;
  final AssetCreatedBy? createdBy;

  factory AssetMovement.fromJson(Map<String, dynamic> json) {
    return AssetMovement(
      id: json['id'] as int,
      assetId: json['asset_id'] as int,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      description: json['description'] as String?,
      movementAt: DateTime.parse(json['movement_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] != null
          ? AssetCreatedBy.fromJson(json['created_by'] as Map<String, dynamic>)
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
}

class Asset {
  const Asset({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.description,
    required this.quantity,
    required this.unit,
    this.purchasePrice,
    this.purchaseDate,
    this.condition,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.recentMovements,
  });

  final int id;
  final String code;
  final String name;
  final String category;
  final String? description;
  final int quantity;
  final String unit;
  final String? purchasePrice;
  final String? purchaseDate;
  final String? condition;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AssetMovement>? recentMovements;

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      purchasePrice: json['purchase_price']?.toString(),
      purchaseDate: json['purchase_date'] as String?,
      condition: json['condition'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      recentMovements: (json['recent_movements'] as List<dynamic>?)
          ?.map((e) => AssetMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Baru';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'poor':
        return 'Rusak';
      default:
        return condition ?? '-';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'available':
        return 'Tersedia';
      case 'in_use':
        return 'Dipakai';
      case 'maintenance':
        return 'Perbaikan';
      case 'retired':
        return 'Nonaktif';
      default:
        return status ?? '-';
    }
  }
}
