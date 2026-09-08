import 'complaint_attachment_model.dart';
import 'complaint_comment_model.dart';

class ComplaintModel {
  final int id;
  final String referenceNo;
  final String title;
  final String? description;
  final String category;
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final _ComplaintResident? resident;
  final _ComplaintAssignee? assignedTo;
  final List<ComplaintAttachmentModel> attachments;
  final List<ComplaintCommentModel> comments;
  final int attachmentCount;

  const ComplaintModel({
    required this.id,
    required this.referenceNo,
    required this.title,
    this.description,
    required this.category,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.resident,
    this.assignedTo,
    this.attachments = const [],
    this.comments = const [],
    required this.attachmentCount,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as int,
      referenceNo: json['reference_no'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
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
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resident: json['resident'] != null
          ? _ComplaintResident.fromJson(
              json['resident'] as Map<String, dynamic>,
            )
          : null,
      assignedTo: json['assigned_to'] != null
          ? _ComplaintAssignee.fromJson(
              json['assigned_to'] as Map<String, dynamic>,
            )
          : null,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => ComplaintAttachmentModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ComplaintCommentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      attachmentCount: json['attachment_count'] as int? ?? 0,
    );
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

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Terkirim';
      case 'reviewed':
        return 'Ditinjau';
      case 'in_progress':
        return 'Dikerjakan';
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

  bool get canComment => !['closed', 'rejected'].contains(status);
  bool get isOwner => true; // Determined by API authorization
}

class _ComplaintResident {
  final int id;
  final String fullName;

  const _ComplaintResident({required this.id, required this.fullName});

  factory _ComplaintResident.fromJson(Map<String, dynamic> json) {
    return _ComplaintResident(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? 'Warga',
    );
  }
}

class _ComplaintAssignee {
  final int id;
  final String name;

  const _ComplaintAssignee({required this.id, required this.name});

  factory _ComplaintAssignee.fromJson(Map<String, dynamic> json) {
    return _ComplaintAssignee(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'RT',
    );
  }
}
