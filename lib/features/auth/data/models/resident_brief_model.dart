class ResidentBriefModel {
  const ResidentBriefModel({required this.id, required this.fullName});

  final int id;
  final String fullName;

  factory ResidentBriefModel.fromJson(Map<String, dynamic> json) {
    return ResidentBriefModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
    );
  }
}
