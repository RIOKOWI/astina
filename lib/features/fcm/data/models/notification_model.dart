class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  int? get activityId {
    final v = data?['activity_id'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  int? get letterId {
    final v = data?['letter_id'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  int? get paymentId {
    final v = data?['payment_id'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  int? get complaintId {
    final v = data?['complaint_id'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  int? get sosId {
    final v = data?['sos_id'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get routePath {
    switch (type) {
      case 'activity_created':
        final id = activityId;
        return id != null ? '/activities/$id' : '/activities';
      case 'letter_submitted':
      case 'letter_approved':
      case 'letter_rejected':
      case 'letter_completed':
        final id = letterId;
        return id != null ? '/letters/$id' : '/letters/my';
      case 'payment_submitted':
      case 'payment_approved':
      case 'payment_rejected':
        return '/finance/payments';
      case 'complaint_created':
      case 'complaint_updated':
        final id = complaintId;
        return id != null ? '/complaints/$id' : '/complaints';
      case 'sos_alert':
        final id = sosId;
        return id != null ? '/sos/$id' : '/sos';
      default:
        return '/notifications';
    }
  }
}
