class HouseholdModel {
  final int id;
  final String? kkNumber;
  final String headName;
  final String? address;
  final String? rt;
  final String? rw;
  final String? village;
  final String? district;
  final String? city;
  final String? postalCode;
  final String? province;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseholdModel({
    required this.id,
    this.kkNumber,
    required this.headName,
    this.address,
    this.rt,
    this.rw,
    this.village,
    this.district,
    this.city,
    this.postalCode,
    this.province,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as int,
      kkNumber: json['kk_number'] as String?,
      headName: json['head_name'] as String,
      address: json['address'] as String?,
      rt: json['rt'] as String?,
      rw: json['rw'] as String?,
      village: json['village'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      province: json['province'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kk_number': kkNumber,
      'head_name': headName,
      'address': address,
      'rt': rt,
      'rw': rw,
      'village': village,
      'district': district,
      'city': city,
      'postal_code': postalCode,
      'province': province,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress {
    final parts = [
      address,
      if (rt != null) 'RT $rt',
      if (rw != null) 'RW $rw',
      village,
      district,
      city,
      postalCode,
    ].where((p) => p != null && p.isNotEmpty).cast<String>().toList();
    return parts.join(', ');
  }
}
