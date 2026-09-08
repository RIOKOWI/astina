class AssetModel {
  final int id;
  final String code;
  final String name;
  final String category;
  final String? description;
  final int quantity;
  final String unit;
  final String? condition;
  final String status;
  final double? purchasePrice;
  final String? purchaseDate;
  final String createdAt;
  final String updatedAt;
  final List<_RecentMovement>? recentMovements;

  const AssetModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.description,
    required this.quantity,
    required this.unit,
    this.condition,
    required this.status,
    this.purchasePrice,
    this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
    this.recentMovements,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      condition: json['condition'] as String?,
      status: json['status'] as String,
      purchasePrice: json['purchase_price'] != null
          ? double.tryParse(json['purchase_price'].toString())
          : null,
      purchaseDate: json['purchase_date'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      recentMovements: json['recent_movements'] != null
          ? (json['recent_movements'] as List)
                .map((e) => _RecentMovement.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
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
        return '-';
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
        return 'Dimusnahkan';
      default:
        return status;
    }
  }

  String get formattedPurchasePrice {
    if (purchasePrice == null) return '-';
    final str = purchasePrice!
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $str';
  }

  String get formattedPurchaseDate {
    if (purchaseDate == null) return '-';
    try {
      final parts = purchaseDate!.split('-');
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
      return purchaseDate!;
    }
  }

  bool get isRetired => status == 'retired';
  bool get isLowStock => quantity <= 5 && quantity > 0;
  bool get isOutOfStock => quantity == 0;
}

class _RecentMovement {
  final int id;
  final String type;
  final int quantity;
  final String? description;
  final String movementAt;
  final String createdAt;
  final _MovementCreator? createdBy;

  const _RecentMovement({
    required this.id,
    required this.type,
    required this.quantity,
    this.description,
    required this.movementAt,
    required this.createdAt,
    this.createdBy,
  });

  factory _RecentMovement.fromJson(Map<String, dynamic> json) {
    return _RecentMovement(
      id: json['id'] as int,
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

class AssetListResponse {
  final List<AssetModel> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const AssetListResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory AssetListResponse.fromJson(
    Map<String, dynamic> json,
    List<dynamic> dataList,
  ) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return AssetListResponse(
      data: dataList
          .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta?['current_page'] as int? ?? 1,
      perPage: meta?['per_page'] as int? ?? 15,
      total: meta?['total'] as int? ?? 0,
      lastPage: meta?['last_page'] as int? ?? 1,
    );
  }
}

class AssetFilter {
  final String? search;
  final String? category;
  final String? condition;
  final String? status;

  const AssetFilter({this.search, this.category, this.condition, this.status});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssetFilter &&
        other.search == search &&
        other.category == category &&
        other.condition == condition &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(search, category, condition, status);

  Map<String, dynamic> toQuery() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (category != null) 'category': category,
      if (condition != null) 'condition': condition,
      if (status != null) 'status': status,
    };
  }
}

class MovementFilter {
  final String? type;
  final String? from;
  final String? to;
  final String? search;
  final int? perPage;

  const MovementFilter({
    this.type,
    this.from,
    this.to,
    this.search,
    this.perPage,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovementFilter &&
        other.type == type &&
        other.from == from &&
        other.to == to &&
        other.search == search &&
        other.perPage == perPage;
  }

  @override
  int get hashCode => Object.hash(type, from, to, search, perPage);

  Map<String, dynamic> toQuery() {
    return {
      if (type != null) 'type': type,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (perPage != null) 'per_page': perPage,
    };
  }
}
