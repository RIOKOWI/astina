class AdminHousehold {
  final int id;
  final String noKk;
  final String address;
  final String rt;
  final String rw;
  final String? postalCode;
  final String status;
  final AdminHouseholdHead? headResident;
  final List<AdminHouseholdMember>? members;
  final int? memberCount;

  const AdminHousehold({
    required this.id,
    required this.noKk,
    required this.address,
    required this.rt,
    required this.rw,
    this.postalCode,
    required this.status,
    this.headResident,
    this.members,
    this.memberCount,
  });

  factory AdminHousehold.fromJson(Map<String, dynamic> json) {
    return AdminHousehold(
      id: json['id'] as int,
      noKk: json['no_kk'] as String,
      address: json['address'] as String,
      rt: json['rt'] as String,
      rw: json['rw'] as String,
      postalCode: json['postal_code'] as String?,
      status: json['status'] as String,
      headResident: json['head_resident'] != null
          ? AdminHouseholdHead.fromJson(
              json['head_resident'] as Map<String, dynamic>,
            )
          : null,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => AdminHouseholdMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      memberCount: json['member_count'] as int?,
    );
  }
}

class AdminHouseholdHead {
  final int id;
  final String fullName;
  final String? phone;

  const AdminHouseholdHead({
    required this.id,
    required this.fullName,
    this.phone,
  });

  factory AdminHouseholdHead.fromJson(Map<String, dynamic> json) {
    return AdminHouseholdHead(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class AdminHouseholdMember {
  final int id;
  final String fullName;
  final String? phone;
  final String relationship;

  const AdminHouseholdMember({
    required this.id,
    required this.fullName,
    this.phone,
    required this.relationship,
  });

  factory AdminHouseholdMember.fromJson(Map<String, dynamic> json) {
    return AdminHouseholdMember(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      relationship: json['relationship'] as String,
    );
  }

  String get relationshipLabel {
    switch (relationship) {
      case 'head':
        return 'Kepala Keluarga';
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
        return relationship;
    }
  }
}
