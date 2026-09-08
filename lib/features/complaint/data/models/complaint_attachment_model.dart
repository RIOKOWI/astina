class ComplaintAttachmentModel {
  final int id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String url;
  final DateTime createdAt;

  const ComplaintAttachmentModel({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.url,
    required this.createdAt,
  });

  factory ComplaintAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ComplaintAttachmentModel(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      mimeType.startsWith('image/') ||
      [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
      ].any((ext) => fileName.toLowerCase().endsWith('.$ext'));
  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');
}
