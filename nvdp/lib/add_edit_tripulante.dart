import 'package:flutter/material.dart';
import 'api_service.dart';

class AddEditTripulanteScreen extends StatefulWidget {
  final Map<String, dynamic>? tripulante;
  const AddEditTripulanteScreen({super.key, this.tripulante});

  @override
  State<AddEditTripulanteScreen> createState() => _AddEditTripulanteScreenState();
}

class _AddEditTripulanteScreenState extends State<AddEditTripulanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nombreController;
  late TextEditingController _rolController;
  late TextEditingController _pasaporteController;
  late TextEditingController _barcoIdController;

  bool get _isEditing => widget.tripulante != null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: _isEditing ? widget.tripulante!['NOMBRE_COMPLETO'] : '');
    _rolController = TextEditingController(text: _isEditing ? widget.tripulante!['ROL_ABORDO'] : '');
    _pasaporteController = TextEditingController(text: _isEditing ? widget.tripulante!['PASAPORTE'] : '');
    _barcoIdController = TextEditingController(text: _isEditing ? widget.tripulante!['ID_BARCO']?.toString() : '');
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final data = {
        'nombre_completo': _nombreController.text,
        'rol_abordo': _rolController.text,
        'pasaporte': _pasaporteController.text,
        'id_barco': int.tryParse(_barcoIdController.text),
      };
      try {
        bool exito = false;
        if (_isEditing) {
          exito = await _apiService.updateTripulante(widget.tripulante!['ID_TRIPULACION'], data);
        } else {
          exito = await _apiService.addTripulante(data);
        }
        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado con éxito'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else if (mounted) {
          throw Exception('Fallo al guardar');
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Tripulante' : 'Añadir Tripulante')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _rolController, decoration: const InputDecoration(labelText: 'Rol a Bordo'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _pasaporteController, decoration: const InputDecoration(labelText: 'Pasaporte'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _barcoIdController, decoration: const InputDecoration(labelText: 'ID del Barco Asignado'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 32),
              _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}