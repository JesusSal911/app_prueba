import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';

class NotificationService {
  static const String _notificationsKey = 'notifications';

  // Tiempos de notificación antes del inicio y fin de la tarea (en minutos)
  static const List<int> _notificationTimes = [60, 30, 10, 0];

  // Crear notificaciones para una tarea
  static Future<void> createTaskNotifications(Map<String, dynamic> task, Map<String, dynamic> board) async {
    final List<Map<String, dynamic>> notifications = [];
    final DateTime startDateTime = _parseDateTime(task['startDate'], task['startTime']);
    final DateTime endDateTime = _parseDateTime(task['endDate'], task['endTime']);

    // Crear notificaciones para el inicio de la tarea
    for (var minutes in _notificationTimes) {
      final DateTime notificationTime = startDateTime.subtract(Duration(minutes: minutes));
      if (notificationTime.isAfter(DateTime.now())) {
        final int notificationId = DateTime.now().millisecondsSinceEpoch.hashCode;
        notifications.add({
          'id': notificationId,
          'taskTitle': task['title'],
          'message': minutes > 0
              ? 'La tarea comenzará en ${_formatTimeRemaining(minutes)}'
              : 'La tarea ha comenzado',
          'time': notificationTime.millisecondsSinceEpoch,
          'board': board,
          'task': task,
        });

        await LocalNotificationService.scheduleTaskNotification(
          id: notificationId,
          title: task['title'],
          body: minutes > 0
              ? 'La tarea comenzará en ${_formatTimeRemaining(minutes)}'
              : 'La tarea ha comenzado',
          scheduledDate: notificationTime,
        );
      }
    }

    // Crear notificaciones para el fin de la tarea
    for (var minutes in _notificationTimes) {
      final DateTime notificationTime = endDateTime.subtract(Duration(minutes: minutes));
      if (notificationTime.isAfter(DateTime.now())) {
        final int notificationId = DateTime.now().millisecondsSinceEpoch.hashCode;
        notifications.add({
          'id': notificationId,
          'taskTitle': task['title'],
          'message': minutes > 0
              ? 'La tarea finalizará en ${_formatTimeRemaining(minutes)}'
              : 'La tarea ha finalizado',
          'time': notificationTime.millisecondsSinceEpoch,
          'board': board,
          'task': task,
        });

        await LocalNotificationService.scheduleTaskNotification(
          id: notificationId,
          title: task['title'],
          body: minutes > 0
              ? 'La tarea finalizará en ${_formatTimeRemaining(minutes)}'
              : 'La tarea ha finalizado',
          scheduledDate: notificationTime,
        );
      }
    }

    // Guardar las notificaciones
    await _saveNotifications(notifications);
  }

  // Cargar todas las notificaciones
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);
    if (notificationsJson != null) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(notificationsJson).map((x) => Map<String, dynamic>.from(x)));
    }
    return [];
  }

  // Guardar notificaciones
  static Future<void> _saveNotifications(List<Map<String, dynamic>> newNotifications) async {
    final List<Map<String, dynamic>> currentNotifications = await getNotifications();
    currentNotifications.addAll(newNotifications);
    
    // Ordenar notificaciones por tiempo
    currentNotifications.sort((a, b) => a['time'].compareTo(b['time']));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(currentNotifications));
  }

  // Eliminar una notificación
  static Future<void> removeNotification(int index) async {
    final List<Map<String, dynamic>> notifications = await getNotifications();
    notifications.removeAt(index);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  // Convertir fecha y hora en formato string a DateTime
  static DateTime _parseDateTime(String date, String time) {
    final List<String> dateParts = date.split('/');
    final List<String> timeParts = time.split(':');
    
    return DateTime(
      int.parse(dateParts[2]), // año
      int.parse(dateParts[1]), // mes
      int.parse(dateParts[0]), // día
      int.parse(timeParts[0]), // hora
      int.parse(timeParts[1]), // minutos
    );
  }

  // Formatear el tiempo restante
  static String _formatTimeRemaining(int minutes) {
    if (minutes >= 60) {
      return '1 hora';
    } else {
      return '$minutes minutos';
    }
  }
}