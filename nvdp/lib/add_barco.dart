import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class AddBarcoScreen extends StatefulWidget {
  // Hacemos que el barco sea opcional. Si viene, estamos editando.
  final Map<String, dynamic>? barco;

  const AddBarcoScreen({super.key, this.barco});

  @override
  State<AddBarcoScreen> createState() => _AddBarcoScreenState();
}

class _AddBarcoScreenState extends State<AddBarcoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _imoController = TextEditingController();
  final _tipoController = TextEditingController();
  final _banderaController = TextEditingController();

  List<dynamic> _clientes = [];
  int? _selectedClienteId;
  bool _isLoading = true;
  bool _isSaving = false;

  // Determinamos si estamos en modo de edición
  bool get _isEditing => widget.barco != null;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, llenamos los campos con los datos del barco
    if (_isEditing) {
      _nombreController.text = widget.barco!['NOMBRE'];
      _imoController.text = widget.barco!['NUMEROIMO'];
      _tipoController.text = widget.barco!['TIPO'];
      _banderaController.text = widget.barco!['BANDERA'];
      // Guardamos el ID del propietario para pre-seleccionar en el dropdown
      _selectedClienteId = widget.barco!['PROPIETARIOID'];
    }
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
    const url = '$apiBaseUrl/api/clientes';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _clientes = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Fallo al cargar los clientes');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      // Dependiendo del modo, llamamos a una función u otra
      if (_isEditing) {
        await _updateBarco();
      } else {
        await _addBarco();
      }
      if(mounted){
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addBarco() async {
    const url = '$apiBaseUrl/api/barcos';
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
        }),
      );
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Barco añadido con éxito'),
              backgroundColor: Colors.green));
          Navigator.of(context).pop(true); // Regresar y refrescar
        }
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception('Error al añadir barco: ${responseBody['message']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _updateBarco() async {
    final barcoId = widget.barco!['BARCOID'];
    final url = '$apiBaseUrl/api/barcos/$barcoId';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': _nombreController.text,
          'tipo': _tipoController.text,
          'bandera': _banderaController.text,
          'propietarioId': _selectedClienteId,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Barco actualizado con éxito'),
              backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception('Error al actualizar: ${responseBody['message']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Barco' : 'Añadir Nuevo Barco'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre del Barco', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imoController,
                      decoration: const InputDecoration(labelText: 'Número IMO', border: OutlineInputBorder()),
                      // Deshabilitamos el campo IMO si estamos editando
                      readOnly: _isEditing,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tipoController,
                      decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _banderaController,
                      decoration: const InputDecoration(labelText: 'Bandera', border: OutlineInputBorder()),
                    ),
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
                      validator: (value) =>
                          value == null ? 'Seleccione un propietario' : null,
                    ),
                    const SizedBox(height: 24),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _onSave,
                            child: Text(_isEditing ? 'Actualizar Barco' : 'Guardar Barco'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}