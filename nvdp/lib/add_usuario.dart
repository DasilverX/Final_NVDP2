import 'package:flutter/material.dart';
import 'api_service.dart';

class AddUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario; // Si es nulo, es para añadir. Si no, para editar.
  const AddUsuarioScreen({super.key, this.usuario});

  @override
  State<AddUsuarioScreen> createState() => _AddUsuarioScreenState();
}

class _AddUsuarioScreenState extends State<AddUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rolController = TextEditingController();

  bool get _isEditing => widget.usuario != null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nombreController.text = widget.usuario!['NOMBRE_USUARIO'] ?? '';
      _rolController.text = widget.usuario!['ID_ROL']?.toString() ?? '';
      // No precargamos la contraseña por seguridad
    }
  }

  void _guardarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userData = {
        'nombre_usuario': _nombreController.text,
        'id_rol': int.tryParse(_rolController.text),
      };

      // Solo incluimos la contraseña si se escribió algo.
      // Así, al editar, si el campo está vacío, no se cambia la contraseña.
      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      try {
        bool exito = false;
        if (_isEditing) {
          // NOTA: Aún no hemos creado el endpoint PUT para usuarios en el API
          // ni la función en ApiService, pero preparamos el código.
          // exito = await _apiService.updateUsuario(widget.usuario!['ID_USUARIO'], userData);
          throw Exception("La función de editar aún no está implementada en el API.");
        } else {
          exito = await _apiService.addUsuario(userData);
        }

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario guardado con éxito'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Devuelve true para refrescar
        } else if (mounted && !_isEditing){
           throw Exception('Fallo al guardar');
        }

      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
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
    _passwordController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Usuario' : 'Añadir Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  // Mostramos una ayuda si estamos editando
                  helperText: _isEditing ? 'Dejar en blanco para no cambiar' : null,
                ),
                obscureText: true,
                validator: (v) {
                  // La contraseña solo es requerida si estamos creando un usuario nuevo
                  if (!_isEditing && (v == null || v.isEmpty)) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rolController,
                decoration: const InputDecoration(labelText: 'ID del Rol (ej: 1, 2, 3)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarUsuario,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
