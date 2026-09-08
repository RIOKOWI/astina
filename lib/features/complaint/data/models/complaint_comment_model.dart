class ComplaintCommentModel {
  final int id;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final _CommentUser user;

  const ComplaintCommentModel({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory ComplaintCommentModel.fromJson(Map<String, dynamic> json) {
    return ComplaintCommentModel(
      id: json['id'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: _CommentUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';

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
    return '${createdAt.day} ${months[createdAt.month - 1]}';
  }
}

class _CommentUser {
  final int id;
  final String name;
  final String? role;

  const _CommentUser({required this.id, required this.name, this.role});

  factory _CommentUser.fromJson(Map<String, dynamic> json) {
    return _CommentUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'User',
      role: json['role'] as String?,
    );
  }

  bool get isRT => role == 'rt';
}
