class ActivityModel {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime? startAt;
  final DateTime? endAt;
  final String status;
  final int attachmentCount;
  final bool isRead;
  final DateTime createdAt;
  final List<ActivityAttachment>? attachments;
  final ActivityCreator? creator;

  ActivityModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.startAt,
    this.endAt,
    required this.status,
    this.attachmentCount = 0,
    this.isRead = false,
    required this.createdAt,
    this.attachments,
    this.creator,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : null,
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : null,
      status: json['status'] as String,
      attachmentCount: json['attachment_count'] as int? ?? 0,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>)
                .map(
                  (e) => ActivityAttachment.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      creator: json['creator'] != null
          ? ActivityCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'published':
        return 'Dipublikasikan';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  bool get isUpcoming => startAt != null && startAt!.isAfter(DateTime.now());
  bool get isOngoing => startAt != null && endAt != null
      ? DateTime.now().isAfter(startAt!) && DateTime.now().isBefore(endAt!)
      : false;
}

class ActivityAttachment {
  final int id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? url;
  final DateTime createdAt;

  ActivityAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.url,
    required this.createdAt,
  });

  factory ActivityAttachment.fromJson(Map<String, dynamic> json) {
    return ActivityAttachment(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      url: json['url'] as String?,
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
      mimeType == 'image/jpeg' ||
      mimeType == 'image/png' ||
      mimeType == 'image/jpg';
  bool get isPdf => mimeType == 'application/pdf';
}

class ActivityCreator {
  final int id;
  final String name;

  ActivityCreator({required this.id, required this.name});

  factory ActivityCreator.fromJson(Map<String, dynamic> json) {
    return ActivityCreator(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
    );
  }
}
