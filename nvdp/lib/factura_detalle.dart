// lib/factura_detalle_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class FacturaDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> factura;
  const FacturaDetalleScreen({super.key, required this.factura});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: Text('Detalle Factura ${factura["NUMERO_FACTURA"]}')),
      body: Column(
        children: [
          // Cabecera con la información principal
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${factura["NOMBRE_CLIENTE"]}', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Text('Monto Total: ${currencyFormatter.format(factura["MONTO_TOTAL"])}', style: Theme.of(context).textTheme.titleMedium),
                Text('Estado: ${factura["ESTADO_FACTURA"]}', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          Divider(),
          // Título para la lista de detalles
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Detalles de la Factura', style: Theme.of(context).textTheme.titleMedium),
          ),
          // Lista de detalles
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: apiService.getDetallesFactura(factura['ID_FACTURA']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final detalles = snapshot.data ?? [];
                return ListView.builder(
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
        ],
      ),
    );
  }
}