
enum DownloadStatus { PENDING, APPROVED, REJECTED }

class DownloadLinkDTO {
  final int id;
  final int articleId;
  final String name;
  final String url;
  final bool isActive;
  final DownloadStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  DownloadLinkDTO({
    required this.id,
    required this.articleId,
    required this.name,
    required this.url,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  factory DownloadLinkDTO.fromJson(Map<String, dynamic> json) {
    return DownloadLinkDTO(
      id: json['id'],
      articleId: json['articleId'],
      name: json['name'],
      url: json['url'],
      isActive: json['isActive'],
      status: DownloadStatus.values.firstWhere((e) => e.toString() == 'DownloadStatus.${json['status']}'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      note: json['note'],
    );
  }
}

class CreateDownloadLinkDTO {
  final int articleId;
  final String name;
  final String url;
  final bool? isActive;
  final String? note;

  CreateDownloadLinkDTO({
    required this.articleId,
    required this.name,
    required this.url,
    this.isActive,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'name': name,
    'url': url,
    if (isActive != null) 'isActive': isActive,
    if (note != null) 'note': note,
  };
}

class UpdateDownloadLinkDTO {
  final String? name;
  final String? url;
  final bool? isActive;
  final String? note;

  UpdateDownloadLinkDTO({
    this.name,
    this.url,
    this.isActive,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (url != null) 'url': url,
    if (isActive != null) 'isActive': isActive,
    if (note != null) 'note': note,
  };
}

class ModerateDownloadLinkDTO {
  final DownloadStatus status;
  final String? note;

  ModerateDownloadLinkDTO({required this.status, this.note});

  Map<String, dynamic> toJson() => {
    'status': status.name,
    if (note != null) 'note': note,
  };
}
