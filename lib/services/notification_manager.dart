import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationManager {
  static const String _unreadCountKey = 'unread_notifications_count';
  static const String _notificationsKey = 'notifications';

  static Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unreadCountKey) ?? 0;
  }

  static Future<void> incrementUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_unreadCountKey) ?? 0;
    await prefs.setInt(_unreadCountKey, currentCount + 1);
  }

  static Future<void> resetUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unreadCountKey, 0);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);
    if (notificationsJson != null) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(notificationsJson).map((x) => Map<String, dynamic>.from(x)));
    }
    return [];
  }

  static Future<void> addNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
    await incrementUnreadCount();
  }

  static Future<void> removeNotification(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    if (index >= 0 && index < notifications.length) {
      notifications.removeAt(index);
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }
}