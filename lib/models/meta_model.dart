
class TagsResponse {
  final List<String> tags;

  TagsResponse({required this.tags});

  factory TagsResponse.fromJson(Map<String, dynamic> json) {
    return TagsResponse(tags: List<String>.from(json['tags']));
  }
}

class CategoriesResponse {
  final List<String> categories;

  CategoriesResponse({required this.categories});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(categories: List<String>.from(json['categories']));
  }
}

class PlatformsResponse {
  final List<String> platforms;

  PlatformsResponse({required this.platforms});

  factory PlatformsResponse.fromJson(Map<String, dynamic> json) {
    return PlatformsResponse(platforms: List<String>.from(json['platforms']));
  }
}

class EngineDto {
  final int id;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  EngineDto({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EngineDto.fromJson(Map<String, dynamic> json) {
    return EngineDto(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
