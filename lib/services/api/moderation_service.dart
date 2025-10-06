import 'package:chanolite/models/moderation_model.dart';
import 'api_client.dart';

class ModerationService {
  final ApiClient _apiClient;

  ModerationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<ModerationRequest>> getModerationRequests({ModerationStatus? status}) async {
    final endpoint = 'moderation/requests${status != null ? '?status=${status.name}' : ''}';
    final data = await _apiClient.get(endpoint) as List<dynamic>;
    return data.map((request) => ModerationRequest.fromJson(request as Map<String, dynamic>)).toList();
  }

  Future<ModerationRequest> createModerationRequest(String entityType, int entityId, String? requestNote) async {
    final data = await _apiClient.post('moderation/requests', body: {
      'entityType': entityType,
      'entityId': entityId,
      'requestNote': requestNote,
    }) as Map<String, dynamic>;
    return ModerationRequest.fromJson(data);
  }

  Future<ModerationRequest> getModerationRequestById(int id) async {
    final data = await _apiClient.get('moderation/requests/$id') as Map<String, dynamic>;
    return ModerationRequest.fromJson(data);
  }

  Future<ModerationRequest> updateModerationRequest(int id, ModerationStatus status, String? reviewNote) async {
    final data = await _apiClient.put('moderation/requests/$id', body: {
      'status': status.name,
      'reviewNote': reviewNote,
    }) as Map<String, dynamic>;
    return ModerationRequest.fromJson(data);
  }

  Future<void> deleteModerationRequest(int id) async {
    await _apiClient.delete('moderation/requests/$id');
  }
}