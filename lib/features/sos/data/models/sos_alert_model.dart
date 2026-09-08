class SosAlertModel {
  final int id;
  final int senderId;
  final _Sender? sender;
  final double? latitude;
  final double? longitude;
  final String? locationText;
  final String status;
  final List<_SosResponse> responses;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final int? resolvedBy;

  const SosAlertModel({
    required this.id,
    required this.senderId,
    this.sender,
    this.latitude,
    this.longitude,
    this.locationText,
    required this.status,
    this.responses = const [],
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      sender: json['sender'] != null
          ? _Sender.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationText: json['location_text'] as String?,
      status: json['status'] as String,
      responses:
          (json['responses'] as List<dynamic>?)
              ?.map((e) => _SosResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as int?,
    );
  }

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';

  String get formattedTime =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  String get formattedDate {
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
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String? get mapUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps?q=$latitude,$longitude';
    }
    return null;
  }

  int get responseCount => responses.length;
}

class _Sender {
  final int id;
  final String name;
  final String? address;
  final String? phone;

  const _Sender({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory _Sender.fromJson(Map<String, dynamic> json) {
    return _Sender(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Warga',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class _SosResponse {
  final int id;
  final int sosId;
  final int responderId;
  final String? responderName;
  final String response; // 'coming' or 'decline'
  final DateTime createdAt;

  const _SosResponse({
    required this.id,
    required this.sosId,
    required this.responderId,
    this.responderName,
    required this.response,
    required this.createdAt,
  });

  factory _SosResponse.fromJson(Map<String, dynamic> json) {
    return _SosResponse(
      id: json['id'] as int,
      sosId: json['sos_id'] as int,
      responderId: json['responder_id'] as int,
      responderName: json['responder_name'] as String?,
      response: json['response'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isComing => response == 'coming';
  bool get isDecline => response == 'decline';
  String get responseLabel =>
      isComing ? 'Menuju Lokasi' : 'Tidak Bisa Membantu';
}
