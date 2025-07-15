// lib/add_documento_screen.dart

import 'package:flutter/material.dart';
import 'api_service.dart';

class AddDocumentoScreen extends StatefulWidget {
  const AddDocumentoScreen({super.key});
  @override
  State<AddDocumentoScreen> createState() => _AddDocumentoScreenState();
}

class _AddDocumentoScreenState extends State<AddDocumentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _pagoIdController = TextEditingController(); // Nuevo
  final _tipoDocController = TextEditingController();
  final _nombreArchivoController = TextEditingController();
  
  bool _isLoading = false;

  void _guardarDocumento() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final docData = {
        'id_pago': int.tryParse(_pagoIdController.text), // Nuevo
        'id_tipo_documento': int.tryParse(_tipoDocController.text),
        'nombre_archivo': _nombreArchivoController.text,
        // 'id_escala' es ahora opcional, lo enviamos como nulo
        'id_escala': null, 
      };

      try {
        final bool exito = await _apiService.addDocumento(docData);
        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento registrado con éxito'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Fallo al registrar el documento');
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pagoIdController.dispose();
    _tipoDocController.dispose();
    _nombreArchivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Documento de Pago')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CAMPO MODIFICADO ---
              TextFormField(
                controller: _pagoIdController,
                decoration: const InputDecoration(labelText: 'ID del Pago a Asociar'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoDocController,
                decoration: const InputDecoration(labelText: 'ID del Tipo de Documento'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _nombreArchivoController,
                decoration: const InputDecoration(labelText: 'Nombre del Documento (ej: comprobante.pdf)'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarDocumento,
                    child: const Text('Guardar Documento'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}