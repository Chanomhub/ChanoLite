/// GraphQL field definitions for API queries.
/// Centralized here to avoid duplication across screens.
class GraphQLFields {
  GraphQLFields._();

  /// Fields for article detail screen
  static const String articleDetail = r'''
    id
    slug
    sequentialCode
    title
    description
    body
    status
    ver
    coverImage
    backgroundImage
    images {
      url
    }
    author {
      name
      image
    }
    creators {
      name
    }
    categories {
      name
    }
    tags {
      name
    }
    platforms {
      name
    }
    engine {
      name
    }
    favoritesCount
    createdAt
    updatedAt
  ''';

  /// Fields for home screen article list
  static const String homeArticle = r'''
    id
    title
    description
    slug
    coverImage
    mainImage
    backgroundImage
    favoritesCount
    updatedAt
    tags {
      name
    }
    platforms {
      name
    }
  ''';

  /// Fields for search results
  static const String searchArticle = r'''
    id
    title
    description
    slug
    coverImage
    mainImage
    status
    ver
    favoritesCount
    updatedAt
    tags {
      name
    }
    categories {
      name
    }
    platforms {
      name
    }
    engine {
      name
    }
  ''';
}
