import 'dart:convert';
import 'role_model.dart';
import 'resident_brief_model.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.isActive,
    required this.roles,
    this.resident,
  });

  final int id;
  final String phone;
  final String? email;
  final bool isActive;
  final List<RoleModel> roles;
  final ResidentBriefModel? resident;

  /// Returns the role with highest privilege:
  /// rt > bendahara > warga
  String? get primaryRoleCode {
    for (final code in ['rt', 'bendahara', 'warga']) {
      if (roles.any((r) => r.code == code)) return code;
    }
    return null;
  }

  bool get hasRoleRt => roles.any((r) => r.code == 'rt');
  bool get hasRoleBendahara => roles.any((r) => r.code == 'bendahara');
  bool get hasRoleWarga => roles.any((r) => r.code == 'warga');

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
      resident: json['resident'] != null
          ? ResidentBriefModel.fromJson(
              json['resident'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'roles': roles
          .map((r) => {'id': r.id, 'name': r.name, 'code': r.code})
          .toList(),
      'resident': resident != null
          ? {'id': resident!.id, 'full_name': resident!.fullName}
          : null,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
