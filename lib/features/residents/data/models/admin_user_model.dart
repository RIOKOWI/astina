import '../../../auth/data/models/role_model.dart';
import '../../../auth/data/models/resident_brief_model.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.phone,
    this.email,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    required this.roles,
    this.resident,
  });

  final int id;
  final String phone;
  final String? email;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final List<RoleModel> roles;
  final ResidentBriefModel? resident;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
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
}
