import 'package:flutter/material.dart';
import 'api_service.dart';

class EditTripulanteScreen extends StatefulWidget {
  // Este widget siempre recibirá los datos del tripulante a editar
  final Map<String, dynamic> tripulante;

  const EditTripulanteScreen({super.key, required this.tripulante});

  @override
  State<EditTripulanteScreen> createState() => _EditTripulanteScreenState();
}

class _EditTripulanteScreenState extends State<EditTripulanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nombreController;
  late TextEditingController _rolController;
  late TextEditingController _pasaporteController;
  late TextEditingController _barcoIdController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Llenamos los campos con los datos del tripulante que recibimos
    _nombreController = TextEditingController(text: widget.tripulante['NOMBRE_COMPLETO']);
    _rolController = TextEditingController(text: widget.tripulante['ROL_ABORDO']);
    _pasaporteController = TextEditingController(text: widget.tripulante['PASAPORTE']);
    _barcoIdController = TextEditingController(text: widget.tripulante['ID_BARCO']?.toString() ?? '');
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final tripulanteData = {
        'nombre_completo': _nombreController.text,
        'rol_abordo': _rolController.text,
        'pasaporte': _pasaporteController.text,
        'id_barco': int.tryParse(_barcoIdController.text),
      };

      try {
        final exito = await _apiService.updateTripulante(widget.tripulante['ID_TRIPULACION'], tripulanteData);

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cambios guardados'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Devuelve true para refrescar la lista
        } else if(mounted) {
           throw Exception('Fallo al guardar los cambios');
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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
    _rolController.dispose();
    _pasaporteController.dispose();
    _barcoIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Tripulante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rolController,
                decoration: const InputDecoration(labelText: 'Rol a Bordo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pasaporteController,
                decoration: const InputDecoration(labelText: 'Pasaporte'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcoIdController,
                decoration: const InputDecoration(labelText: 'ID del Barco Asignado'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarCambios,
                    child: const Text('Guardar Cambios'),
                  )
            ],
          ),
        ),
      ),
    );
  }
}