import 'package:chanolite/models/download.dart';

class ArticlesResponse {
  final List<Article> articles;
  final int? articlesCount;

  ArticlesResponse({required this.articles, this.articlesCount});

  factory ArticlesResponse.fromJson(Map<String, dynamic> json) {
    return ArticlesResponse(
      articles: (json['articles'] as List)
          .map((article) => Article.fromJson(article))
          .toList(),
      articlesCount: json['articlesCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articles': articles.map((article) => article.toJson()).toList(),
      'articlesCount': articlesCount,
    };
  }
}

class Article {
  final int id;
  final String title;
  final String? slug;
  final String description;
  final String body;
  final dynamic ver;
  final int? version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? engine;
  final dynamic mainImage;
  final List<String> images;
  final dynamic backgroundImage;
  final dynamic coverImage;
  final List<String> tagList;
  final List<String> categoryList;
  final List<String> platformList;
  final Author author;
  final bool favorited;
  final int favoritesCount;
  final dynamic sequentialCode;
  final List<Download> downloads;

  Article({
    required this.id,
    required this.title,
    this.slug,
    required this.description,
    required this.body,
    this.ver,
    this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.engine,
    this.mainImage,
    required this.images,
    this.backgroundImage,
    this.coverImage,
    required this.tagList,
    required this.categoryList,
    required this.platformList,
    required this.author,
    required this.favorited,
    required this.favoritesCount,
    this.sequentialCode,
    required this.downloads,
  });

  Article.idOnly(this.id)
      : title = '',
        slug = '',
        description = '',
        body = '',
        ver = null,
        version = null,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        status = '',
        engine = null,
        mainImage = null,
        images = [],
        backgroundImage = null,
        coverImage = null,
        tagList = [],
        categoryList = [],
        platformList = [],
        author = Author.dummy(),
        favorited = false,
        favoritesCount = 0,
        sequentialCode = null,
        downloads = [];

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] is String) ? int.parse(json['id']) : json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'],
      body: json['body'],
      ver: json['ver'],
      version: json['version'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: json['status'],
      engine: json['engine']?['name'] as String?,
      mainImage: json['mainImage'],
      images: (() {
        final dynamic imagesData = json['images'];
        if (imagesData == null) {
          return <String>[];
        } else if (imagesData is List) {
          return imagesData.map<String>((e) {
            if (e is Map && e.containsKey('url')) {
              return e['url'] as String;
            } else if (e is String) {
              return e;
            }
            return ''; // Default or error handling for unexpected types in list
          }).where((element) => element.isNotEmpty).toList();
        } else if (imagesData is Map && imagesData.containsKey('url')) {
          return [imagesData['url'] as String];
        }
        return <String>[]; // Default for unexpected types
      })(),
      backgroundImage: json['backgroundImage'],
      coverImage: json['coverImage'],
      tagList: (json['tags'] != null)
          ? (json['tags'] as List).map((e) => e['name'] as String).toList()
          : List<String>.from(json['tagList'] ?? []),
      categoryList: (json['categories'] != null)
          ? (json['categories'] as List).map((e) => e['name'] as String).toList()
          : List<String>.from(json['categoryList'] ?? []),
      platformList: (json['platforms'] != null)
          ? (json['platforms'] as List).map((e) => e['name'] as String).toList()
          : List<String>.from(json['platformList'] ?? []),
      author: Author.fromJson(json['author']),
      favorited: json['favorited'] ?? false,
      favoritesCount: json['favoritesCount'] ?? 0,
      sequentialCode: json['sequentialCode'],
      downloads: (json['downloads'] as List? ?? []).map((e) => Download.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'body': body,
      'ver': ver,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'engine': engine,
      'mainImage': mainImage,
      'images': images,
      'backgroundImage': backgroundImage,
      'coverImage': coverImage,
      'tagList': tagList,
      'categoryList': categoryList,
      'platformList': platformList,
      'author': author.toJson(),
      'favorited': favorited,
      'favoritesCount': favoritesCount,
      'sequentialCode': sequentialCode,
      'downloads': downloads.map((e) => e.toJson()).toList(),
    };
  }

  Article copyWith({
    int? id,
    String? title,
    String? slug,
    String? description,
    String? body,
    dynamic ver,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? engine,
    dynamic mainImage,
    List<String>? images,
    dynamic backgroundImage,
    dynamic coverImage,
    List<String>? tagList,
    List<String>? categoryList,
    List<String>? platformList,
    Author? author,
    bool? favorited,
    int? favoritesCount,
    dynamic sequentialCode,
    List<Download>? downloads,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      body: body ?? this.body,
      ver: ver ?? this.ver,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      engine: engine ?? this.engine,
      mainImage: mainImage ?? this.mainImage,
      images: images ?? this.images,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      coverImage: coverImage ?? this.coverImage,
      tagList: tagList ?? this.tagList,
      categoryList: categoryList ?? this.categoryList,
      platformList: platformList ?? this.platformList,
      author: author ?? this.author,
      favorited: favorited ?? this.favorited,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      sequentialCode: sequentialCode ?? this.sequentialCode,
      downloads: downloads ?? this.downloads,
    );
  }

  factory Article.dummy() {
    return Article(
      id: 0,
      title: 'Loading article...', 
      slug: 'loading-article',
      description: 'This is a placeholder for a loading article. The content is being fetched.',
      body: 'Loading...',
      ver: '1.0',
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'PUBLISHED',
      engine: 'Flutter',
      mainImage: null,
      images: [],
      backgroundImage: null,
      coverImage: null,
      tagList: ['loading', 'skeleton'],
      categoryList: ['news'],
      platformList: ['android', 'ios'],
      author: Author.dummy(),
      favorited: false,
      favoritesCount: 99,
      sequentialCode: null,
      downloads: [],
    );
  }
}

class Author {
  final String? id;
  final String name;
  final String? image;

  Author({
    this.id,
    required this.name,
    this.image,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'] ?? json['username'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }

  factory Author.dummy() {
    return Author(
      id: '0',
      name: 'Chano-chan',
      image: '',
    );
  }
}
