import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'add_usuario.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});
  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _usuariosFuture;

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _apiService.getUsuarios();
  }

  void _refreshData() {
    setState(() { _usuariosFuture = _apiService.getUsuarios(); });
  }

  void _navigateToForm({Map<String, dynamic>? usuario}) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => AddUsuarioScreen(usuario: usuario)));
    if (result == true) _refreshData();
  }

  void _deleteUsuario(int id, String nombre) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Seguro que quieres eliminar al usuario "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _apiService.deleteUsuario(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado'), backgroundColor: Colors.green));
                _refreshData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).esAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: FutureBuilder<List<dynamic>>(
        future: _usuariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final usuarios = snapshot.data ?? [];
          if (usuarios.isEmpty) return const Center(child: Text('No hay usuarios registrados.'));

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.account_circle_outlined)),
                    title: Text(usuario['NOMBRE_USUARIO'] ?? 'Sin Nombre'),
                    subtitle: Text('Rol ID: ${usuario['ID_ROL'] ?? 'N/A'}'),
                    trailing: esAdmin ? IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[700]), onPressed: () => _deleteUsuario(usuario['ID_USUARIO'], usuario['NOMBRE_USUARIO'])) : null,
                    onTap: esAdmin ? () => _navigateToForm(usuario: usuario) : null,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: esAdmin ? FloatingActionButton(onPressed: () => _navigateToForm(), child: const Icon(Icons.add)) : null,
    );
  }
}