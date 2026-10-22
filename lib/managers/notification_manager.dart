import 'package:chanolite/models/notification_model.dart';
import 'package:chanolite/services/api/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Manages the state for in-app notifications, including loading, marking as
/// read, and deleting notifications.
class NotificationManager extends ChangeNotifier {
  NotificationManager({NotificationApiService? apiService})
      : _apiService = apiService ?? NotificationApiService() {
    loadNotifications();
  }

  final NotificationApiService _apiService;

  List<NotificationResponse> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationResponse> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads notifications from the API (up to 50 most recent).
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications(take: 50);
      _notifications = response.notifications;
      _unreadCount = response.unreadCount;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a single notification as read by [id], then updates local state.
  Future<void> markAsRead(int id) async {
    try {
      await _apiService.markNotificationAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index >= 0 && !_notifications[index].isRead) {
        _notifications = List.from(_notifications)
          ..[index] = NotificationResponse(
            id: _notifications[index].id,
            userId: _notifications[index].userId,
            type: _notifications[index].type,
            message: _notifications[index].message,
            isRead: true,
            entityId: _notifications[index].entityId,
            entityType: _notifications[index].entityType,
            createdAt: _notifications[index].createdAt,
            updatedAt: _notifications[index].updatedAt,
          );
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marks all notifications as read via the API, then updates local state.
  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      _notifications = _notifications
          .map(
            (n) => NotificationResponse(
              id: n.id,
              userId: n.userId,
              type: n.type,
              message: n.message,
              isRead: true,
              entityId: n.entityId,
              entityType: n.entityType,
              createdAt: n.createdAt,
              updatedAt: n.updatedAt,
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deletes a single notification by [id], removes it from the local list,
  /// and updates [unreadCount].
  Future<void> deleteNotification(int id) async {
    try {
      await _apiService.deleteNotification(id);
      final removed = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => _notifications.first,
      );
      final wasUnread = !removed.isRead && _notifications.any((n) => n.id == id);
      _notifications = _notifications.where((n) => n.id != id).toList();
      if (wasUnread) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deletes all notifications via the API and clears the local list.
  Future<void> deleteAll() async {
    try {
      await _apiService.deleteAllNotifications();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
