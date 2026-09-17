import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AppNotification {
  final String id;
  final String message;
  final String? postContent;
  final String timeAgo;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    this.postContent,
    required this.timeAgo,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      postContent: json['post_content'],
      timeAgo: _formatDateString(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }

  static String _formatDateString(String? dateStr) {
    if (dateStr == null) return 'الآن';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 0) return 'منذ ${difference.inDays} أيام';
      if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعات';
      if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقائق';
      return 'الآن';
    } catch (e) {
      return 'الآن';
    }
  }
}

class NotificationService {
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await apiService.get('notifications/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      throw Exception('فشل في جلب الإشعارات: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await apiService.post('notifications/mark_all_read/', {});
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }
}
