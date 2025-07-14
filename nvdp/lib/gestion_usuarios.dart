import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  List _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/usuarios'));
      if (mounted && response.statusCode == 200) {
        setState(() {
          _usuarios = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar los usuarios: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddUserForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddUserForm(),
    ).then((success) {
      if (success == true) {
        _fetchUsuarios();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsuarios,
              child: ListView.builder(
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = _usuarios[index];
                  return ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(usuario['NOMBRE']),
                    subtitle: Text('Rol: ${usuario['NOMBREROL']}'),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserForm,
        tooltip: 'Añadir Usuario',
        child: const Icon(Icons.add),
      ),
    );
  }
}


// Widget interno para el formulario de creación de usuario
class _AddUserForm extends StatefulWidget {
  const _AddUserForm();

  @override
  __AddUserFormState createState() => __AddUserFormState();
}

class __AddUserFormState extends State<_AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _barcoIdController = TextEditingController();
  
  List<dynamic> _roles = [];
  Map<String, dynamic>? _selectedRole;
  bool _isLoadingRoles = true;
  bool _isSaving = false;
  // SOLUCIÓN PUNTO 3: Estado para controlar la visibilidad de la contraseña
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  // SOLUCIÓN PUNTO 2: Esta función obtiene los roles para el menú desplegable
  Future<void> _fetchRoles() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/roles'));
      if(mounted && response.statusCode == 200) {
        setState(() {
          _roles = jsonDecode(response.body);
          _isLoadingRoles = false;
        });
      } else {
        throw Exception('Fallo al cargar los roles');
      }
    } catch (e) { 
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/api/usuarios'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': _nombreController.text,
            'password': _passwordController.text,
            'rolId': _selectedRole!['ROLID'],
            'barcoId': _barcoIdController.text.isNotEmpty ? int.parse(_barcoIdController.text) : null,
          }),
        );
        if (mounted) {
          if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado con éxito'), backgroundColor: Colors.green));
            Navigator.of(context).pop(true);
          } else {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'Error desconocido');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Crear Nuevo Usuario', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre de Usuario'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            // SOLUCIÓN PUNTO 3: Campo de contraseña con visibilidad
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            // SOLUCIÓN PUNTO 2: Menú desplegable para roles
            _isLoadingRoles ? const Center(child: CircularProgressIndicator()) : DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedRole,
              hint: const Text('Seleccionar Rol'),
              items: _roles.map<DropdownMenuItem<Map<String, dynamic>>>((role) {
                return DropdownMenuItem<Map<String, dynamic>>(value: role, child: Text(role['NOMBREROL']));
              }).toList(),
              onChanged: (value) => setState(() => _selectedRole = value),
              validator: (value) => value == null ? 'Seleccione un rol' : null,
            ),
            if (_selectedRole?['NOMBREROL'] == 'capitan')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _barcoIdController,
                  decoration: const InputDecoration(labelText: 'ID del Barco Asignado (Opcional)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            const SizedBox(height: 24),
            _isSaving ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _submitUser, child: const Text('Crear Usuario')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}