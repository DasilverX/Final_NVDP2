import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'login.dart';
import 'config.dart';

class CapitanDashboardScreen extends StatefulWidget {
  // 1. Añadimos las variables que la pantalla recibirá
  final int barcoId;
  final String nombreCapitan;

  // 2. Modificamos el constructor para que sea obligatorio recibir estos datos
  const CapitanDashboardScreen({
    super.key,
    required this.barcoId,
    required this.nombreCapitan,
  });

  @override
  State<CapitanDashboardScreen> createState() => _CapitanDashboardScreenState();
}

class _CapitanDashboardScreenState extends State<CapitanDashboardScreen> {
  List _peticiones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPeticiones();
  }

  Future<void> _fetchPeticiones() async {
    // Usamos el widget.barcoId que recibimos para construir la URL
    final url = '$apiBaseUrl/api/peticiones/barco/${widget.barcoId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _peticiones = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Fallo al cargar las peticiones');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Usamos el widget.nombreCapitan que recibimos para el título
        title: Text('Dashboard Capitán ${widget.nombreCapitan}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPeticiones,
              child: _peticiones.isEmpty
                  ? const Center(child: Text('No hay peticiones de servicio registradas.'))
                  : ListView.builder(
                      itemCount: _peticiones.length,
                      itemBuilder: (context, index) {
                        final peticion = _peticiones[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          child: ListTile(
                            leading: Icon(_getStatusIcon(peticion['ESTADO'])),
                            title: Text(peticion['SERVICIOTIPO'] ?? 'Servicio no especificado'),
                            subtitle: Text('Puerto: ${peticion['NOMBREPUERTO']} - Estado: ${peticion['ESTADO']}'),
                            trailing: Text(peticion['FECHAPETICION'].toString().substring(0, 10)),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidad de añadir petición pendiente.')),
          );
        },
        tooltip: 'Nueva Petición de Servicio',
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getStatusIcon(String? estado) {
    switch (estado) {
      case 'Pendiente':
        return Icons.hourglass_top;
      case 'Aprobado':
        return Icons.check_circle_outline;
      case 'Completado':
        return Icons.check_circle;
      case 'Rechazado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}