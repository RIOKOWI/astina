class LetterModel {
  final int id;
  final String referenceNo;
  final int letterTypeId;
  final int? residentId;
  final int? submittedBy;
  final String? purpose;
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime createdAt;
  final LetterTypeSummary? letterType;
  final _LetterSender? resident;
  final List<_FieldValue>? fieldValues;
  final List<_LetterApproval>? approvals;
  final List<_LetterDocument>? documents;

  LetterModel({
    required this.id,
    required this.referenceNo,
    required this.letterTypeId,
    this.residentId,
    this.submittedBy,
    this.purpose,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    required this.createdAt,
    this.letterType,
    this.resident,
    this.fieldValues,
    this.approvals,
    this.documents,
  });

  factory LetterModel.fromJson(Map<String, dynamic> json) {
    return LetterModel(
      id: json['id'] as int,
      referenceNo: json['reference_no'] as String,
      letterTypeId: json['letter_type_id'] as int,
      residentId: json['resident_id'] as int?,
      submittedBy: json['submitted_by'] as int?,
      purpose: json['purpose'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      letterType: json['letter_type'] != null
          ? LetterTypeSummary.fromJson(
              json['letter_type'] as Map<String, dynamic>,
            )
          : null,
      resident: json['resident'] != null
          ? _LetterSender.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      fieldValues: json['field_values'] != null
          ? (json['field_values'] as List<dynamic>)
                .map((e) => _FieldValue.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      approvals: json['approvals'] != null
          ? (json['approvals'] as List<dynamic>)
                .map((e) => _LetterApproval.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      documents: json['documents'] != null
          ? (json['documents'] as List<dynamic>)
                .map((e) => _LetterDocument.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  bool get isPending => status == 'submitted';
  bool get isApproved => status == 'approved' || status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  String get formattedDate {
    final d = submittedAt ?? createdAt;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get formattedTime {
    final d = submittedAt ?? createdAt;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class LetterTypeSummary {
  final int id;
  final String name;

  LetterTypeSummary({required this.id, required this.name});

  factory LetterTypeSummary.fromJson(Map<String, dynamic> json) {
    return LetterTypeSummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class _LetterSender {
  final int id;
  final String name;
  final String? address;
  final String? phone;

  _LetterSender({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory _LetterSender.fromJson(Map<String, dynamic> json) {
    return _LetterSender(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class _FieldValue {
  final String fieldKey;
  final String label;
  final String value;

  _FieldValue({
    required this.fieldKey,
    required this.label,
    required this.value,
  });

  factory _FieldValue.fromJson(Map<String, dynamic> json) {
    return _FieldValue(
      fieldKey: json['field_key'] as String,
      label: json['label'] as String? ?? json['field_key'] as String,
      value: json['value']?.toString() ?? '',
    );
  }
}

class _LetterApproval {
  final int id;
  final String action;
  final String? notes;
  final DateTime actedAt;
  final _Approver? approver;

  _LetterApproval({
    required this.id,
    required this.action,
    this.notes,
    required this.actedAt,
    this.approver,
  });

  factory _LetterApproval.fromJson(Map<String, dynamic> json) {
    return _LetterApproval(
      id: json['id'] as int,
      action: json['action'] as String,
      notes: json['notes'] as String?,
      actedAt: DateTime.parse(json['acted_at'] as String),
      approver: json['approver'] != null
          ? _Approver.fromJson(json['approver'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isApproved => action == 'approved';
  bool get isRejected => action == 'rejected';
}

class _Approver {
  final int id;
  final String name;

  _Approver({required this.id, required this.name});

  factory _Approver.fromJson(Map<String, dynamic> json) {
    return _Approver(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class _LetterDocument {
  final int id;
  final String documentType;
  final String fileName;
  final String mimeType;
  final int fileSize;

  _LetterDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  factory _LetterDocument.fromJson(Map<String, dynamic> json) {
    return _LetterDocument(
      id: json['id'] as int,
      documentType: json['document_type'] as String? ?? 'generated',
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
