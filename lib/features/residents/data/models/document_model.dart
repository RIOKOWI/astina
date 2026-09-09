class MeDocument {
  final MeDocumentResident resident;
  final MeDocumentFile? ktp;
  final MeDocumentHousehold? household;
  final MeDocumentFile? kk;

  const MeDocument({required this.resident, this.ktp, this.household, this.kk});

  factory MeDocument.fromJson(Map<String, dynamic> json) {
    return MeDocument(
      resident: MeDocumentResident.fromJson(
        json['resident'] as Map<String, dynamic>,
      ),
      ktp: json['ktp'] != null
          ? MeDocumentFile.fromJson(json['ktp'] as Map<String, dynamic>)
          : null,
      household: json['household'] != null
          ? MeDocumentHousehold.fromJson(
              json['household'] as Map<String, dynamic>,
            )
          : null,
      kk: json['kk'] != null
          ? MeDocumentFile.fromJson(json['kk'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MeDocumentResident {
  final int id;
  final String nik;
  final String fullName;

  const MeDocumentResident({
    required this.id,
    required this.nik,
    required this.fullName,
  });

  factory MeDocumentResident.fromJson(Map<String, dynamic> json) {
    return MeDocumentResident(
      id: json['id'] as int,
      nik: json['nik'] as String,
      fullName: json['full_name'] as String,
    );
  }
}

class MeDocumentHousehold {
  final int id;
  final String noKk;

  const MeDocumentHousehold({required this.id, required this.noKk});

  factory MeDocumentHousehold.fromJson(Map<String, dynamic> json) {
    return MeDocumentHousehold(
      id: json['id'] as int,
      noKk: json['no_kk'] as String,
    );
  }
}

class MeDocumentFile {
  final int id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? url;

  const MeDocumentFile({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.url,
  });

  factory MeDocumentFile.fromJson(Map<String, dynamic> json) {
    return MeDocumentFile(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      url: json['url'] as String?,
    );
  }

  String get fileSizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
