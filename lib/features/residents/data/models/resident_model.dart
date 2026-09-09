class MeResident {
  final int id;
  final String nik;
  final String fullName;
  final String? birthPlace;
  final String? birthDate;
  final String gender;
  final String? religion;
  final String? occupation;
  final String? maritalStatus;
  final String? phone;
  final String? email;
  final String? lastEducation;
  final String status;

  const MeResident({
    required this.id,
    required this.nik,
    required this.fullName,
    this.birthPlace,
    this.birthDate,
    required this.gender,
    this.religion,
    this.occupation,
    this.maritalStatus,
    this.phone,
    this.email,
    this.lastEducation,
    required this.status,
  });

  factory MeResident.fromJson(Map<String, dynamic> json) {
    return MeResident(
      id: json['id'] as int,
      nik: json['nik'] as String,
      fullName: json['full_name'] as String,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String,
      religion: json['religion'] as String?,
      occupation: json['occupation'] as String?,
      maritalStatus: json['marital_status'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      lastEducation: json['last_education'] as String?,
      status: json['status'] as String,
    );
  }

  String get genderLabel => gender == 'male' ? 'Laki-laki' : 'Perempuan';

  String get maritalStatusLabel {
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

  String get religionLabel {
    switch (religion) {
      case 'islam':
        return 'Islam';
      case 'kristen':
        return 'Kristen';
      case 'katolik':
        return 'Katolik';
      case 'hindu':
        return 'Hindu';
      case 'buddha':
        return 'Buddha';
      case 'konghucu':
        return 'Konghucu';
      default:
        return religion ?? '-';
    }
  }
}
