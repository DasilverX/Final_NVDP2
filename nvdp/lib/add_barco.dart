import 'package:flutter/material.dart';
import 'api_service.dart';

class AddBarcoScreen extends StatefulWidget {
  final Map<String, dynamic>? barco;
  const AddBarcoScreen({super.key, this.barco});

  @override
  State<AddBarcoScreen> createState() => _AddBarcoScreenState();
}

class _AddBarcoScreenState extends State<AddBarcoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controladores para campos de texto
  final _nombreController = TextEditingController();
  final _imoController = TextEditingController();

  // Variables de estado para los menús desplegables
  int? _selectedTipoBarcoId;
  int? _selectedPaisId;
  int? _selectedClienteId;

  // Futuros para cargar los datos de los menús
  late Future<List<List<dynamic>>> _dropdownDataFuture;

  bool get _isEditing => widget.barco != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Cargamos todos los datos de los dropdowns a la vez
    _dropdownDataFuture = Future.wait([
      _apiService.getTiposDeBarco(),
      _apiService.getPaises(),
      _apiService.getClientes(),
    ]);

    if (_isEditing) {
      _nombreController.text = widget.barco!['NOMBRE_BARCO'] ?? '';
      _imoController.text = widget.barco!['NUMERO_IMO'] ?? '';
      _selectedTipoBarcoId = widget.barco!['ID_TIPO_BARCO'];
      _selectedPaisId = widget.barco!['ID_PAIS_BANDERA'];
      _selectedClienteId = widget.barco!['ID_CLIENTE'];
    }
  }

  void _guardarBarco() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final barcoData = {
        'nombre_barco': _nombreController.text,
        'numero_imo': _imoController.text,
        'id_tipo_barco': _selectedTipoBarcoId,
        'id_pais_bandera': _selectedPaisId,
        'id_cliente': _selectedClienteId,
      };

      try {
        bool exito = false;
        if (_isEditing) {
          final barcoId = widget.barco!['ID_BARCO'];
          exito = await _apiService.updateBarco(barcoId, barcoData);
        } else {
          final response = await _apiService.addBarco(barcoData);
          exito = response != null;
        }

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barco guardado con éxito'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else if (mounted) {
          throw Exception('Fallo al guardar');
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() => _isSaving = false);
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Barco' : 'Añadir Barco')),
      body: FutureBuilder<List<List<dynamic>>>(
        future: _dropdownDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos para los formularios: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final tiposBarco = snapshot.data![0];
          final paises = snapshot.data![1];
          final clientes = snapshot.data![2];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre del Barco'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _imoController, decoration: const InputDecoration(labelText: 'Número IMO'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 16),
                  
                  // Menú desplegable para Tipo de Barco
                  DropdownButtonFormField<int>(
                    value: _selectedTipoBarcoId,
                    decoration: const InputDecoration(labelText: 'Tipo de Barco'),
                    items: tiposBarco.map<DropdownMenuItem<int>>((tipo) => DropdownMenuItem<int>(value: tipo['ID_TIPO_BARCO'], child: Text(tipo['TIPO_BARCO']))).toList(),
                    onChanged: (val) => setState(() => _selectedTipoBarcoId = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Menú desplegable para País de Bandera
                  DropdownButtonFormField<int>(
                    value: _selectedPaisId,
                    decoration: const InputDecoration(labelText: 'País de Bandera'),
                    items: paises.map<DropdownMenuItem<int>>((pais) => DropdownMenuItem<int>(value: pais['ID_PAIS'], child: Text(pais['PAIS']))).toList(),
                    onChanged: (val) => setState(() => _selectedPaisId = val),
                     validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Menú desplegable para Cliente
                  DropdownButtonFormField<int>(
                    value: _selectedClienteId,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: clientes.map<DropdownMenuItem<int>>((cliente) => DropdownMenuItem<int>(value: cliente['ID_CLIENTE'], child: Text(cliente['NOMBRE_CLIENTE']))).toList(),
                    onChanged: (val) => setState(() => _selectedClienteId = val),
                     validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _guardarBarco, child: const Text('Guardar Cambios')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}