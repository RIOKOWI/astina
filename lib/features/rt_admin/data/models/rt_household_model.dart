class RtHouseholdModel {
  final int id;
  final String? noKk;
  final String? address;
  final String? rt;
  final String? rw;
  final String? postalCode;
  final String status;
  final DateTime createdAt;
  final _RtHeadResident? headResident;
  final int? memberCount;
  final List<_RtHouseholdMember>? members;

  RtHouseholdModel({
    required this.id,
    this.noKk,
    this.address,
    this.rt,
    this.rw,
    this.postalCode,
    required this.status,
    required this.createdAt,
    this.headResident,
    this.memberCount,
    this.members,
  });

  factory RtHouseholdModel.fromJson(Map<String, dynamic> json) {
    return RtHouseholdModel(
      id: json['id'] as int,
      noKk: json['no_kk'] as String?,
      address: json['address'] as String?,
      rt: json['rt'] as String?,
      rw: json['rw'] as String?,
      postalCode: json['postal_code'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      headResident: json['head_resident'] != null
          ? _RtHeadResident.fromJson(
              json['head_resident'] as Map<String, dynamic>,
            )
          : null,
      memberCount: json['member_count'] as int?,
      members: json['members'] != null
          ? (json['members'] as List<dynamic>)
                .map(
                  (e) => _RtHouseholdMember.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Nonaktif';
      default:
        return status;
    }
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (rt != null && rt!.isNotEmpty) parts.add('RT $rt');
    if (rw != null && rw!.isNotEmpty) parts.add('RW $rw');
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }
}

class _RtHeadResident {
  final int id;
  final String fullName;
  final String? phone;

  _RtHeadResident({required this.id, required this.fullName, this.phone});

  factory _RtHeadResident.fromJson(Map<String, dynamic> json) {
    return _RtHeadResident(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class _RtHouseholdMember {
  final int id;
  final String fullName;
  final String? phone;
  final String? relationship;

  _RtHouseholdMember({
    required this.id,
    required this.fullName,
    this.phone,
    this.relationship,
  });

  factory _RtHouseholdMember.fromJson(Map<String, dynamic> json) {
    return _RtHouseholdMember(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  String get relationshipLabel {
    switch (relationship) {
      case 'head':
        return 'Kepala Rumah Tangga';
      case 'spouse':
        return 'Pasangan';
      case 'child':
        return 'Anak';
      case 'parent':
        return 'Orang Tua';
      case 'sibling':
        return 'Saudara';
      case 'other':
        return 'Lainnya';
      default:
        return relationship ?? '-';
    }
  }
}
