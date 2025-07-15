// lib/contabilidad_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necesitarás añadir este paquete: flutter pub add intl
import 'api_service.dart';
import 'factura_detalle.dart'; // La crearemos a continuación

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contabilidad - Facturas')),
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

          return ListView.builder(
            itemCount: facturas.length,
            itemBuilder: (context, index) {
              final factura = facturas[index];
              // Formateador para la moneda
              final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
              // Formateador para la fecha
              final date = DateTime.parse(factura['FECHA_EMISION']);
              final dateFormatter = DateFormat('dd/MM/yyyy');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                  title: Text(factura['NUMERO_FACTURA']),
                  subtitle: Text('Cliente: ${factura['NOMBRE_CLIENTE']}\nFecha: ${dateFormatter.format(date)}'),
                  trailing: Text(
                    currencyFormatter.format(factura['MONTO_TOTAL']),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => FacturaDetalleScreen(factura: factura),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}