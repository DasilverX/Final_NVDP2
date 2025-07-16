// lib/capitan_facturas_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class CapitanFacturasScreen extends StatefulWidget {
  final int barcoId;
  const CapitanFacturasScreen({super.key, required this.barcoId});

  @override
  State<CapitanFacturasScreen> createState() => _CapitanFacturasScreenState();
}

class _CapitanFacturasScreenState extends State<CapitanFacturasScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _facturasFuture;

  @override
  void initState() {
    super.initState();
    _facturasFuture = _apiService.getFacturasPorBarco(widget.barcoId);
  }

  void _refreshData() {
    setState(() {
      _facturasFuture = _apiService.getFacturasPorBarco(widget.barcoId);
    });
  }

  void _pagarFactura(int facturaId, double monto) async {
    try {
      final success = await _apiService.realizarPago(facturaId, monto);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pago simulado con éxito'),
            backgroundColor: Colors.green));
        _refreshData();
      } else if (mounted) {
        throw Exception('Fallo al procesar el pago');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facturas del Barco')),
      body: FutureBuilder<List<dynamic>>(
        future: _facturasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final facturas = snapshot.data ?? [];
          if (facturas.isEmpty) {
            return const Center(child: Text('No hay facturas para este barco.'));
          }
          return ListView.builder(
            itemCount: facturas.length,
            itemBuilder: (context, index) {
              final factura = facturas[index];
              final bool esPendiente = factura['ESTADO_FACTURA'] == 'Pendiente';
              return Card(
                color: esPendiente ? Colors.orange[50] : Colors.white,
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(factura['NUMERO_FACTURA']),
                  subtitle: Text(
                      'Monto: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(factura['MONTO_TOTAL'])}'),
                  trailing: esPendiente
                      ? ElevatedButton(
                          onPressed: () => _pagarFactura(
                              factura['ID_FACTURA'],
                              factura['MONTO_TOTAL'].toDouble()),
                          child: const Text('Pagar'),
                        )
                      : Chip(
                          label: Text(factura['ESTADO_FACTURA']),
                          backgroundColor: Colors.green[100],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}