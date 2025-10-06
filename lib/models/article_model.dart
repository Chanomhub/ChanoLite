
class ArticlesResponse {
  final List<Article> articles;
  final int articlesCount;

  ArticlesResponse({required this.articles, required this.articlesCount});

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
  final String slug;
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

  Article({
    required this.id,
    required this.title,
    required this.slug,
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
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
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
      images: List<String>.from(json['images']),
      backgroundImage: json['backgroundImage'],
      coverImage: json['coverImage'],
      tagList: List<String>.from(json['tagList']),
      categoryList: List<String>.from(json['categoryList']),
      platformList: List<String>.from(json['platformList']),
      author: Author.fromJson(json['author']),
      favorited: json['favorited'],
      favoritesCount: json['favoritesCount'],
      sequentialCode: json['sequentialCode'],
    );
  }
}

class Author {
  final String username;
  final dynamic bio;
  final dynamic image;
  final dynamic backgroundImage;
  final bool following;
  final List<SocialMediaLink> socialMediaLinks;

  Author({
    required this.username,
    this.bio,
    this.image,
    this.backgroundImage,
    required this.following,
    required this.socialMediaLinks,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      username: json['username'],
      bio: json['bio'],
      image: json['image'],
      backgroundImage: json['backgroundImage'],
      following: json['following'],
      socialMediaLinks: (json['socialMediaLinks'] as List? ?? [])
          .map((e) => SocialMediaLink.fromJson(e))
          .toList(),
    );
  }
}

class SocialMediaLink {
  final String platform;
  final String url;

  SocialMediaLink({required this.platform, required this.url});

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) {
    return SocialMediaLink(
      platform: json['platform'],
      url: json['url'],
    );
  }
}
