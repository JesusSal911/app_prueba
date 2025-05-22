import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/notification_service.dart';

class BoardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> board;

  const BoardDetailScreen({super.key, required this.board});

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingTasks = [];
  List<Map<String, dynamic>> _completedTasks = [];
  
  // Clave para almacenar las tareas en SharedPreferences
  String get _tasksKey => 'tasks_${widget.board["title"]}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }
  
  // Cargar las tareas del tablero desde SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);
    
    if (tasksJson != null) {
      final Map<String, dynamic> tasksData = jsonDecode(tasksJson);
      setState(() {
        _pendingTasks = List<Map<String, dynamic>>.from(tasksData['pending'] ?? []);
        _completedTasks = List<Map<String, dynamic>>.from(tasksData['completed'] ?? []);
      });
    }
  }
  
  // Guardar las tareas del tablero en SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> tasksData = {
      'pending': _pendingTasks,
      'completed': _completedTasks,
    };
    await prefs.setString(_tasksKey, jsonEncode(tasksData));
    // Forzar actualización del estado después de guardar
    setState(() {
      _pendingTasks = List<Map<String, dynamic>>.from(_pendingTasks);
      _completedTasks = List<Map<String, dynamic>>.from(_completedTasks);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditBoardDialog() {
    final TextEditingController controller = TextEditingController(text: widget.board['title']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar tablero'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nombre del tablero',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Guardar el cambio en SharedPreferences y actualizar la UI
              await _updateBoardTitle(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tablero'),
        content: const Text('¿Estás seguro de que deseas eliminar este tablero? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Eliminar el tablero de SharedPreferences
              await _deleteBoard();
              Navigator.pop(context); // Cerrar el diálogo
              Navigator.pop(context); // Volver a la pantalla anterior
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite() async {
    // Cambiar el estado de favorito localmente
    setState(() {
      widget.board['isFavorite'] = !(widget.board['isFavorite'] as bool);
    });
    
    // Guardar el cambio en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? boardsJson = prefs.getString('boards');
    
    if (boardsJson != null) {
      List<Map<String, dynamic>> boards = List<Map<String, dynamic>>.from(
        jsonDecode(boardsJson).map((x) => Map<String, dynamic>.from(x)));
      
      // Encontrar y actualizar el tablero correspondiente
      final int index = boards.indexWhere((b) => b['title'] == widget.board['title']);
      if (index != -1) {
        boards[index]['isFavorite'] = widget.board['isFavorite'];
        await prefs.setString('boards', jsonEncode(boards));
      }
    }
  }

  Future<void> _deleteBoard() async {
    // Obtener la lista actual de tableros
    final prefs = await SharedPreferences.getInstance();
    final String? boardsJson = prefs.getString('boards');
    
    if (boardsJson != null) {
      List<Map<String, dynamic>> boards = List<Map<String, dynamic>>.from(
        jsonDecode(boardsJson).map((x) => Map<String, dynamic>.from(x)));
      
      // Encontrar y eliminar el tablero correspondiente
      final int index = boards.indexWhere((b) => b['title'] == widget.board['title']);
      if (index != -1) {
        boards.removeAt(index);
        // Guardar la lista actualizada sin el tablero eliminado
        await prefs.setString('boards', jsonEncode(boards));
      }
    }
  }

  Future<void> _updateBoardTitle(String newTitle) async {
    // Obtener la lista actual de tableros
    final prefs = await SharedPreferences.getInstance();
    final String? boardsJson = prefs.getString('boards');
    
    if (boardsJson != null) {
      List<Map<String, dynamic>> boards = List<Map<String, dynamic>>.from(
        jsonDecode(boardsJson).map((x) => Map<String, dynamic>.from(x)));
      
      // Encontrar y actualizar el tablero correspondiente
      final int index = boards.indexWhere((b) => b['title'] == widget.board['title']);
      if (index != -1) {
        // Actualizar el título en la lista de tableros
        boards[index]['title'] = newTitle;
        // Guardar la lista actualizada con el título modificado
        await prefs.setString('boards', jsonEncode(boards));
        
        // Actualizar el título en el objeto actual para que se refleje en la UI
        setState(() {
          widget.board['title'] = newTitle;
        });
      }
    }
  }

  void _showTaskFormDialog({Map<String, dynamic>? task}) {
    final TextEditingController titleController = TextEditingController(text: task?['title'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: task?['description'] ?? '');
    DateTime startDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay endTime = TimeOfDay.now();
    List<String> attachedFiles = List<String>.from(task?['attachedFiles'] ?? []);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task == null ? 'Nueva tarea' : 'Editar tarea',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Fecha y hora de inicio:'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                            });
                          }
                        },
                        child: Text(
                          '${startDate.day}/${startDate.month}/${startDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                            initialEntryMode: TimePickerEntryMode.input,
                            builder: (context, child) {
                              return MediaQuery(                                
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              startTime = picked;
                            });
                          }
                        },
                        child: Text(
                          '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Fecha y hora de finalización:'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                        child: Text(
                          '${endDate.day}/${endDate.month}/${endDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                            initialEntryMode: TimePickerEntryMode.input,
                            builder: (context, child) {
                              return MediaQuery(                                
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              endTime = picked;
                            });
                          }
                        },
                        child: Text(
                          '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Archivos adjuntos:'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.any,
                          );
                          
                          if (result != null) {
                            setState(() {
                              for (var file in result.files) {
                                attachedFiles.add(file.name);
                              }
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al seleccionar archivos: $e')),
                            );
                          }
                        }
                      },
                      tooltip: 'Adjuntar archivo',
                    ),
                  ],
                ),
                if (attachedFiles.isNotEmpty)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: attachedFiles.length,
                      itemBuilder: (context, index) {
                        return Chip(
                          label: Text(
                            attachedFiles[index],
                            style: const TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.grey[200],
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              attachedFiles.removeAt(index);
                            });
                          },
                          padding: const EdgeInsets.only(right: 8),
                        );
                      },
                    ),
                  ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isNotEmpty) {
                            final taskData = {
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'startDate': '${startDate.day}/${startDate.month}/${startDate.year}',
                              'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                              'endDate': '${endDate.day}/${endDate.month}/${endDate.year}',
                              'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
                              'attachedFiles': attachedFiles,
                              'createdAt': task?['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                            };
                            
                            Navigator.pop(context);
                            setState(() {
                              if (task != null) {
                                // Actualizar tarea existente
                                final index = _pendingTasks.indexOf(task);
                                if (index != -1) {
                                  _pendingTasks[index] = taskData;
                                } else {
                                  final completedIndex = _completedTasks.indexOf(task);
                                  if (completedIndex != -1) {
                                    _completedTasks[completedIndex] = taskData;
                                  }
                                }
                              } else {
                                // Añadir nueva tarea
                                _pendingTasks.add(taskData);
                              }
                            });
                            
                            await _saveTasks();
                            
                            // Crear notificaciones para la tarea
                            await NotificationService.createTaskNotifications(taskData, widget.board);
                          }
                        },
                        child: Text(task == null ? 'Crear' : 'Actualizar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Mostrar los detalles de una tarea
  void _showTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task['title']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task['description'] ?? ''),
              const SizedBox(height: 16),
              const Text('Fecha de inicio:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${task['startDate']} ${task['startTime']}'),
              const SizedBox(height: 8),
              const Text('Fecha de finalización:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${task['endDate']} ${task['endTime']}'),
              if ((task['attachedFiles'] as List?)?.isNotEmpty ?? false) ...[  
                const SizedBox(height: 16),
                const Text('Archivos adjuntos:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(
                  (task['attachedFiles'] as List).length,
                  (index) => InkWell(
                    onTap: () async {
                      final String fileName = (task['attachedFiles'] as List)[index];
                      try {
                        final Uri fileUri = Uri.file(fileName);
                        if (await canLaunchUrl(fileUri)) {
                          await launchUrl(fileUri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No se puede abrir el archivo: $fileName')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al abrir el archivo: $e')),
                          );
                        }
                      }
                    },
                    child: Chip(
                      label: Text(
                        (task['attachedFiles'] as List)[index],
                        style: const TextStyle(color: Colors.black),
                      ),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        if (isCompleted) {
                          // Mover de completadas a pendientes
                          _completedTasks.remove(task);
                          _pendingTasks.add(task);
                        } else {
                          // Mover de pendientes a completadas
                          _pendingTasks.remove(task);
                          _completedTasks.add(task);
                        }
                        _saveTasks();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task['description'] ?? ''),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inicio: ${task['startDate']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Fin: ${task['endDate']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showTaskFormDialog(task: task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar tarea'),
                              content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      if (isCompleted) {
                                        _completedTasks.remove(task);
                                      } else {
                                        _pendingTasks.remove(task);
                                      }
                                      _saveTasks();
                                    });
                                  },
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if ((task['attachedFiles'] as List?)?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${(task['attachedFiles'] as List).length} archivos',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.board['title']),
        backgroundColor: Color(widget.board['color']),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditBoardDialog,
            tooltip: 'Editar tablero',
          ),
          IconButton(
            icon: Icon(
              widget.board['isFavorite'] ? Icons.star : Icons.star_border,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'Marcar como favorito',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Eliminar tablero',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Completadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de tareas pendientes
          _pendingTasks.isEmpty
              ? const Center(child: Text('No hay tareas pendientes'))
              : ListView.builder(
                  itemCount: _pendingTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(_pendingTasks[index], false);
                  },
                ),
          // Pestaña de tareas completadas
          _completedTasks.isEmpty
              ? const Center(child: Text('No hay tareas completadas'))
              : ListView.builder(
                  itemCount: _completedTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(_completedTasks[index], true);
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}