// lib/reporte_clientes_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class ReporteClientesScreen extends StatefulWidget {
  const ReporteClientesScreen({super.key});

  @override
  State<ReporteClientesScreen> createState() => _ReporteClientesScreenState();
}

class _ReporteClientesScreenState extends State<ReporteClientesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _reporteFuture;

  @override
  void initState() {
    super.initState();
    _reporteFuture = _apiService.getReportePagosPorCliente();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte por Cliente')),
      body: FutureBuilder<List<dynamic>>(
        future: _reporteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reporteData = snapshot.data ?? [];
          if (reporteData.isEmpty) {
            return const Center(child: Text('No hay datos para el reporte.'));
          }
          
          return ListView.builder(
            itemCount: reporteData.length,
            itemBuilder: (context, index) {
              final clienteData = reporteData[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clienteData['NOMBRE_CLIENTE'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      _buildReportRow('Total Facturado:', currencyFormatter.format(clienteData['MONTO_FACTURADO'] ?? 0)),
                      _buildReportRow('Total Pagado:', currencyFormatter.format(clienteData['TOTAL_PAGADO'] ?? 0)),
                      _buildReportRow('N° de Facturas:', (clienteData['TOTAL_FACTURAS'] ?? 0).toString()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}