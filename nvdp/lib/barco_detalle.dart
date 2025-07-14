import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class BarcoDetalleScreen extends StatefulWidget {
  final int barcoId;

  const BarcoDetalleScreen({super.key, required this.barcoId});

  @override
  State<BarcoDetalleScreen> createState() => _BarcoDetalleScreenState();
}

class _BarcoDetalleScreenState extends State<BarcoDetalleScreen> {
  Map<String, dynamic>? _detalles;
  List _tripulacion = [];
  List _historialEscalas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBarcoDetalles();
  }

  Future<void> _fetchBarcoDetalles() async {
    final url = '$apiBaseUrl/api/barcos/${widget.barcoId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detalles = data['detalles'];
          _tripulacion = data['tripulacion'];
          _historialEscalas = data['historial_escalas'];
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar los detalles del barco');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Cargando...' : _detalles?['NOMBRE'] ?? 'Detalle del Barco'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _detalles == null
                  ? const Center(child: Text('No se encontraron detalles para este barco.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetallesCard(),
                          const SizedBox(height: 20),
                          _buildTripulacionCard(),
                          const SizedBox(height: 20),
                          _buildHistorialEscalasCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetallesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Información General', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('IMO: ${_detalles!['NUMEROIMO']}'),
            Text('Tipo: ${_detalles!['TIPO']}'),
            Text('Bandera: ${_detalles!['BANDERA']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTripulacionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tripulación a Bordo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (_tripulacion.isEmpty)
              const Text('No hay tripulantes registrados para este barco.')
            else
              Column(
                children: _tripulacion.map((tripulante) {
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(tripulante['NOMBRE']),
                    subtitle: Text(tripulante['ROL']),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialEscalasCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de Escalas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (_historialEscalas.isEmpty)
              const Text('No hay escalas registradas para este barco.')
            else
              Column(
                children: _historialEscalas.map((escala) {
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(escala['NOMBREPUERTO']),
                    subtitle: Text('Llegada: ${escala['FECHAHORALLEGADA']}'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}