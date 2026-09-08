class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isRead => readAt != null;

  String? get resourceId =>
      data?['activity_id']?.toString() ??
      data?['letter_id']?.toString() ??
      data?['payment_id']?.toString() ??
      data?['complaint_id']?.toString() ??
      data?['sos_id']?.toString();

  String get iconName {
    switch (type) {
      case 'activity_created':
        return 'event';
      case 'letter_submitted':
      case 'letter_approved':
      case 'letter_rejected':
      case 'letter_completed':
        return 'mail';
      case 'payment_submitted':
      case 'payment_approved':
      case 'payment_rejected':
        return 'payment';
      case 'complaint_created':
      case 'complaint_updated':
        return 'report_problem';
      case 'sos_alert':
        return 'emergency';
      default:
        return 'notifications';
    }
  }
}
