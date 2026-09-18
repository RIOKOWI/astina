class LetterTypeRef {
  final int id;
  final String code;
  final String name;

  const LetterTypeRef({
    required this.id,
    required this.code,
    required this.name,
  });

  factory LetterTypeRef.fromJson(Map<String, dynamic> json) {
    return LetterTypeRef(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class ResidentRef {
  final int id;
  final String fullName;
  final String? nik;

  const ResidentRef({required this.id, required this.fullName, this.nik});

  factory ResidentRef.fromJson(Map<String, dynamic> json) {
    return ResidentRef(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      nik: json['nik'] as String?,
    );
  }
}

class Approver {
  final int id;
  final String name;

  const Approver({required this.id, required this.name});

  factory Approver.fromJson(Map<String, dynamic> json) {
    return Approver(id: json['id'] as int, name: json['name'] as String);
  }
}

class Approval {
  final String action;
  final String? notes;
  final String actedAt;
  final Approver approver;

  const Approval({
    required this.action,
    this.notes,
    required this.actedAt,
    required this.approver,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      action: json['action'] as String,
      notes: json['notes'] as String?,
      actedAt: json['acted_at'] as String,
      approver: Approver.fromJson(json['approver'] as Map<String, dynamic>),
    );
  }
}

class LetterDocument {
  final int id;
  final String documentType;
  final String fileName;
  final String? mimeType;
  final int? fileSize;

  const LetterDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    this.mimeType,
    this.fileSize,
  });

  factory LetterDocument.fromJson(Map<String, dynamic> json) {
    return LetterDocument(
      id: json['id'] as int,
      documentType: json['document_type'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
    );
  }
}

class FieldValue {
  final String fieldKey;
  final String label;
  final String? value;

  const FieldValue({required this.fieldKey, required this.label, this.value});

  factory FieldValue.fromJson(Map<String, dynamic> json) {
    return FieldValue(
      fieldKey: json['field_key'] as String,
      label: json['label'] as String,
      value: json['value'] as String?,
    );
  }
}

class Letter {
  final int id;
  final String referenceNo;
  final LetterTypeRef letterType;
  final ResidentRef resident;
  final String? purpose;
  final String status;
  final String? rejectionReason;
  final String? submittedAt;
  final String? approvedAt;
  final List<FieldValue> fieldValues;
  final List<Approval> approvals;
  final List<LetterDocument> documents;

  const Letter({
    required this.id,
    required this.referenceNo,
    required this.letterType,
    required this.resident,
    this.purpose,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.approvedAt,
    required this.fieldValues,
    required this.approvals,
    required this.documents,
  });

  factory Letter.fromJson(Map<String, dynamic> json) {
    return Letter(
      id: json['id'] as int,
      referenceNo: json['reference_no'] as String,
      letterType: LetterTypeRef.fromJson(
        json['letter_type'] as Map<String, dynamic>,
      ),
      resident: ResidentRef.fromJson(json['resident'] as Map<String, dynamic>),
      purpose: json['purpose'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] as String?,
      approvedAt: json['approved_at'] as String?,
      fieldValues:
          (json['field_values'] as List<dynamic>?)
              ?.map((e) => FieldValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      approvals:
          (json['approvals'] as List<dynamic>?)
              ?.map((e) => Approval.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map((e) => LetterDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LetterListItem {
  final int id;
  final String referenceNo;
  final LetterTypeRef letterType;
  final String status;
  final String? purpose;
  final String? submittedAt;
  final ResidentRef? resident;

  const LetterListItem({
    required this.id,
    required this.referenceNo,
    required this.letterType,
    required this.status,
    this.purpose,
    this.submittedAt,
    this.resident,
  });

  factory LetterListItem.fromJson(Map<String, dynamic> json) {
    return LetterListItem(
      id: json['id'] as int,
      referenceNo: json['reference_no'] as String,
      letterType: LetterTypeRef.fromJson(
        json['letter_type'] as Map<String, dynamic>,
      ),
      status: json['status'] as String,
      purpose: json['purpose'] as String?,
      submittedAt: json['submitted_at'] as String?,
      resident: json['resident'] != null
          ? ResidentRef.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
    );
  }
}
