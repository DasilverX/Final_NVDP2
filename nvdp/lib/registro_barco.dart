// lib/registro_barco.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'main.dart'; // Contiene DashboardScreen

class RegistroBarcoScreen extends StatefulWidget {
  const RegistroBarcoScreen({super.key});

  @override
  State<RegistroBarcoScreen> createState() => _RegistroBarcoScreenState();
}

class _RegistroBarcoScreenState extends State<RegistroBarcoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final _nombreController = TextEditingController();
  final _imoController = TextEditingController();
  bool _isLoading = false;

  void _registrarBarco() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final clienteId = authService.userData?['id_usuario']; 

      final barcoData = {
        'nombre_barco': _nombreController.text,
        'numero_imo': _imoController.text,
        'id_cliente': clienteId,
        'id_tipo_barco': 1,
        'id_pais_bandera': 1,
      };

      try {
        final responseData = await _apiService.addBarco(barcoData);
        if (mounted && responseData != null) {
          final nuevoBarcoId = responseData['nuevoBarcoId'];
          authService.updateUserBarcoId(nuevoBarcoId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barco registrado con éxito'), backgroundColor: Colors.green)
          );
          // CORRECCIÓN: Navegamos a DashboardScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
           throw Exception('Fallo al registrar el barco');
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red)
          );
        }
      } finally {
        if(mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _imoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Mi Barco')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Por favor, ingrese los datos de su embarcación.', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Barco'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imoController,
                decoration: const InputDecoration(labelText: 'Número IMO'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registrarBarco,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                      child: const Text('Registrar Barco'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}