
class CreateModDto {
  final String name;
  final String description;
  final String version;
  final String downloadLink;
  final String? creditTo;
  final List<String> images;
  final String type;
  final List<int> categoryIds;

  CreateModDto({
    required this.name,
    required this.description,
    required this.version,
    required this.downloadLink,
    this.creditTo,
    required this.images,
    required this.type,
    required this.categoryIds,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'version': version,
    'downloadLink': downloadLink,
    if (creditTo != null) 'creditTo': creditTo,
    'images': images,
    'type': type,
    'categoryIds': categoryIds,
  };
}

class UpdateModDto {
  final String? name;
  final String? description;
  final String? version;
  final String? downloadLink;
  final String? creditTo;
  final List<String>? images;
  final String? type;
  final List<int>? categoryIds;

  UpdateModDto({
    this.name,
    this.description,
    this.version,
    this.downloadLink,
    this.creditTo,
    this.images,
    this.type,
    this.categoryIds,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (version != null) 'version': version,
    if (downloadLink != null) 'downloadLink': downloadLink,
    if (creditTo != null) 'creditTo': creditTo,
    if (images != null) 'images': images,
    if (type != null) 'type': type,
    if (categoryIds != null) 'categoryIds': categoryIds,
  };
}

enum ModStatus { PENDING, APPROVED, REJECTED }

class Mod {
  final int id;
  final String name;
  final String description;
  final String version;
  final String downloadLink;
  final String? creditTo;
  final List<String> images;
  final String type;
  final ModStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int articleId;
  final int authorId;
  final List<ModCategory> categories;

  Mod({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.downloadLink,
    this.creditTo,
    required this.images,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.articleId,
    required this.authorId,
    required this.categories,
  });

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      version: json['version'],
      downloadLink: json['downloadLink'],
      creditTo: json['creditTo'],
      images: List<String>.from(json['images']),
      type: json['type'],
      status: ModStatus.values.firstWhere((e) => e.toString() == 'ModStatus.${json['status']}'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      articleId: json['articleId'],
      authorId: json['authorId'],
      categories: (json['categories'] as List)
          .map((e) => ModCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ModCategory {
  final int id;
  final String name;
  final String slug;

  ModCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ModCategory.fromJson(Map<String, dynamic> json) {
    return ModCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}

class CreateModCategoryDto {
  final String name;
  final String slug;

  CreateModCategoryDto({required this.name, required this.slug});

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
  };
}

class ModCategoryResponseDto {
  final int id;
  final String name;
  final String slug;

  ModCategoryResponseDto({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ModCategoryResponseDto.fromJson(Map<String, dynamic> json) {
    return ModCategoryResponseDto(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}

class SingleModResponse {
  final Mod mod;

  SingleModResponse({required this.mod});

  factory SingleModResponse.fromJson(Map<String, dynamic> json) {
    return SingleModResponse(mod: Mod.fromJson(json['mod']));
  }
}

class MultipleModsResponse {
  final List<Mod> mods;
  final int modsCount;

  MultipleModsResponse({required this.mods, required this.modsCount});

  factory MultipleModsResponse.fromJson(Map<String, dynamic> json) {
    return MultipleModsResponse(
      mods: (json['mods'] as List).map((e) => Mod.fromJson(e as Map<String, dynamic>)).toList(),
      modsCount: json['modsCount'],
    );
  }
}
