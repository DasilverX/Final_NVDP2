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

  void _refreshUsuarios() {
    setState(() {
      _usuariosFuture = _apiService.getUsuarios();
    });
  }

  void _deleteUsuario(int id, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar al usuario $nombre?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _apiService.deleteUsuario(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuario eliminado'), backgroundColor: Colors.green)
                );
                _refreshUsuarios();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red)
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Función para navegar al formulario y refrescar la lista si hay cambios
  void _navigateToForm({Map<String, dynamic>? usuario}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddUsuarioScreen(usuario: usuario),
      ),
    );
    // Si volvemos del formulario y el resultado es 'true', refrescamos
    if (result == true) {
      _refreshUsuarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).userRole == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshUsuarios(),
        child: FutureBuilder<List<dynamic>>(
          future: _usuariosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay usuarios registrados.'));
            }

            final usuarios = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.account_circle_outlined)),
                    title: Text(usuario['NOMBRE_USUARIO'] ?? 'Sin Nombre'),
                    subtitle: Text('Rol ID: ${usuario['ID_ROL'] ?? 'N/A'}'),
                    trailing: esAdmin
                        ? IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                            onPressed: () => _deleteUsuario(usuario['ID_USUARIO'], usuario['NOMBRE_USUARIO']),
                          )
                        : null,
                    // MODIFICACIÓN: Acción de Editar
                    onTap: esAdmin ? () => _navigateToForm(usuario: usuario) : null,
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: esAdmin
          ? FloatingActionButton(
              // MODIFICACIÓN: Acción de Añadir
              onPressed: () => _navigateToForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}