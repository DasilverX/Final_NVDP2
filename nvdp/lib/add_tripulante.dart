// lib/add_tripulante.dart

import 'package:flutter/material.dart';
import 'api_service.dart';

class AddTripulanteScreen extends StatefulWidget {
  const AddTripulanteScreen({super.key});

  @override
  State<AddTripulanteScreen> createState() => _AddTripulanteScreenState();
}

class _AddTripulanteScreenState extends State<AddTripulanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _rolController = TextEditingController();
  final _pasaporteController = TextEditingController();
  final _barcoIdController = TextEditingController();

  bool _isLoading = false;

  void _guardarTripulante() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final tripulanteData = {
        'nombre_completo': _nombreController.text,
        'rol_abordo': _rolController.text,
        'pasaporte': _pasaporteController.text,
        'id_barco': int.tryParse(_barcoIdController.text),
      };

      try {
        final bool exito = await _apiService.addTripulante(tripulanteData);

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tripulante añadido con éxito'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Devuelve true para refrescar la lista
        } else {
          throw Exception('Fallo al añadir el tripulante');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _rolController.dispose();
    _pasaporteController.dispose();
    _barcoIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nuevo Tripulante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rolController,
                decoration: const InputDecoration(labelText: 'Rol a Bordo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pasaporteController,
                decoration: const InputDecoration(labelText: 'Pasaporte'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcoIdController,
                decoration: const InputDecoration(labelText: 'ID del Barco Asignado'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarTripulante,
                    child: const Text('Guardar Tripulante'),
                  )
            ],
          ),
        ),
      ),
    );
  }
}