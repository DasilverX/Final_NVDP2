import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nvdp/capitanes.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class RegistrarBarcoScreen extends StatefulWidget {
  const RegistrarBarcoScreen({super.key});

  @override
  State<RegistrarBarcoScreen> createState() => _RegistrarBarcoScreenState();
}

class _RegistrarBarcoScreenState extends State<RegistrarBarcoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _imoController = TextEditingController();
  final _tipoController = TextEditingController();
  final _banderaController = TextEditingController();
  
  List<dynamic> _clientes = [];
  int? _selectedClienteId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchClientes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _imoController.dispose();
    _tipoController.dispose();
    _banderaController.dispose();
    super.dispose();
  }

  Future<void> _fetchClientes() async {
    const url = 'http://localhost:3000/api/clientes';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _clientes = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else { throw Exception('Fallo al cargar los clientes'); }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
  
  Future<void> _registrarBarco() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final capitanUsuarioId = authService.user!['usuarioId'];

      const url = 'http://localhost:3000/api/capitan/registrar-barco';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': _nombreController.text,
            'numeroImo': _imoController.text,
            'tipo': _tipoController.text,
            'bandera': _banderaController.text,
            'propietarioId': _selectedClienteId,
            'capitanUsuarioId': capitanUsuarioId
          }),
        );
        
        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          final nuevoBarcoId = responseData['nuevoBarcoId'];

          // Actualizamos el estado de la app con el nuevo BarcoID
          authService.updateUserBarcoId(nuevoBarcoId);

          // ***** CAMBIO CLAVE AQUÍ *****
          // Realizamos la navegación PRIMERO, para asegurar que se ejecute.
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CapitanDashboardScreen(
                  barcoId: nuevoBarcoId,
                  nombreCapitan: authService.user!['nombre'],
                ),
              ),
            );
            // Y luego, mostramos el mensaje de éxito.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Barco registrado con éxito'), 
              backgroundColor: Colors.green,
            ));
          }
        } else {
          final responseBody = jsonDecode(response.body);
          throw Exception('Error al registrar: ${responseBody['error']}');
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        }
      } finally {
        if(mounted) { setState(() => _isSaving = false); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Mi Barco')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Bienvenido, Capitán", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text("Parece que es tu primera vez aquí o aún no tienes un barco asignado. Por favor, registra los datos de tu barco para continuar."),
                    const SizedBox(height: 24),
                    TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre del Barco', border: OutlineInputBorder()), validator: (v)=> v!.isEmpty ? 'Campo requerido' : null,),
                    const SizedBox(height: 16),
                    TextFormField(controller: _imoController, decoration: const InputDecoration(labelText: 'Número IMO', border: OutlineInputBorder()), validator: (v)=> v!.isEmpty ? 'Campo requerido' : null,),
                    const SizedBox(height: 16),
                    TextFormField(controller: _tipoController, decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextFormField(controller: _banderaController, decoration: const InputDecoration(labelText: 'Bandera', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedClienteId,
                      decoration: const InputDecoration(labelText: 'Propietario', border: OutlineInputBorder()),
                      hint: const Text('Seleccionar Propietario'),
                      items: _clientes.map<DropdownMenuItem<int>>((cliente) {
                        return DropdownMenuItem<int>(
                          value: cliente['CLIENTEID'],
                          child: Text(cliente['NOMBRE']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClienteId = value);
                      },
                      validator: (value) => value == null ? 'Seleccione un propietario' : null,
                    ),
                    const SizedBox(height: 24),
                    _isSaving 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: _registrarBarco,
                          child: const Text('Registrar y Continuar al Dashboard'),
                        ),
                  ],
                ),
              ),
            ),
    );
  }
}