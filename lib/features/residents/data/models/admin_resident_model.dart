class AdminResident {
  final int id;
  final String nik;
  final String? noKk;
  final String fullName;
  final String? birthPlace;
  final String? birthDate;
  final String? gender;
  final String? religion;
  final String? occupation;
  final String? maritalStatus;
  final String? phone;
  final String? email;
  final String status;
  final String? lastEducation;
  final String? joinedAt;
  final String? leftAt;
  final bool hasAccount;
  final AdminResidentAccount? account;
  final AdminResidentHousehold? household;
  final AdminResidentDoc? ktp;
  final AdminResidentDoc? kk;

  const AdminResident({
    required this.id,
    required this.nik,
    this.noKk,
    required this.fullName,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.religion,
    this.occupation,
    this.maritalStatus,
    this.phone,
    this.email,
    required this.status,
    this.lastEducation,
    this.joinedAt,
    this.leftAt,
    required this.hasAccount,
    this.account,
    this.household,
    this.ktp,
    this.kk,
  });

  factory AdminResident.fromJson(Map<String, dynamic> json) {
    return AdminResident(
      id: json['id'] as int,
      nik: json['nik'] as String,
      noKk: json['no_kk'] as String?,
      fullName: json['full_name'] as String,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      religion: json['religion'] as String?,
      occupation: json['occupation'] as String?,
      maritalStatus: json['marital_status'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String,
      lastEducation: json['last_education'] as String?,
      joinedAt: json['joined_at'] as String?,
      leftAt: json['left_at'] as String?,
      hasAccount: json['has_account'] as bool? ?? false,
      account: json['account'] != null
          ? AdminResidentAccount.fromJson(
              json['account'] as Map<String, dynamic>,
            )
          : null,
      household: json['household'] != null
          ? AdminResidentHousehold.fromJson(
              json['household'] as Map<String, dynamic>,
            )
          : null,
      ktp: json['ktp'] != null
          ? AdminResidentDoc.fromJson(json['ktp'] as Map<String, dynamic>)
          : null,
      kk: json['kk'] != null
          ? AdminResidentDoc.fromJson(json['kk'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AdminResidentAccount {
  final int? id;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? lastLoginAt;
  final List<AdminRole>? roles;

  const AdminResidentAccount({
    this.id,
    this.phone,
    this.email,
    required this.isActive,
    this.lastLoginAt,
    this.roles,
  });

  factory AdminResidentAccount.fromJson(Map<String, dynamic> json) {
    return AdminResidentAccount(
      id: json['id'] as int?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool,
      lastLoginAt: json['last_login_at'] as String?,
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => AdminRole.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminRole {
  final int? id;
  final String code;
  final String name;

  const AdminRole({this.id, required this.code, required this.name});

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: json['id'] as int?,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class AdminResidentHousehold {
  final int id;
  final String noKk;
  final String address;
  final String rt;
  final String rw;
  final String? postalCode;
  final String status;

  const AdminResidentHousehold({
    required this.id,
    required this.noKk,
    required this.address,
    required this.rt,
    required this.rw,
    this.postalCode,
    required this.status,
  });

  factory AdminResidentHousehold.fromJson(Map<String, dynamic> json) {
    return AdminResidentHousehold(
      id: json['id'] as int,
      noKk: json['no_kk'] as String,
      address: json['address'] as String,
      rt: json['rt'] as String,
      rw: json['rw'] as String,
      postalCode: json['postal_code'] as String?,
      status: json['status'] as String,
    );
  }
}

class AdminResidentDoc {
  final bool exists;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final String? url;

  const AdminResidentDoc({
    required this.exists,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.url,
  });

  factory AdminResidentDoc.fromJson(Map<String, dynamic> json) {
    return AdminResidentDoc(
      exists: json['exists'] as bool,
      fileName: json['file_name'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      url: json['url'] as String?,
    );
  }
}

// Admin resident list item (summary)
class AdminResidentListItem {
  final int id;
  final String fullName;
  final String nik;
  final String? phone;
  final String status;
  final bool hasAccount;

  const AdminResidentListItem({
    required this.id,
    required this.fullName,
    required this.nik,
    this.phone,
    required this.status,
    required this.hasAccount,
  });

  factory AdminResidentListItem.fromJson(Map<String, dynamic> json) {
    return AdminResidentListItem(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      nik: json['nik'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      hasAccount: json['has_account'] as bool,
    );
  }
}
