
enum ModerationStatus { PENDING, APPROVED, REJECTED, NEEDS_REVISION }

class ModerationRequest {
  final int id;
  final String entityType;
  final int entityId;
  final ModerationStatus status;
  final String? requestNote;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int requesterId;
  final int? reviewerId;
  final Requester requester;
  final Reviewer? reviewer;
  final Map<String, dynamic>? entityDetails;

  ModerationRequest({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.status,
    this.requestNote,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
    required this.requesterId,
    this.reviewerId,
    required this.requester,
    this.reviewer,
    this.entityDetails,
  });

  factory ModerationRequest.fromJson(Map<String, dynamic> json) {
    return ModerationRequest(
      id: json['id'],
      entityType: json['entityType'],
      entityId: json['entityId'],
      status: ModerationStatus.values.firstWhere((e) => e.toString() == 'ModerationStatus.${json['status']}'),
      requestNote: json['requestNote'],
      reviewNote: json['reviewNote'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      requesterId: json['requesterId'],
      reviewerId: json['reviewerId'],
      requester: Requester.fromJson(json['requester']),
      reviewer: json['reviewer'] != null ? Reviewer.fromJson(json['reviewer']) : null,
      entityDetails: json['entityDetails'],
    );
  }
}

class Requester {
  final int id;
  final String name;
  final String? image;

  Requester({required this.id, required this.name, this.image});

  factory Requester.fromJson(Map<String, dynamic> json) {
    return Requester(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}

class Reviewer {
  final int id;
  final String name;
  final String? image;

  Reviewer({required this.id, required this.name, this.image});

  factory Reviewer.fromJson(Map<String, dynamic> json) {
    return Reviewer(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}
