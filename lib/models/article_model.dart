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
      engine: json['engine'],
      mainImage: json['mainImage'],
      images: (json['images'] != null && json['images'].isNotEmpty && json['images'][0] is Map)
          ? (json['images'] as List).map((e) => e['url'] as String).toList()
          : List<String>.from(json['images'] ?? []),
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

  factory Author.dummy() {
    return Author(
      id: '0',
      name: 'Chano-chan',
      image: '',
    );
  }
}
