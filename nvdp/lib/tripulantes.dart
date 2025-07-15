// lib/tripulantes.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'add_tripulante.dart';
import 'edit_tripulante.dart';

class TripulantesScreen extends StatefulWidget {
  const TripulantesScreen({super.key});

  @override
  State<TripulantesScreen> createState() => _TripulantesScreenState();
}

class _TripulantesScreenState extends State<TripulantesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _tripulantesFuture;

  @override
  void initState() {
    super.initState();
    _tripulantesFuture = _apiService.getTripulantes();
  }

  void _refreshData() {
    setState(() {
      _tripulantesFuture = _apiService.getTripulantes();
    });
  }

  void _deleteTripulante(int id, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar a $nombre?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _apiService.deleteTripulante(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Tripulante eliminado'), backgroundColor: Colors.green));
                _refreshData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToForm({Map<String, dynamic>? tripulante}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          // Decidimos a qué pantalla ir basado en si estamos editando o añadiendo
          if (tripulante != null) {
            return EditTripulanteScreen(tripulante: tripulante);
          } else {
            return const AddTripulanteScreen();
          }
        },
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).userRole == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Tripulantes'),
        actions: [
          if (esAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Añadir Tripulante',
              onPressed: () => _navigateToForm(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<dynamic>>(
          future: _tripulantesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Tu excelente UI para cuando no hay datos
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    const Text('No hay tripulantes registrados', style: TextStyle(fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (esAdmin)
                      const Text('Usa el botón (+) para añadir el primero.', style: TextStyle(color: Colors.black45)),
                  ],
                ),
              );
            }

            final tripulantes = snapshot.data!;
            return ListView.builder(
              itemCount: tripulantes.length,
              itemBuilder: (context, index) {
                final tripulante = tripulantes[index];
                // CORRECCIÓN: Usar las claves correctas del API
                final nombre = tripulante['NOMBRE_COMPLETO'] ?? 'N/A';
                final rol = tripulante['ROL_ABORDO'] ?? 'N/A';
                final nombreBarco = tripulante['NOMBRE_BARCO'] ?? 'No asignado';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: InkWell(
                    onTap: esAdmin ? () => _navigateToForm(tripulante: tripulante) : null,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(rol, style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text("Barco: $nombreBarco", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          if (esAdmin)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                              onPressed: () => _deleteTripulante(tripulante['ID_TRIPULACION'], nombre),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}