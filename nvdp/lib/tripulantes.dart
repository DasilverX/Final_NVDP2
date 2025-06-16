import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // ***** AÑADIDO *****
import 'auth_service.dart'; // ***** AÑADIDO *****
import 'add_tripulante.dart'; // ***** AÑADIDO (asegúrate que el nombre del archivo sea correcto) *****
import 'edit_tripulante.dart';
import 'config.dart';
class TripulantesScreen extends StatefulWidget {
  const TripulantesScreen({super.key});

  @override
  State<TripulantesScreen> createState() => _TripulantesScreenState();
}

class _TripulantesScreenState extends State<TripulantesScreen> {
  List _tripulantes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTripulantes();
  }

  Future<void> _fetchTripulantes() async {
    const url = '$apiBaseUrl/api/tripulantes';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _tripulantes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar los tripulantes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  Future<void> _deleteTripulante(int id) async {
    final url = '$apiBaseUrl/api/tripulantes/$id';
    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tripulante eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refrescar la lista después de eliminar
        _fetchTripulantes();
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception('Error al eliminar: ${responseBody['message']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _showDeleteConfirmationDialog(int id, String nombre) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar a $nombre?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTripulante(id);
              },
            ),
          ],
        );
      },
    );
  }

  // ***** MÉTODO BUILD COMPLETAMENTE ACTUALIZADO *****
  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el rol del usuario desde el AuthService
    final authService = Provider.of<AuthService>(context);
    final esAdmin = authService.userRole == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Tripulantes'),
        // 2. El botón de añadir solo aparece si el usuario es administrador
        actions: [
          if (esAdmin)
            IconButton(
              icon: const Icon(Icons.add_box),
              tooltip: 'Añadir Tripulante',
              onPressed: () async {
                // Suponiendo que tu clase se llama AddTripulanteScreen
                // y el archivo es add_tripulante.dart
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddTripulanteScreen(),
                  ),
                );
                if (result == true) {
                  _fetchTripulantes();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tripulantes
                .isEmpty // ***** NUEVA CONDICIÓN AQUÍ *****
          ? Center(
              // Usamos Center para que se vea bien en cualquier pantalla
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png', // Usamos el logo que ya tienes
                    height: 100,
                    color: Colors.grey[400], // Un color sutil
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No hay tripulantes registrados',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  if (esAdmin) // Mostramos este texto solo si es admin
                    const Text(
                      'Usa el botón (+) para añadir el primero.',
                      style: TextStyle(color: Colors.black45),
                    ),
                ],
              ),
            )
          : RefreshIndicator(
              // La lista solo se muestra si no está vacía
              onRefresh: _fetchTripulantes,
              child: ListView.builder(
                itemCount: _tripulantes.length,
                itemBuilder: (context, index) {
                  final tripulante = _tripulantes[index];
                  final tripulanteId = tripulante['TRIPULACIONID'];
                  final nombre = tripulante['NOMBRE'] ?? 'N/A';
                  final rol = tripulante['ROL'] ?? 'N/A';
                  final nombreBarco = tripulante['NOMBREBARCO'] ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    child: InkWell(
                      // Hacemos que toda la tarjeta sea "clicable" para editar
                      onTap: esAdmin
                          ? () async {
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (context) => EditTripulanteScreen(
                                        tripulante: tripulante,
                                      ),
                                    ),
                                  );
                              if (result == true) {
                                _fetchTripulantes();
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ), // Para que el efecto de clic tenga bordes redondeados
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila para el nombre del tripulante
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            // Fila para el rol
                            Row(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rol,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Fila para el nombre del barco
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_boat_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Barco: $nombreBarco",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            // Mostramos el botón de eliminar solo si es administrador
                            if (esAdmin)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[700],
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        tripulanteId,
                                        nombre,
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}