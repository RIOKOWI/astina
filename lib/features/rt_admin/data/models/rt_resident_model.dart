class RtResidentModel {
  final int id;
  final String? nik;
  final String fullName;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? gender;
  final String? religion;
  final String? occupation;
  final String? lastEducation;
  final String? maritalStatus;
  final String? phone;
  final String? email;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final DateTime createdAt;
  final _RtHouseholdSummary? household;
  final _RtUserAccount? account;
  final _RtDocumentInfo? ktp;
  final _RtKKInfo? kk;

  RtResidentModel({
    required this.id,
    this.nik,
    required this.fullName,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.religion,
    this.occupation,
    this.lastEducation,
    this.maritalStatus,
    this.phone,
    this.email,
    required this.status,
    this.joinedAt,
    this.leftAt,
    required this.createdAt,
    this.household,
    this.account,
    this.ktp,
    this.kk,
  });

  factory RtResidentModel.fromJson(Map<String, dynamic> json) {
    return RtResidentModel(
      id: json['id'] as int,
      nik: json['nik'] as String?,
      fullName: json['full_name'] as String,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      religion: json['religion'] as String?,
      occupation: json['occupation'] as String?,
      lastEducation: json['last_education'] as String?,
      maritalStatus: json['marital_status'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      leftAt: json['left_at'] != null
          ? DateTime.parse(json['left_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      household: json['household'] != null
          ? _RtHouseholdSummary.fromJson(
              json['household'] as Map<String, dynamic>,
            )
          : null,
      account: json['account'] != null
          ? _RtUserAccount.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      ktp: json['ktp'] != null
          ? _RtDocumentInfo.fromJson(json['ktp'] as Map<String, dynamic>)
          : null,
      kk: json['kk'] != null
          ? _RtKKInfo.fromJson(json['kk'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Nonaktif';
      case 'moved':
        return 'Pindah';
      default:
        return status;
    }
  }

  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      default:
        return gender ?? '-';
    }
  }

  String get maritalLabel {
    switch (maritalStatus) {
      case 'single':
        return 'Belum Menikah';
      case 'married':
        return 'Menikah';
      case 'divorced':
        return 'Cerai';
      case 'widowed':
        return 'Duda/Janda';
      default:
        return maritalStatus ?? '-';
    }
  }

  String get formattedBirthDate {
    if (birthDate == null) return '-';
    final months = [
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
    return '${birthDate!.day} ${months[birthDate!.month - 1]} ${birthDate!.year}';
  }

  bool get hasAccount => account != null;
  bool get hasKtp => ktp?.exists ?? false;
}

class _RtHouseholdSummary {
  final int id;
  final String? noKk;
  final String? address;
  final String? rt;
  final String? rw;
  final String? postalCode;
  final String? status;

  _RtHouseholdSummary({
    required this.id,
    this.noKk,
    this.address,
    this.rt,
    this.rw,
    this.postalCode,
    this.status,
  });

  factory _RtHouseholdSummary.fromJson(Map<String, dynamic> json) {
    return _RtHouseholdSummary(
      id: json['id'] as int,
      noKk: json['no_kk'] as String?,
      address: json['address'] as String?,
      rt: json['rt'] as String?,
      rw: json['rw'] as String?,
      postalCode: json['postal_code'] as String?,
      status: json['status'] as String?,
    );
  }
}

class _RtUserAccount {
  final int id;
  final String phone;
  final String? email;
  final bool isActive;
  final List<_RtRole>? roles;

  _RtUserAccount({
    required this.id,
    required this.phone,
    this.email,
    required this.isActive,
    this.roles,
  });

  factory _RtUserAccount.fromJson(Map<String, dynamic> json) {
    return _RtUserAccount(
      id: json['id'] as int,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool,
      roles: json['roles'] != null
          ? (json['roles'] as List<dynamic>)
                .map((e) => _RtRole.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class _RtRole {
  final int id;
  final String name;
  final String code;

  _RtRole({required this.id, required this.name, required this.code});

  factory _RtRole.fromJson(Map<String, dynamic> json) {
    return _RtRole(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class _RtDocumentInfo {
  final bool exists;
  final String? mimeType;
  final int? fileSize;
  final String? fileName;
  final String? url;

  _RtDocumentInfo({
    required this.exists,
    this.mimeType,
    this.fileSize,
    this.fileName,
    this.url,
  });

  factory _RtDocumentInfo.fromJson(Map<String, dynamic> json) {
    return _RtDocumentInfo(
      exists: json['exists'] as bool? ?? false,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      fileName: json['file_name'] as String?,
      url: json['url'] as String?,
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '-';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _RtKKInfo {
  final bool exists;
  final String? noKk;
  final String? mimeType;
  final int? fileSize;
  final String? fileName;
  final String? url;

  _RtKKInfo({
    required this.exists,
    this.noKk,
    this.mimeType,
    this.fileSize,
    this.fileName,
    this.url,
  });

  factory _RtKKInfo.fromJson(Map<String, dynamic> json) {
    if (json is bool) {
      return _RtKKInfo(exists: false);
    }
    return _RtKKInfo(
      exists: json['exists'] as bool? ?? false,
      noKk: json['no_kk'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      fileName: json['file_name'] as String?,
      url: json['url'] as String?,
    );
  }
}
