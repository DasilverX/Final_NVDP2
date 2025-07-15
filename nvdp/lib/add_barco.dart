import 'package:flutter/material.dart';
import 'package:nvdp/api_service.dart';

class AddBarcoScreen extends StatefulWidget {
  final Map<String, dynamic>? barco;
  const AddBarcoScreen({super.key, this.barco});

  @override
  _AddBarcoScreenState createState() => _AddBarcoScreenState();
}

class _AddBarcoScreenState extends State<AddBarcoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // --- CONTROLADORES PARA TODOS LOS CAMPOS ---
  final _nombreController = TextEditingController();
  final _imoController = TextEditingController();
  final _tipoBarcoController = TextEditingController();
  final _paisBanderaController = TextEditingController();
  final _clienteController = TextEditingController();

  bool get _isEditing => widget.barco != null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, llenamos todos los campos con los datos del barco
    if (_isEditing) {
      _nombreController.text = widget.barco!['NOMBRE_BARCO'] ?? '';
      _imoController.text = widget.barco!['NUMERO_IMO'] ?? '';
      // Convertimos los IDs (que son números) a String para los controladores
      _tipoBarcoController.text = widget.barco!['ID_TIPO_BARCO']?.toString() ?? '';
      _paisBanderaController.text = widget.barco!['ID_PAIS_BANDERA']?.toString() ?? '';
      _clienteController.text = widget.barco!['ID_CLIENTE']?.toString() ?? '';
    }
  }

  void _guardarBarco() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Creamos el mapa con todos los datos del formulario
      final barcoData = {
        'nombre_barco': _nombreController.text,
        'numero_imo': _imoController.text,
        // Convertimos el texto de los IDs de vuelta a números
        'id_tipo_barco': int.tryParse(_tipoBarcoController.text),
        'id_pais_bandera': int.tryParse(_paisBanderaController.text),
        'id_cliente': int.tryParse(_clienteController.text),
      };

      bool exito = false;
      try {
        if (_isEditing) {
          final barcoId = widget.barco!['ID_BARCO'];
          exito = await _apiService.updateBarco(barcoId, barcoData);
        } else {
          // El método addBarco ahora devuelve un Map, no un bool.
          // Lo consideramos un éxito si la respuesta no es nula.
          final response = await _apiService.addBarco(barcoData);
          exito = response != null;
        }

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barco guardado exitosamente'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Devuelve 'true' para refrescar la lista
        } else if (mounted) {
           throw Exception('Fallo al guardar');
        }
      } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
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
    // Limpiamos los controladores al salir de la pantalla
    _nombreController.dispose();
    _imoController.dispose();
    _tipoBarcoController.dispose();
    _paisBanderaController.dispose();
    _clienteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                decoration: const InputDecoration(labelText: 'Nombre del Barco'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imoController,
                decoration: const InputDecoration(labelText: 'Número IMO'),
                 validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoBarcoController,
                decoration: const InputDecoration(labelText: 'ID Tipo de Barco'),
                keyboardType: TextInputType.number,
                 validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paisBanderaController,
                decoration: const InputDecoration(labelText: 'ID País de Bandera'),
                keyboardType: TextInputType.number,
                 validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
               const SizedBox(height: 16),
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(labelText: 'ID Cliente'),
                keyboardType: TextInputType.number,
                 validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarBarco,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar Cambios'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}