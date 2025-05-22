import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'board_detail_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import '../services/notification_manager.dart';
import '../utils/lifecycle_event_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _boardNameController = TextEditingController();
  List<Map<String, dynamic>> _boards = [];
  int _unreadNotifications = 0;

  final List<Widget> _screens = [
    const HomeScreenContent(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _boardNameController.dispose();
    WidgetsBinding.instance.removeObserver(LifecycleEventHandler());
    super.dispose();
  }

  Future<void> _loadBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? boardsJson = prefs.getString('boards');
    if (boardsJson != null) {
      setState(() {
        _boards = List<Map<String, dynamic>>.from(
          jsonDecode(boardsJson).map((x) => Map<String, dynamic>.from(x)));
      });
    }
  }

  Future<void> _saveBoards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('boards', jsonEncode(_boards));
  }

  Future<void> _checkUnreadNotifications() async {
    final unreadCount = await NotificationManager.getUnreadCount();
    setState(() {
      _unreadNotifications = unreadCount;
    });
  }

  void _showCreateBoardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear nuevo tablero'),
        content: TextField(
          controller: _boardNameController,
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
            onPressed: () {
              if (_boardNameController.text.isNotEmpty) {
                setState(() {
                  _boards.add({
                    'title': _boardNameController.text,
                    'color': Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.8).value,
                    'isFavorite': false,
                  });
                });
                _saveBoards();
                _boardNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
            label: 'Notificación',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfile',
          ),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _boardNameController = TextEditingController();
  List<Map<String, dynamic>> _boards = [];

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _boardNameController.dispose();
    WidgetsBinding.instance.removeObserver(LifecycleEventHandler());
    super.dispose();
  }

  Future<void> _loadBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? boardsJson = prefs.getString('boards');
    if (boardsJson != null) {
      setState(() {
        _boards = List<Map<String, dynamic>>.from(
          jsonDecode(boardsJson).map((x) => Map<String, dynamic>.from(x)));
      });
    }
  }

  Future<void> _saveBoards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('boards', jsonEncode(_boards));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacio de trabajo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TaskBoardSearchDelegate(
                  _boards,
                  onBoardTap: (board) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoardDetailScreen(board: board),
                      ),
                    ).then((_) {
                      // Recargar los tableros cuando regresamos de la pantalla de detalles
                      _loadBoards();
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Tareas destacadas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTaskBoardList(true),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Tus tareas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTaskBoardList(false),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Crear nuevo tablero'),
              content: TextField(
                controller: _boardNameController,
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
                  onPressed: () {
                    if (_boardNameController.text.isNotEmpty) {
                      setState(() {
                        _boards.add({
                          'title': _boardNameController.text,
                          'color': Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.8).value,
                          'isFavorite': false,
                        });
                      });
                      _saveBoards();
                      _boardNameController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

    );
  }

  // Lista de tableros eliminada ya que ahora se carga dinámicamente
  // final List<Map<String, dynamic>> _boards = [
    // Tableros de ejemplo eliminados
  //];

  void _toggleFavorite(int index) {
    setState(() {
      _boards[index]['isFavorite'] = !_boards[index]['isFavorite'];
    });
    _saveBoards();
  }

  Widget _buildTaskBoardList(bool isFeatured) {
    final filteredBoards = _boards.where((board) => board['isFavorite'] == isFeatured).toList();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredBoards.length,
      itemBuilder: (context, index) {
        final board = filteredBoards[index];
        final originalIndex = _boards.indexWhere((b) => b['title'] == board['title']);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Color(board['color']),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navegar a la vista de detalles del tablero
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoardDetailScreen(board: board),
                        ),
                      ).then((_) {
                        // Recargar los tableros cuando regresamos de la pantalla de detalles
                        _loadBoards();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            board['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              board['isFavorite'] ? Icons.star : Icons.star_border,
                              color: Colors.white,
                            ),
                            onPressed: () => _toggleFavorite(originalIndex),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskBoardSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> _boards;
  final void Function(Map<String, dynamic> board) onBoardTap;

  _TaskBoardSearchDelegate(this._boards, {required this.onBoardTap});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> board) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Color(board['color']),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    onBoardTap(board);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        board['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        board['isFavorite'] ? Icons.star : Icons.star_border,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterBoards(String query) {
    return _boards
        .where((board) =>
            board['title'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredBoards = _filterBoards(query);
    return ListView.builder(
      itemCount: filteredBoards.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(filteredBoards[index]);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredBoards = _filterBoards(query);
    return ListView.builder(
      itemCount: filteredBoards.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(filteredBoards[index]);
      },
    );
  }
}