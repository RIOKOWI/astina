class PaymentModel {
  final int id;
  final int dueBillId;
  final _PaymentDueBill? dueBill;
  final int residentId;
  final _PaymentResident? resident;
  final int amount;
  final String? method;
  final String status;
  final DateTime? paidAt;
  final DateTime? approvedAt;
  final int? approvedBy;
  final _PaymentApprover? approver;
  final String? rejectionReason;
  final List<PaymentProofModel> proofs;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.dueBillId,
    this.dueBill,
    required this.residentId,
    this.resident,
    required this.amount,
    this.method,
    required this.status,
    this.paidAt,
    this.approvedAt,
    this.approvedBy,
    this.approver,
    this.rejectionReason,
    this.proofs = const [],
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      dueBillId: json['due_bill_id'] as int,
      dueBill: json['due_bill'] != null
          ? _PaymentDueBill.fromJson(json['due_bill'] as Map<String, dynamic>)
          : null,
      residentId: json['resident_id'] as int,
      resident: json['resident'] != null
          ? _PaymentResident.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      amount: json['amount'] as int,
      method: json['method'] as String?,
      status: json['status'] as String,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as int?,
      approver: json['approver'] != null
          ? _PaymentApprover.fromJson(json['approver'] as Map<String, dynamic>)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      proofs:
          (json['proofs'] as List<dynamic>?)
              ?.map(
                (e) => PaymentProofModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  String get formattedAmount {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String get methodLabel {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'ewallet':
        return 'E-Wallet';
      case 'other':
        return 'Lainnya';
      default:
        return method ?? '-';
    }
  }
}

class _PaymentDueBill {
  final int id;
  final _InnerDue due;
  final int amount;
  final String dueDate;
  final String status;

  const _PaymentDueBill({
    required this.id,
    required this.due,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory _PaymentDueBill.fromJson(Map<String, dynamic> json) {
    return _PaymentDueBill(
      id: json['id'] as int,
      due: _InnerDue.fromJson(json['due'] as Map<String, dynamic>),
      amount: json['amount'] as int,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
    );
  }
}

class _InnerDue {
  final int id;
  final String name;
  final int amount;

  const _InnerDue({required this.id, required this.name, required this.amount});

  factory _InnerDue.fromJson(Map<String, dynamic> json) {
    return _InnerDue(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: json['amount'] as int,
    );
  }
}

class _PaymentResident {
  final int id;
  final String fullName;

  const _PaymentResident({required this.id, required this.fullName});

  factory _PaymentResident.fromJson(Map<String, dynamic> json) {
    return _PaymentResident(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? 'Warga',
    );
  }
}

class _PaymentApprover {
  final int id;
  final String name;

  const _PaymentApprover({required this.id, required this.name});

  factory _PaymentApprover.fromJson(Map<String, dynamic> json) {
    return _PaymentApprover(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Bendahara',
    );
  }
}

class PaymentProofModel {
  final int id;
  final int paymentId;
  final String? url;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final DateTime createdAt;

  const PaymentProofModel({
    required this.id,
    required this.paymentId,
    this.url,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });

  factory PaymentProofModel.fromJson(Map<String, dynamic> json) {
    return PaymentProofModel(
      id: json['id'] as int,
      paymentId: json['payment_id'] as int,
      url: json['url'] as String?,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
