import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notification_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // Solicitar permisos de notificación al inicializar
    await _requestNotificationPermissions();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Manejar la interacción con la notificación aquí
      },
    );

    // Crear canal de notificación para Android
    await _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        'task_notifications',
        'Notificaciones de Tareas',
        description: 'Canal para notificaciones de tareas',
        importance: Importance.high,
      ),
    );
  }

  static Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? minutesBefore, // Nuevo parámetro opcional para flexibilidad
  }) async {
    try {
      var now = tz.TZDateTime.now(tz.local);
      var scheduledDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      if (scheduledDateTime.isBefore(now)) {
        throw Exception('La fecha programada debe ser posterior a la actual');
      }
      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'task_notifications',
          'Notificaciones de Tareas',
          channelDescription: 'Canal para notificaciones de tareas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      // Si se especifica un recordatorio antes, programar esa notificación
      if (minutesBefore != null && minutesBefore > 0) {
        final reminderDateTime = tz.TZDateTime.from(scheduledDate.subtract(Duration(minutes: minutesBefore)), tz.local);
        if (reminderDateTime.isAfter(now)) {
          await _notificationsPlugin.zonedSchedule(
            id + 1,
            'Recordatorio: $minutesBefore minutos para $title',
            body,
            reminderDateTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
      // Programar notificación principal
      if (scheduledDateTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      print('Error al programar la notificación: \$e');
      rethrow;
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> _requestNotificationPermissions() async {
    // iOS/macOS (solicitar permisos específicos)
    final iOSPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOSPlatform != null) {
      await iOSPlatform.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
        provisional: false,
      );
    }
    // Android 13+ (solicitar permisos de notificación)
    if (await Permission.notification.isDenied || await Permission.notification.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

}