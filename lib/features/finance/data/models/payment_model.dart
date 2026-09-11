class PaymentModel {
  final int id;
  final int dueBillId;
  final DueBill? dueBill;
  final int residentId;
  final Resident? resident;
  final int amount;
  final String method;
  final String status;
  final DateTime? paidAt;
  final DateTime? approvedAt;
  final int? approvedBy;
  final Approver? approver;
  final String? rejectionReason;
  final List<PaymentProof> proofs;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.dueBillId,
    this.dueBill,
    required this.residentId,
    this.resident,
    required this.amount,
    required this.method,
    required this.status,
    this.paidAt,
    this.approvedAt,
    this.approvedBy,
    this.approver,
    this.rejectionReason,
    required this.proofs,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final residentJson = json['resident'];
    final resident = residentJson is Map
        ? Resident.fromJson(Map<String, dynamic>.from(residentJson))
        : null;

    return PaymentModel(
      id: json['id'] as int,
      dueBillId: json['due_bill_id'] as int,
      dueBill: json['due_bill'] != null
          ? DueBill.fromJson(json['due_bill'] as Map<String, dynamic>)
          : null,
      residentId: json['resident_id'] as int? ?? resident?.id ?? 0,
      resident: resident,
      amount: json['amount'] as int,
      method: json['method'] as String? ?? '-',
      status: json['status'] as String,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as int?,
      approver: json['approver'] != null
          ? Approver.fromJson(json['approver'] as Map<String, dynamic>)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      proofs:
          (json['proofs'] as List<dynamic>?)
              ?.map((e) => PaymentProof.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class DueBill {
  final int id;
  final int? dueId;
  final DueInfo? due;
  final int amount;
  final String dueDate;
  final String status;

  const DueBill({
    required this.id,
    this.dueId,
    this.due,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory DueBill.fromJson(Map<String, dynamic> json) {
    final dueJson = json['due'];
    final due = dueJson is Map
        ? DueInfo.fromJson(Map<String, dynamic>.from(dueJson))
        : null;

    return DueBill(
      id: json['id'] as int,
      dueId: json['due_id'] as int? ?? due?.id,
      due: due,
      amount: json['amount'] as int,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
    );
  }
}

class DueInfo {
  final int id;
  final String name;
  final int amount;
  final String? frequency;
  final bool? isActive;

  const DueInfo({
    required this.id,
    required this.name,
    required this.amount,
    this.frequency,
    this.isActive,
  });

  factory DueInfo.fromJson(Map<String, dynamic> json) {
    return DueInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: json['amount'] as int,
      frequency: json['frequency'] as String?,
      isActive: json['is_active'] as bool?,
    );
  }
}

class Resident {
  final int id;
  final String? fullName;

  const Resident({required this.id, this.fullName});

  factory Resident.fromJson(Map<String, dynamic> json) {
    return Resident(
      id: json['id'] as int,
      fullName: json['full_name'] as String?,
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

class PaymentProof {
  final int id;
  final int paymentId;
  final String url;
  final String fileName;
  final String mimeType;
  final int? fileSize;
  final DateTime createdAt;

  const PaymentProof({
    required this.id,
    required this.paymentId,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    return PaymentProof(
      id: json['id'] as int,
      paymentId: json['payment_id'] as int,
      url: json['url'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
