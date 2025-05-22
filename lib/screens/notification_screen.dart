import 'package:flutter/material.dart';
import '../services/notification_manager.dart';
import 'board_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resetear el contador de notificaciones no leídas cuando se abre la pantalla
    NotificationManager.resetUnreadCount();
  }

  Future<void> _loadNotifications() async {
    final notifications = await NotificationManager.getNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  Future<void> _removeNotification(int index) async {
    await NotificationManager.removeNotification(index);
    await _loadNotifications();
  }

  void _navigateToTask(Map<String, dynamic> notification) {
    // Navegar a la tarea correspondiente
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardDetailScreen(
          board: notification['board'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('No hay notificaciones'))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.blue),
                    title: Text(notification['taskTitle']),
                    subtitle: Text(notification['message']),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeNotification(index),
                    ),
                    onTap: () => _navigateToTask(notification),
                  ),
                );
              },
            ),
    );
  }
}