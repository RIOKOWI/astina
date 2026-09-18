class SosAlertModel {
  final int id;
  final String status;
  final DateTime triggeredAt;
  final SosUser triggeredBy;
  final SosHousehold? household;
  final SosLocation location;
  final DateTime? resolvedAt;
  final SosUser? resolvedBy;
  final List<SosResponse> responses;

  const SosAlertModel({
    required this.id,
    required this.status,
    required this.triggeredAt,
    required this.triggeredBy,
    this.household,
    required this.location,
    this.resolvedAt,
    this.resolvedBy,
    this.responses = const [],
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['id'] as int,
      status: json['status'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      triggeredBy: SosUser.fromJson(
        json['triggered_by'] as Map<String, dynamic>,
      ),
      household: json['household'] != null
          ? SosHousehold.fromJson(json['household'] as Map<String, dynamic>)
          : null,
      location: SosLocation.fromJson(json['location'] as Map<String, dynamic>),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] != null
          ? SosUser.fromJson(json['resolved_by'] as Map<String, dynamic>)
          : null,
      responses:
          (json['responses'] as List<dynamic>?)
              ?.map((e) => SosResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';
}

class SosUser {
  final int id;
  final String name;

  const SosUser({required this.id, required this.name});

  factory SosUser.fromJson(Map<String, dynamic> json) {
    return SosUser(id: json['id'] as int, name: json['name'] as String);
  }
}

class SosHousehold {
  final int id;
  final String? noKk;
  final String address;
  final String? rt;
  final String? rw;
  final String? postalCode;

  const SosHousehold({
    required this.id,
    this.noKk,
    required this.address,
    this.rt,
    this.rw,
    this.postalCode,
  });

  factory SosHousehold.fromJson(Map<String, dynamic> json) {
    return SosHousehold(
      id: json['id'] as int,
      noKk: json['no_kk'] as String?,
      address: json['address'] as String,
      rt: json['rt'] as String?,
      rw: json['rw'] as String?,
      postalCode: json['postal_code'] as String?,
    );
  }
}

class SosLocation {
  final double latitude;
  final double longitude;
  final String? text;

  const SosLocation({
    required this.latitude,
    required this.longitude,
    this.text,
  });

  factory SosLocation.fromJson(Map<String, dynamic> json) {
    return SosLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      text: json['text'] as String?,
    );
  }
}

class SosResponse {
  final int id;
  final String response;
  final DateTime respondedAt;
  final SosUser user;

  const SosResponse({
    required this.id,
    required this.response,
    required this.respondedAt,
    required this.user,
  });

  factory SosResponse.fromJson(Map<String, dynamic> json) {
    return SosResponse(
      id: json['id'] as int,
      response: json['response'] as String,
      respondedAt: DateTime.parse(json['responded_at'] as String),
      user: SosUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
