import 'package:chanolite/models/mod_model.dart';
import 'package:chanolite/services/api/api_client.dart';

/// Fetches mods listed under an article from the public API.
class ModService {
  final ApiClient _apiClient;

  ModService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Approved mods for an article slug. Throws on HTTP/parse errors.
  Future<List<GameMod>> getModsForArticle(String slug) async {
    final raw = await _apiClient.get('mods/article/$slug');
    // Global interceptor wraps REST payloads in {data: ...}.
    final data = raw is Map<String, dynamic> && raw['data'] != null
        ? raw['data']
        : raw;
    return GameModsResponse.fromJson(data).mods;
  }
}
