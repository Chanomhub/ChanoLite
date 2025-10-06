
import 'package:chanolite/models/meta_model.dart';
import 'api_client.dart';

class MetaService {
  final ApiClient _apiClient;

  MetaService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<String>> getTags() async {
    final data = await _apiClient.get('tags') as Map<String, dynamic>;
    return List<String>.from(data['tags']);
  }

  Future<List<String>> getCategories() async {
    final data = await _apiClient.get('categories') as Map<String, dynamic>;
    return List<String>.from(data['categories']);
  }

  Future<List<String>> getPlatforms() async {
    final data = await _apiClient.get('platforms') as Map<String, dynamic>;
    return List<String>.from(data['platforms']);
  }

  Future<List<EngineDto>> getEngines({String? status}) async {
    final endpoint = status != null ? 'engines?status=$status' : 'engines';
    final data = await _apiClient.get(endpoint) as List<dynamic>;
    return data.map((engine) => EngineDto.fromJson(engine as Map<String, dynamic>)).toList();
  }

  Future<EngineDto> approveEngine(int id) async {
    final data = await _apiClient.put('engines/$id/approve') as Map<String, dynamic>;
    return EngineDto.fromJson(data);
  }
}
