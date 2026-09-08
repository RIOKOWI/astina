class RtUserModel {
  final int id;
  final String phone;
  final String? email;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final List<_RtUserRole>? roles;
  final _RtUserResident? resident;

  RtUserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.isActive,
    this.lastLoginAt,
    required this.createdAt,
    this.roles,
    this.resident,
  });

  factory RtUserModel.fromJson(Map<String, dynamic> json) {
    return RtUserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      roles: json['roles'] != null
          ? (json['roles'] as List<dynamic>)
                .map((e) => _RtUserRole.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      resident: json['resident'] != null
          ? _RtUserResident.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
    );
  }

  String get rolesLabel {
    if (roles == null || roles!.isEmpty) return '-';
    return roles!.map((r) => r.name).join(', ');
  }
}

class _RtUserRole {
  final int id;
  final String name;
  final String code;

  _RtUserRole({required this.id, required this.name, required this.code});

  factory _RtUserRole.fromJson(Map<String, dynamic> json) {
    return _RtUserRole(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class _RtUserResident {
  final int id;
  final String? nik;
  final String fullName;

  _RtUserResident({required this.id, this.nik, required this.fullName});

  factory _RtUserResident.fromJson(Map<String, dynamic> json) {
    return _RtUserResident(
      id: json['id'] as int,
      nik: json['nik'] as String?,
      fullName: json['full_name'] as String,
    );
  }
}
