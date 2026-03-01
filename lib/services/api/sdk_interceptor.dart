import 'package:dio/dio.dart';

/// Interceptor to fix type mismatch issues from the Chanomhub backend 
/// before the SDK's json_serializable models attempt to parse them.
class SdkTypeFixInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data is Map<String, dynamic> && options.data['query'] is String) {
      String query = options.data['query'];
      
      // Pattern to match 'downloads { ... }' and capture the content inside braces
      // This handles nested braces by finding the matching closing brace for the downloads block
      final downloadsRegex = RegExp(r'downloads\s*\{([^{}]*)\}');
      
      if (query.contains('downloads')) {
        print('Intercepting GraphQL query: Checking for unsupported fields in downloads block');
        
        String fixedQuery = query;
        // Basic replacement for simple cases, and more advanced if needed
        // Since the SDK queries are usually flat within the downloads block:
        fixedQuery = fixedQuery.replaceAllMapped(downloadsRegex, (match) {
          String content = match.group(1) ?? '';
          String fixedContent = content
            .replaceAll('createdAt', '')
            .replaceAll('updatedAt', '')
            .replaceAll('forVersion', '');
          return 'downloads { $fixedContent }';
        });
        
        if (fixedQuery != query) {
          print('Fixed downloads block in GraphQL query');
          options.data['query'] = fixedQuery;
        }
      } else if (query.contains('forVersion')) {
          // Fallback for cases where forVersion is outside downloads if any
          options.data['query'] = query.replaceAll('forVersion', '');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final path = response.requestOptions.path;
      if (path.contains('/graphql')) {
        response.data = _fixGraphqlData(response.data);
      } else if (path.contains('/api/users') || path.contains('/api/auth')) {
        response.data = _fixRestData(response.data);
      }
    }
    super.onResponse(response, handler);
  }

  dynamic _fixGraphqlData(dynamic data) {
    if (data is List) {
      return data.map((e) => _fixGraphqlData(e)).toList();
    } else if (data is Map<String, dynamic>) {
      final fixed = <String, dynamic>{};
      data.forEach((key, value) {
        if (key == 'articles' || key == 'mods' || key == 'downloads' || key == 'items') {
          fixed[key] = (value as List?)?.map((e) => _fixArticleObject(e)).toList();
        } else if (key == 'article' || key == 'author') {
          fixed[key] = _fixArticleObject(value);
        } else if ((key == 'total' || key == 'offset' || key == 'limit') && value is String) {
          fixed[key] = int.tryParse(value) ?? value;
        } else {
          fixed[key] = _fixGraphqlData(value);
        }
      });
      return fixed;
    }
    return data;
  }

  dynamic _fixArticleObject(dynamic item) {
    if (item is! Map<String, dynamic>) return item;
    final fixed = <String, dynamic>{};
    item.forEach((k, v) {
      if (k == 'id' && v is String) {
        fixed[k] = int.tryParse(v) ?? v; // SDK expects int for Article, Mod, Download id
      } else if (k == 'favoritesCount' && v is String) {
        fixed[k] = int.tryParse(v) ?? 0; // SDK expects int
      } else if (k == 'author' && v is Map<String, dynamic>) {
        final authorFixed = Map<String, dynamic>.from(v);
        if (authorFixed['id'] is String) {
           authorFixed['id'] = int.tryParse(authorFixed['id']); // SDK expects int? for Author id
        }
        fixed[k] = authorFixed;
      } else if (v is String && RegExp(r'^\d+$').hasMatch(v)) {
        // Broadly fix any numeric string that might be causing the 'num' type cast error
        fixed[k] = num.tryParse(v) ?? v;
      } else {
        // Leave tags, categories, platforms intact because SDK expects String id for NamedEntity
        fixed[k] = v;
      }
    });
    return fixed;
  }

  dynamic _fixRestData(dynamic data) {
     if (data is Map<String, dynamic>) {
        final fixed = Map<String, dynamic>.from(data);
        if (fixed.containsKey('user') && fixed['user'] is Map) {
           final userFixed = Map<String, dynamic>.from(fixed['user']);
           if (userFixed['points'] is String) {
              userFixed['points'] = num.tryParse(userFixed['points']) ?? 0;
           }
           fixed['user'] = userFixed;
        }
        return fixed;
     }
     return data;
  }
}
