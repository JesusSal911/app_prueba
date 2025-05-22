import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Erlan Reyes');
  final TextEditingController _emailController = TextEditingController(text: 'eryes1025@gmail.com');
  final TextEditingController _passwordController = TextEditingController();
  String? _profileImagePath;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _showEditProfileModal(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar cuenta'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImagePath != null
                          ? Image.asset(_profileImagePath!).image
                          : const AssetImage('assets/logo.png'),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, size: 18, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                    validator: (value) => value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                    validator: (value) => value != null && value.isNotEmpty && value.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    // Aquí deberías usar image_picker o similar para seleccionar imagen
    // Por simplicidad, simulamos la selección
    setState(() {
      _profileImagePath = 'assets/logo.png'; // Reemplazar por la ruta real seleccionada
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    await Future.delayed(const Duration(seconds: 1)); // Simula guardado
    setState(() { _isLoading = false; });
    Navigator.pop(context);
    setState(() {}); // Refresca la UI
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImagePath != null
                    ? Image.asset(_profileImagePath!).image
                    : const AssetImage('assets/logo.png'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _nameController.text,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar cuenta'),
            onTap: () => _showEditProfileModal(context),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ayuda'),
            onTap: () => _showAlert(context, '¿Como no vas a saber usar una app tan simple?'),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Soporte'),
            onTap: () async {
              const phoneNumber = 'tel:+51910801491';
              if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                await launchUrl(Uri.parse(phoneNumber));
              } else {
                _showAlert(context, 'No se pudo abrir la aplicación de teléfono.');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Salir de la app'),
            onTap: () => SystemNavigator.pop(),
          ),
        ],
      ),
    );
  }
}