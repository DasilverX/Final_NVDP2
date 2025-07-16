// lib/contabilidad_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener este import
import 'api_service.dart';
import 'factura_detalle.dart'; 
import 'add_factura.dart';

class ContabilidadScreen extends StatefulWidget {
  const ContabilidadScreen({super.key});

  @override
  State<ContabilidadScreen> createState() => _ContabilidadScreenState();
}

class _ContabilidadScreenState extends State<ContabilidadScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _facturasFuture;

  @override
  void initState() {
    super.initState();
    _facturasFuture = _apiService.getFacturas();
  }

  void _refreshData() {
    setState(() {
      _facturasFuture = _apiService.getFacturas();
    });
  }

  void _exportarFacturas() {
    final url = Uri.parse('${_apiService.getBaseUrl()}/api/export/facturas');
    launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contabilidad - Facturas'),
        // --- BOTÓN DE EXPORTAR AÑADIDO ---
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Exportar a CSV',
            onPressed: _exportarFacturas,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _facturasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final facturas = snapshot.data ?? [];
          if (facturas.isEmpty) {
            return const Center(child: Text('No hay facturas para mostrar.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
              itemCount: facturas.length,
              itemBuilder: (context, index) {
                final factura = facturas[index];
                final currencyFormatter =
                    NumberFormat.currency(locale: 'en_US', symbol: '\$');
                final date = DateTime.parse(factura['FECHA_EMISION']);
                final dateFormatter = DateFormat('dd/MM/yyyy');

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long_outlined)),
                    title: Text(factura['NUMERO_FACTURA']),
                    subtitle: Text(
                        'Cliente: ${factura['NOMBRE_CLIENTE']}\nFecha: ${dateFormatter.format(date)}'),
                    trailing: Text(
                      currencyFormatter.format(factura['MONTO_TOTAL']),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FacturaDetalleScreen(factura: factura),
                        ),
                      );
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (context) => const AddFacturaScreen()),
          );
          if (result == true) {
            _refreshData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}