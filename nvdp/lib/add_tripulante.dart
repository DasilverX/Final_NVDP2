import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class AddTripulanteScreen extends StatefulWidget {
  const AddTripulanteScreen({super.key});

  @override
  State<AddTripulanteScreen> createState() => _AddTripulanteScreenState();
}

class _AddTripulanteScreenState extends State<AddTripulanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcoIdController = TextEditingController();
  final _nombreController = TextEditingController();
  final _rolController = TextEditingController();
  final _pasaporteController = TextEditingController();
  final _nacionalidadController = TextEditingController();
  bool _isSaving = false;

  Future<void> _addTripulante() async {
    // Validar el formulario
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      const url = '$apiBaseUrl/api/tripulantes';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'barcoId': int.tryParse(_barcoIdController.text), // Convertir a número
            'nombre': _nombreController.text,
            'rol': _rolController.text,
            'pasaporte': _pasaporteController.text,
            'nacionalidad': _nacionalidadController.text,
          }),
        );

        if (response.statusCode == 201) {
          // Si el servidor responde con 201 (Created), todo fue bien
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tripulante añadido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Regresar a la pantalla anterior
        } else {
          // Si hay un error, mostrar el mensaje del servidor
          final responseBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${responseBody['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Limpiar los controladores cuando el widget se destruye
    _barcoIdController.dispose();
    _nombreController.dispose();
    _rolController.dispose();
    _pasaporteController.dispose();
    _nacionalidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nuevo Tripulante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Usamos ListView para evitar overflows si el teclado aparece
            children: [
              TextFormField(
                controller: _barcoIdController,
                decoration: const InputDecoration(labelText: 'ID del Barco'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el ID del barco';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _rolController,
                decoration: const InputDecoration(labelText: 'Rol a Bordo'),
              ),
              TextFormField(
                controller: _pasaporteController,
                decoration: const InputDecoration(labelText: 'Número de Pasaporte'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el pasaporte';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nacionalidadController,
                decoration: const InputDecoration(labelText: 'Nacionalidad'),
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addTripulante,
                      child: const Text('Guardar Tripulante'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}