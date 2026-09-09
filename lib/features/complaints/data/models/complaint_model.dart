class ComplaintAttachment {
  const ComplaintAttachment({
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

  factory ComplaintAttachment.fromJson(Map<String, dynamic> json) {
    return ComplaintAttachment(
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

class ComplaintComment {
  const ComplaintComment({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  final int id;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommentUser user;

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    return ComplaintComment(
      id: json['id'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class CommentUser {
  const CommentUser({
    required this.id,
    required this.name,
    required this.role,
  });

  final int id;
  final String name;
  final String role;

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  bool get isRT => role == 'rt';
}

class ResidentBrief {
  const ResidentBrief({required this.id, required this.fullName});

  final int id;
  final String fullName;

  factory ResidentBrief.fromJson(Map<String, dynamic> json) {
    return ResidentBrief(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
    );
  }
}

class AssignedTo {
  const AssignedTo({required this.id, required this.name});

  final int id;
  final String name;

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
    return AssignedTo(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Complaint {
  const Complaint({
    required this.id,
    required this.referenceNo,
    required this.title,
    this.description,
    required this.category,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    this.updatedAt,
    this.resident,
    this.assignedTo,
    this.attachments,
    this.comments,
    this.attachmentCount,
  });

  final int id;
  final String referenceNo;
  final String title;
  final String? description;
  final String category;
  final String status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ResidentBrief? resident;
  final AssignedTo? assignedTo;
  final List<ComplaintAttachment>? attachments;
  final List<ComplaintComment>? comments;
  final int? attachmentCount;

  int? get residentId => resident?.id;

  static int? _castInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is Map) return null;
    return int.tryParse(v.toString());
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      referenceNo: json['reference_no'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resident: json['resident'] != null
          ? ResidentBrief.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      assignedTo: json['assigned_to'] != null
          ? AssignedTo.fromJson(json['assigned_to'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => ComplaintAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => ComplaintComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachmentCount: _castInt(json['attachment_count']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Baru';
      case 'reviewed':
        return 'Ditinjau';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      case 'closed':
        return 'Ditutup';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'facility':
        return 'Fasilitas';
      case 'security':
        return 'Keamanan';
      case 'cleanliness':
        return 'Kebersihan';
      case 'noise':
        return 'Kebisingan';
      case 'dispute':
        return 'Perselisihan';
      case 'other':
        return 'Lainnya';
      default:
        return category;
    }
  }
}
