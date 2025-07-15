// lib/add_usuario.dart

import 'package:flutter/material.dart';
import 'api_service.dart';

class AddUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  const AddUsuarioScreen({super.key, this.usuario});

  @override
  State<AddUsuarioScreen> createState() => _AddUsuarioScreenState();
}

class _AddUsuarioScreenState extends State<AddUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Usaremos un Future para manejar la carga de los roles
  late Future<List<dynamic>> _rolesFuture;
  int? _selectedRolId;

  bool get _isEditing => widget.usuario != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Iniciamos la carga de los roles aquí
    _rolesFuture = _apiService.getRoles();
    
    if (_isEditing) {
      _nombreController.text = widget.usuario!['NOMBRE_USUARIO'] ?? '';
      _selectedRolId = widget.usuario!['ID_ROL'];
    }
  }
  
  void _guardarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final userData = {
        'nombre_usuario': _nombreController.text,
        'id_rol': _selectedRolId,
      };

      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      try {
        bool exito = false;
        if (_isEditing) {
          throw Exception("La función de editar aún no está implementada.");
        } else {
          exito = await _apiService.addUsuario(userData);
        }

        if (mounted && exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario guardado'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
           throw Exception('Fallo al guardar el usuario');
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if(mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
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
                  helperText: _isEditing ? 'Dejar en blanco para no cambiar' : null,
                ),
                obscureText: true,
                validator: (v) {
                  if (!_isEditing && (v == null || v.isEmpty)) return 'Campo requerido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // --- WIDGET CORREGIDO Y SIMPLIFICADO ---
              // Usamos un FutureBuilder para mostrar el selector solo cuando los datos estén listos.
              FutureBuilder<List<dynamic>>(
                future: _rolesFuture,
                builder: (context, snapshot) {
                  // Mientras carga, muestra un indicador
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  // Si hay un error, lo muestra
                  if (snapshot.hasError) {
                    return Text('Error al cargar roles: ${snapshot.error}');
                  }
                  // Si no hay datos, muestra un mensaje
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No se encontraron roles.');
                  }
                  
                  // Cuando los datos están listos, construye el selector
                  final roles = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    value: _selectedRolId,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: roles.map<DropdownMenuItem<int>>((rol) {
                      return DropdownMenuItem<int>(
                        value: rol['ID_ROL'],
                        child: Text(rol['NOMBRE_ROL']),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedRolId = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Por favor, seleccione un rol' : null,
                  );
                },
              ),

              const SizedBox(height: 32),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarUsuario,
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}