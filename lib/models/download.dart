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
      id: json['id'],
      name: json['name'],
      url: json['url'],
      isActive: json['isActive'],
      vipOnly: json['vipOnly'],
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
