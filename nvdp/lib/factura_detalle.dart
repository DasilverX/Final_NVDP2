// lib/factura_detalle_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';

class FacturaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> factura;
  const FacturaDetalleScreen({super.key, required this.factura});

  @override
  State<FacturaDetalleScreen> createState() => _FacturaDetalleScreenState();
}

class _FacturaDetalleScreenState extends State<FacturaDetalleScreen> {
  late Map<String, dynamic> _facturaActual;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _facturaActual = widget.factura;
  }

  void _cambiarEstado(String nuevoStatus) async {
    // Mostramos un indicador de carga mientras se procesa
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final exito = await _apiService.updateFacturaStatus(_facturaActual['ID_FACTURA'], nuevoStatus);
      Navigator.of(context).pop(); // Cierra el indicador de carga

      if (mounted && exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a $nuevoStatus'), backgroundColor: Colors.green),
        );
        setState(() {
          _facturaActual['ESTADO_FACTURA'] = nuevoStatus;
        });
      } else if(mounted) {
        throw Exception('Fallo al actualizar el estado');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga también si hay error
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).userRole == 'administrador';
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: Text('Detalle Factura ${_facturaActual["NUMERO_FACTURA"]}')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cliente: ${_facturaActual["NOMBRE_CLIENTE"]}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Monto Total: ${currencyFormatter.format(_facturaActual["MONTO_TOTAL"])}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Estado: ', style: Theme.of(context).textTheme.titleMedium),
                        Chip(
                          label: Text(_facturaActual["ESTADO_FACTURA"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.blueGrey, // Color por defecto
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Líneas de Servicio', style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _apiService.getDetallesFactura(_facturaActual['ID_FACTURA']),
              builder: (context, snapshot) {
                // --- LÓGICA COMPLETA DEL FUTUREBUILDER ---
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final detalles = snapshot.data ?? [];
                if (detalles.isEmpty) {
                  return const Center(child: Text('Esta factura no tiene detalles.'));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final detalle = detalles[index];
                    return ListTile(
                      title: Text(detalle['DESCRIPCION']),
                      trailing: Text(currencyFormatter.format(detalle['SUBTOTAL'])),
                    );
                  },
                );
              },
            ),
          ),
          if (esAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como Pagado'),
                    onPressed: () => _cambiarEstado('Pagado'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100]),
                  ),
                   ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar Factura'),
                    onPressed: () => _cambiarEstado('Cancelado'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}