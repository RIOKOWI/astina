class DocumentModel {
  final int id;
  final String type;
  final String? fileName;
  final String? fileUrl;
  final String? status;
  final DateTime? uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.type,
    this.fileName,
    this.fileUrl,
    this.status,
    this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      type: json['type'] as String,
      fileName: json['file_name'] as String?,
      fileUrl: json['file_url'] as String?,
      status: json['status'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'file_name': fileName,
      'file_url': fileUrl,
      'status': status,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  String get displayType {
    switch (type.toLowerCase()) {
      case 'ktp':
        return 'KTP';
      case 'kk':
        return 'Kartu Keluarga';
      default:
        return type;
    }
  }
}
