import 'package:flutter/material.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/signalr_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;
  final SignalRService _signalRService;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._apiService, this._signalRService) {
    _setupSignalRListeners();
  }

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setupSignalRListeners() {
    _signalRService.onNotificationReceived((notification) {
      try {
        final notificationModel = NotificationModel.fromJson(notification);
        _notifications.insert(0, notificationModel);
        if (!notificationModel.isRead) {
          _unreadCount++;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing notification: $e');
      }
    });
  }

  Future<void> loadNotifications({int page = 1, int pageSize = 20}) async {
    if (page == 1) _setLoading(true);
    
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/notifications',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      
      final newNotifications = (response.data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      if (page == 1) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }
      
      // Load unread count
      await _loadUnreadCount();
      
      _clearError();
    } catch (e) {
      _setError('Lỗi tải thông báo: ${e.toString()}');
    } finally {
      if (page == 1) _setLoading(false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/notifications/summary');
      _unreadCount = response.data?['unreadCount'] ?? 0;
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      await _apiService.put<Map<String, dynamic>>('/api/notifications/$notificationId/read');
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          linkUrl: _notifications[index].linkUrl,
          isRead: true,
          createdDate: _notifications[index].createdDate,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Lỗi đánh dấu đã đọc: ${e.toString()}');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiService.put<Map<String, dynamic>>('/api/notifications/read-all');
      
      // Update local state
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        linkUrl: n.linkUrl,
        isRead: true,
        createdDate: n.createdDate,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Lỗi đánh dấu tất cả đã đọc: ${e.toString()}');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}