class ResidentModel {
  final int id;
  final String? kkNumber;
  final String? nik;
  final String fullName;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? gender;
  final String? religion;
  final String? bloodType;
  final String? address;
  final String? occupation;
  final String? citizenship;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResidentModel({
    required this.id,
    this.kkNumber,
    this.nik,
    required this.fullName,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.religion,
    this.bloodType,
    this.address,
    this.occupation,
    this.citizenship,
    this.phone,
    this.email,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      id: json['id'] as int,
      kkNumber: json['kk_number'] as String?,
      nik: json['nik'] as String?,
      fullName: json['full_name'] as String,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      religion: json['religion'] as String?,
      bloodType: json['blood_type'] as String?,
      address: json['address'] as String?,
      occupation: json['occupation'] as String?,
      citizenship: json['citizenship'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kk_number': kkNumber,
      'nik': nik,
      'full_name': fullName,
      'birth_place': birthPlace,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'religion': religion,
      'blood_type': bloodType,
      'address': address,
      'occupation': occupation,
      'citizenship': citizenship,
      'phone': phone,
      'email': email,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ResidentModel copyWith({
    int? id,
    String? kkNumber,
    String? nik,
    String? fullName,
    String? birthPlace,
    DateTime? birthDate,
    String? gender,
    String? religion,
    String? bloodType,
    String? address,
    String? occupation,
    String? citizenship,
    String? phone,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResidentModel(
      id: id ?? this.id,
      kkNumber: kkNumber ?? this.kkNumber,
      nik: nik ?? this.nik,
      fullName: fullName ?? this.fullName,
      birthPlace: birthPlace ?? this.birthPlace,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      religion: religion ?? this.religion,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      citizenship: citizenship ?? this.citizenship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
