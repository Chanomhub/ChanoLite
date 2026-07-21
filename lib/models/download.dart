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
    final name = json['name']?.toString() ?? 'Unknown';
    final url = json['url']?.toString() ?? '';
    final fallbackId = url.isNotEmpty ? url.hashCode.toString() : name.hashCode.toString();

    return Download(
      id: json['id']?.toString() ?? fallbackId,
      name: name,
      url: url,
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
