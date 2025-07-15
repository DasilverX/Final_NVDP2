// lib/barco_detalle.dart

import 'package:flutter/material.dart';
import 'package:nvdp/api_service.dart';
class BarcoDetalleScreen extends StatefulWidget {
  // Esta variable recibirá el ID desde la pantalla anterior (gestion_barcos)
  final int barcoId;

  const BarcoDetalleScreen({super.key, required this.barcoId});

  @override
  _BarcoDetalleScreenState createState() => _BarcoDetalleScreenState();
}

class _BarcoDetalleScreenState extends State<BarcoDetalleScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _barcoFuture;

  @override
  void initState() {
    super.initState();
    // Usamos el widget.barcoId para llamar al API y cargar los datos
    _barcoFuture = _apiService.getBarcoById(widget.barcoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Barco'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _barcoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Si tenemos datos, los extraemos del mapa
            final barco = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Mostramos cada detalle del barco
                  ListTile(
                    title: Text('Nombre del Barco'),
                    subtitle: Text(barco['NOMBRE_BARCO'] ?? 'No disponible'),
                  ),
                  ListTile(
                    title: Text('Número IMO'),
                    subtitle: Text(barco['NUMERO_IMO'] ?? 'No disponible'),
                  ),
                  ListTile(
                    title: Text('ID del Cliente'),
                    subtitle: Text(barco['ID_CLIENTE']?.toString() ?? 'No asignado'),
                  ),
                  // Puedes añadir más campos aquí...
                  SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {
                        // Aquí podrías navegar a ver las escalas de este barco
                        // Navigator.push(...);
                      },
                      child: Text('Ver Escalas Portuarias'),
                  )
                ],
              ),
            );
          } else {
            return Center(child: Text('No se encontró información del barco.'));
          }
        },
      ),
    );
  }
}