// lib/add_factura_screen.dart

import 'package:flutter/material.dart';
import 'api_service.dart';

class AddFacturaScreen extends StatefulWidget {
  const AddFacturaScreen({super.key});
  @override
  State<AddFacturaScreen> createState() => _AddFacturaScreenState();
}

class _AddFacturaScreenState extends State<AddFacturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controladores para la factura
  final _escalaIdController = TextEditingController();
  final _clienteIdController = TextEditingController();
  final _numeroFacturaController = TextEditingController();
  
  // Controladores para la primera línea de detalle
  final _detalleDescController = TextEditingController();
  final _detallePrecioController = TextEditingController();
  final _detalleCantidadController = TextEditingController();
  
  bool _isLoading = false;

  void _guardarFactura() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final facturaData = {
        'id_escala': int.tryParse(_escalaIdController.text),
        'id_cliente': int.tryParse(_clienteIdController.text),
        'numero_factura': _numeroFacturaController.text,
        'id_moneda': 1, // Usamos ID 1 (USD) como ejemplo
        'detalle': {
          'descripcion': _detalleDescController.text,
          'precio_unitario': double.tryParse(_detallePrecioController.text),
          'cantidad': int.tryParse(_detalleCantidadController.text)
        }
      };

      try {
        final bool exito = await _apiService.addFactura(facturaData);
        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factura creada con éxito'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          throw Exception('Fallo al crear la factura');
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nueva Factura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Datos de la Factura', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(controller: _escalaIdController, decoration: const InputDecoration(labelText: 'ID de la Escala'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _clienteIdController, decoration: const InputDecoration(labelText: 'ID del Cliente'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _numeroFacturaController, decoration: const InputDecoration(labelText: 'Número de Factura'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const Divider(height: 32),
              Text('Primera Línea de Detalle', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(controller: _detalleDescController, decoration: const InputDecoration(labelText: 'Descripción del Servicio'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _detallePrecioController, decoration: const InputDecoration(labelText: 'Precio Unitario'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _detalleCantidadController, decoration: const InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 32),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _guardarFactura, child: const Text('Crear Factura')),
            ],
          ),
        ),
      ),
    );
  }
}