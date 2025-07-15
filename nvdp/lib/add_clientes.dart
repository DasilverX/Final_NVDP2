// lib/add_cliente_screen.dart

import 'package:flutter/material.dart';
import 'api_service.dart';

class AddClienteScreen extends StatefulWidget {
  final Map<String, dynamic>? cliente;
  const AddClienteScreen({super.key, this.cliente});

  @override
  State<AddClienteScreen> createState() => _AddClienteScreenState();
}

class _AddClienteScreenState extends State<AddClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contactoController = TextEditingController();

  bool get _isEditing => widget.cliente != null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nombreController.text = widget.cliente!['NOMBRE_CLIENTE'] ?? '';
      _rucController.text = widget.cliente!['RUC_CLIENTE'] ?? '';
      _direccionController.text = widget.cliente!['DIRECCION'] ?? '';
      _contactoController.text = widget.cliente!['CONTACTO_PRINCIPAL'] ?? '';
    }
  }

  void _guardarCliente() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final data = {
        'nombre_cliente': _nombreController.text,
        'ruc_cliente': _rucController.text,
        'direccion': _direccionController.text,
        'contacto_principal': _contactoController.text,
      };

      try {
        bool exito = false;
        if (_isEditing) {
          exito = await _apiService.updateCliente(widget.cliente!['ID_CLIENTE'], data);
        } else {
          exito = await _apiService.addCliente(data);
        }
        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente guardado'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else if (mounted) {
          throw Exception('Fallo al guardar');
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rucController.dispose();
    _direccionController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Cliente' : 'Añadir Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre del Cliente'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _rucController, decoration: const InputDecoration(labelText: 'RUC del Cliente'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _direccionController, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 16),
              TextFormField(controller: _contactoController, decoration: const InputDecoration(labelText: 'Contacto Principal')),
              const SizedBox(height: 32),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _guardarCliente, child: const Text('Guardar Cliente')),
            ],
          ),
        ),
      ),
    );
  }
}