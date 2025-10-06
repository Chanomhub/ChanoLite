
import 'package:chanolite/models/admin_model.dart';

import 'api_client.dart';

class AdminService {
  final ApiClient _apiClient;

  AdminService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<RoleResponse>> getRoles() async {
    final data = await _apiClient.get('admin/roles');
    // Assuming the response is a list of roles
    return (data as List).map((role) => RoleResponse()).toList();
  }

  Future<List<UserRoleResponse>> getUserRoles(int userId) async {
    final data = await _apiClient.get('admin/users/$userId/roles');
    return (data as List).map((role) => UserRoleResponse()).toList();
  }

  Future<UserRoleResponse> addUserRole(int userId, AddUserRoleDto addUserRoleDto) async {
    final data = await _apiClient.post('admin/users/$userId/roles', body: addUserRoleDto) as Map<String, dynamic>;
    return UserRoleResponse();
  }

  Future<void> removeUserRole(int userId, int roleId) async {
    await _apiClient.delete('admin/users/$userId/roles/$roleId');
  }

  Future<void> deleteArticle(int articleId) async {
    await _apiClient.delete('admin/articles/$articleId');
  }
}
