class ActivityAttachment {
  const ActivityAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.url,
    required this.createdAt,
  });

  final int id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String url;
  final DateTime createdAt;

  factory ActivityAttachment.fromJson(Map<String, dynamic> json) {
    return ActivityAttachment(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get fileSizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class ActivityCreator {
  const ActivityCreator({required this.id, required this.name});

  final int id;
  final String name;

  factory ActivityCreator.fromJson(Map<String, dynamic> json) {
    return ActivityCreator(id: json['id'] as int, name: json['name'] as String);
  }
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.startAt,
    this.endAt,
    required this.status,
    this.attachmentCount,
    this.isRead,
    required this.createdAt,
    this.attachments,
    this.createdBy,
    this.creator,
  });

  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime? startAt;
  final DateTime? endAt;
  final String status;
  final int? attachmentCount;
  final bool? isRead;
  final DateTime createdAt;
  final List<ActivityAttachment>? attachments;
  final int? createdBy;
  final ActivityCreator? creator;

  // ponytail: backend may return Map instead of int for created_by
  static int? _castInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is Map) return null;
    return int.tryParse(v.toString());
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
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
      attachmentCount: _castInt(json['attachment_count']),
      isRead: json['is_read'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => ActivityAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdBy: _castInt(json['created_by']),
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
        return 'Dipublikasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }
}
