class Download {
  final String id;
  final String name;
  final String url;
  final bool isActive;
  final bool vipOnly;

  Download({
    required this.id,
    required this.name,
    required this.url,
    required this.isActive,
    required this.vipOnly,
  });

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown',
      url: json['url'] ?? '',
      isActive: json['isActive'] ?? true,
      vipOnly: json['vipOnly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'isActive': isActive,
      'vipOnly': vipOnly,
    };
  }
}
