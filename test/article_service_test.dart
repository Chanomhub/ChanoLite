import 'package:chanolite/services/api/api_client.dart';

import 'package:flutter_test/flutter_test.dart';

class FakeApiClient extends ApiClient {
  Map<String, dynamic>? lastVariables;
  String? lastQuery;

  @override
  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables}) async {
    lastQuery = query;
    lastVariables = variables;
    return {
      'data': {
        'article': {
          'id': '1',
          'slug': 'test-article',
          'title': 'Test Article',
          'description': 'Test Description',
          'body': 'Test Body',
          'status': 'published',
          'createdAt': '2023-01-01T00:00:00Z',
          'updatedAt': '2023-01-01T00:00:00Z',
          'images': [],
          'author': {'name': 'Author', 'image': null},
          'creators': [],
          'categories': [],
          'tags': [],
          'platforms': [],
          'favoritesCount': 0,
          'downloads': []
        },
        'downloads': []
      }
    };
  }
}

void main() {
  group('ArticleService', () {

    setUp(() {
      // fakeApiClient = FakeApiClient(); // Unused
    });


  });
}
