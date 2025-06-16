import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class EditTripulanteScreen extends StatefulWidget {
  // Este widget recibe los datos del tripulante que se va a editar
  final Map<String, dynamic> tripulante;

  const EditTripulanteScreen({super.key, required this.tripulante});

  @override
  State<EditTripulanteScreen> createState() => _EditTripulanteScreenState();
}

class _EditTripulanteScreenState extends State<EditTripulanteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _rolController;
  late TextEditingController _nacionalidadController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Llenamos los controladores con los datos existentes del tripulante
    _nombreController = TextEditingController(text: widget.tripulante['NOMBRE']);
    _rolController = TextEditingController(text: widget.tripulante['ROL']);
    _nacionalidadController = TextEditingController(text: widget.tripulante['NACIONALIDAD']);
  }

  Future<void> _updateTripulante() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final tripulanteId = widget.tripulante['TRIPULACIONID'];
      final url = '$apiBaseUrl/api/tripulantes/$tripulanteId';
      
      try {
        final response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': _nombreController.text,
            'rol': _rolController.text,
            'nacionalidad': _nacionalidadController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tripulante actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Regresar y enviar 'true' para indicar éxito
        } else {
          final responseBody = jsonDecode(response.body);
          throw Exception('Error al actualizar: ${responseBody['message']}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
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
    _nombreController.dispose();
    _rolController.dispose();
    _nacionalidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar a ${widget.tripulante['NOMBRE']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (value) => value == null || value.isEmpty ? 'Por favor, ingrese el nombre' : null,
              ),
              TextFormField(
                controller: _rolController,
                decoration: const InputDecoration(labelText: 'Rol a Bordo'),
              ),
              TextFormField(
                controller: _nacionalidadController,
                decoration: const InputDecoration(labelText: 'Nacionalidad'),
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateTripulante,
                      child: const Text('Actualizar Tripulante'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}