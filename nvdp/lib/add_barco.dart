import 'package:flutter/material.dart';
import 'package:nvdp/api_service.dart';

class AddBarcoScreen extends StatefulWidget {
  // CORRECCIÓN: Hacemos el parámetro 'barco' opcional.
  // Si no es nulo, estamos en modo edición. Si es nulo, es modo añadir.
  final Map<String, dynamic>? barco;

  const AddBarcoScreen({super.key, this.barco});

  @override
  _AddBarcoScreenState createState() => _AddBarcoScreenState();
}

class _AddBarcoScreenState extends State<AddBarcoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _imoController = TextEditingController();
  // ... otros controladores que necesites

  // CORRECCIÓN: Variable para saber si estamos editando
  bool get _isEditing => widget.barco != null;

  @override
  void initState() {
    super.initState();
    // CORRECCIÓN: Si estamos editando, llenamos los campos con los datos del barco
    if (_isEditing) {
      _nombreController.text = widget.barco!['NOMBRE_BARCO'] ?? '';
      _imoController.text = widget.barco!['NUMERO_IMO'] ?? '';
      // ... llena los otros controladores
    }
  }

  void _guardarBarco() async {
    if (_formKey.currentState!.validate()) {
      final barcoData = {
        'nombre_barco': _nombreController.text,
        'numero_imo': _imoController.text,
        // ... otros datos del formulario
      };

      bool exito = false;
      try {
        if (_isEditing) {
          // Si estamos editando, llamamos a updateBarco
          final barcoId = widget.barco!['ID_BARCO'];
          exito = await _apiService.updateBarco(barcoId, barcoData);
        } else {
          // Si no, llamamos a addBarco
          exito = await _apiService.addBarco(barcoData);
        }

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barco guardado exitosamente')),
          );
          Navigator.pop(context, true); // Devuelve 'true' para refrescar la lista
        } else if (mounted) {
           throw Exception('Fallo al guardar');
        }
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CORRECCIÓN: El título cambia dinámicamente
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Barco' : 'Añadir Nuevo Barco'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre del Barco'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, ingrese un nombre';
                  return null;
                },
              ),
              TextFormField(
                controller: _imoController,
                decoration: InputDecoration(labelText: 'Número IMO'),
                 validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, ingrese el número IMO';
                  return null;
                },
              ),
              // ... otros campos
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarBarco,
                child: Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}