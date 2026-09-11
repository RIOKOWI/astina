class HouseholdModel {
  final int id;
  final String noKk;
  final String address;
  final String rt;
  final String rw;
  final String? postalCode;
  final String status;
  final HouseholdMember headResident;
  final List<HouseholdMember> members;

  const HouseholdModel({
    required this.id,
    required this.noKk,
    required this.address,
    required this.rt,
    required this.rw,
    this.postalCode,
    required this.status,
    required this.headResident,
    required this.members,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as int,
      noKk: json['no_kk'] as String,
      address: json['address'] as String,
      rt: json['rt'] as String,
      rw: json['rw'] as String,
      postalCode: json['postal_code'] as String?,
      status: json['status'] as String,
      headResident: HouseholdMember.fromJson(
        json['head_resident'] as Map<String, dynamic>,
      ),
      members: (json['members'] as List<dynamic>)
          .map((e) => HouseholdMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HouseholdMember {
  final int id;
  final String fullName;
  final String? phone;
  final String relationship;

  const HouseholdMember({
    required this.id,
    required this.fullName,
    this.phone,
    required this.relationship,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
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
