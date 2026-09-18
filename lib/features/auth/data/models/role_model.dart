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
}
