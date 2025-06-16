import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tipoBarcoController = TextEditingController();
  final _tipoCargaController = TextEditingController();
  final _serviciosController = TextEditingController();

  String? _analisisResult;
  bool _isLoading = false;

  Future<void> _generarAnalisis() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _analisisResult = null; // Limpiar resultado anterior
      });

      const url = 'http://localhost:3000/api/analisis-logistico';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tipoBarco': _tipoBarcoController.text,
            'tipoCarga': _tipoCargaController.text,
            'servicios': _serviciosController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _analisisResult = data['analisis'];
            });
          }
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception('Error del servidor: ${errorData['message']}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Logístico con IA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulación de Análisis Logístico',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Introduce los datos para que la IA de Gemini genere un análisis estimado.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tipoBarcoController,
                decoration: const InputDecoration(labelText: 'Tipo de Barco', hintText: 'Ej: Portacontenedores Panamax', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoCargaController,
                decoration: const InputDecoration(labelText: 'Tipo de Carga', hintText: 'Ej: Electrónicos y textiles', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviciosController,
                decoration: const InputDecoration(labelText: 'Servicios Requeridos', hintText: 'Ej: Repostaje y cambio de tripulación', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology_outlined),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _generarAnalisis,
                label: const Text('Generar Análisis'),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
              if (_analisisResult != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Respuesta de la IA', style: Theme.of(context).textTheme.titleLarge),
                        const Divider(height: 20),
                        SelectableText(_analisisResult!),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}