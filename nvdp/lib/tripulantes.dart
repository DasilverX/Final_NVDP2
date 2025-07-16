import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'add_edit_tripulante.dart';

class TripulantesScreen extends StatefulWidget {
  const TripulantesScreen({super.key});
  @override
  State<TripulantesScreen> createState() => _TripulantesScreenState();
}

class _TripulantesScreenState extends State<TripulantesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _tripulantesFuture;

  @override
  void initState() { super.initState(); _refreshData(); }
  void _refreshData() { setState(() { _tripulantesFuture = _apiService.getTripulantes(); }); }

  void _navigateToForm({Map<String, dynamic>? tripulante}) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => AddEditTripulanteScreen(tripulante: tripulante)));
    if (result == true) _refreshData();
  }



void _deleteTripulante(int id, String nombre) {
  // Diálogo de confirmación para evitar borrados accidentales
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Eliminación'),
      content: Text('¿Estás seguro de que deseas eliminar a "$nombre"?'),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        TextButton(
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          onPressed: () async {
            Navigator.of(ctx).pop(); // Cierra el diálogo
            try {
              // Llama a la función del ApiService para eliminar
              await _apiService.deleteTripulante(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tripulante eliminado con éxito'), backgroundColor: Colors.green)
                );
              }
              _refreshData(); // Refresca la lista para que el cambio se vea
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: ${e.toString()}'), backgroundColor: Colors.red)
                );
              }
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
      appBar: AppBar(title: const Text('Gestión de Tripulantes')),
      body: FutureBuilder<List<dynamic>>(
        future: _tripulantesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final tripulantes = snapshot.data ?? [];
          if (tripulantes.isEmpty) return const Center(child: Text('No hay tripulantes registrados.'));

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              itemCount: tripulantes.length,
              itemBuilder: (context, index) {
                final tripulante = tripulantes[index];
                final nombre = tripulante['NOMBRE_COMPLETO'] ?? 'N/A';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(nombre),
                    subtitle: Text('Rol: ${tripulante['ROL_ABORDO'] ?? 'N/A'}\nBarco: ${tripulante['NOMBRE_BARCO'] ?? 'No asignado'}'),
                    isThreeLine: true,
                    trailing: esAdmin ? IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[700]), onPressed: () => _deleteTripulante(tripulante['ID_TRIPULACION'], nombre)) : null,
                    onTap: esAdmin ? () => _navigateToForm(tripulante: tripulante) : null,
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