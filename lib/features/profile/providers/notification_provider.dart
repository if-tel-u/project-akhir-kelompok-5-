import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../config/constants/api_constants.dart';
import '../../../data/models/user_model.dart';

class NotificationModel {
  final String id;
  final String threadId;
  final String threadName;
  final String content;
  final UserModel sender;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.threadId,
    required this.threadName,
    required this.content,
    required this.sender,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      threadId: json['thread_id'],
      threadName: json['thread_name'],
      content: json['content'],
      sender: UserModel(
        id: json['sender_id'],
        name: json['sender_name'],
        email: json['sender_email'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final response = await _apiClient.get(
        '$notificationsEndpoint?user_id=${UserModel.currentUser.id}${unreadOnly ? "&unread_only=1" : ""}',
      );

      if (response['status'] == 'success') {
        _notifications =
            (response['data'] as List)
                .map((n) => NotificationModel.fromJson(n))
                .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch notifications');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.put(notificationsEndpoint, {
        'notification_id': notificationId,
      });

      if (response['status'] == 'success') {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index].isRead = true;
          notifyListeners();
        }
      } else {
        throw Exception(
          response['message'] ?? 'Failed to mark notification as read',
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
