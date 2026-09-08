import 'dart:convert';

class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.roles,
    this.resident,
  });

  final int id;
  final String phone;
  final String? email;
  final bool isActive;
  final List<RoleModel> roles;
  final ResidentMiniModel? resident;

  bool hasRole(String code) => roles.any((r) => r.code == code);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resident: json['resident'] == null
          ? null
          : ResidentMiniModel.fromJson(
              json['resident'] as Map<String, dynamic>,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'is_active': isActive,
    'roles': roles.map((r) => r.toJson()).toList(),
    'resident': resident?.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());
}

class RoleModel {
  const RoleModel({required this.id, required this.name, required this.code});

  final int id;
  final String name;
  final String code;

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

class ResidentMiniModel {
  const ResidentMiniModel({required this.id, required this.fullName});

  final int id;
  final String fullName;

  factory ResidentMiniModel.fromJson(Map<String, dynamic> json) {
    return ResidentMiniModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'full_name': fullName};
}

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final UserModel user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
