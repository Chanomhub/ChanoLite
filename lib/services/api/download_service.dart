import 'package:chanolite/models/download_model.dart';
import 'api_client.dart';

class DownloadService {
  final ApiClient _apiClient;

  DownloadService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<DownloadLinkDTO>> getDownloadLinks(int articleId) async {
    final response = await _apiClient.get('downloads/article/$articleId');
    final responseMap = response as Map<String, dynamic>;
    final linksList = responseMap['links'] as List;
    return linksList.map((item) => DownloadLinkDTO.fromJson(item)).toList();
  }
}