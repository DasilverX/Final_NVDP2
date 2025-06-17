import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nvdp/login.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'login.dart';

class CapitanDashboardScreen extends StatefulWidget {
  final int barcoId;
  final String nombreCapitan;

  const CapitanDashboardScreen({
    super.key,
    required this.barcoId,
    required this.nombreCapitan,
  });

  @override
  State<CapitanDashboardScreen> createState() => _CapitanDashboardScreenState();
}

class _CapitanDashboardScreenState extends State<CapitanDashboardScreen> {
  List _peticiones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPeticiones();
  }

  Future<void> _fetchPeticiones() async {
    final url = 'http://localhost:3000/api/peticiones/barco/${widget.barcoId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (mounted && response.statusCode == 200) {
        setState(() {
          _peticiones = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar las peticiones');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  // ***** NUEVO MÉTODO PARA MOSTRAR EL FORMULARIO *****
  void _showAddPeticionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return _AddPeticionForm(
          usuarioId: Provider.of<AuthService>(context, listen: false).user!['usuarioId'],
        );
      },
    ).then((success) {
      // Si el formulario se cerró con éxito (devuelve true), refrescamos la lista
      if (success == true) {
        _fetchPeticiones();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Capitán ${widget.nombreCapitan}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPeticiones,
              child: _peticiones.isEmpty
                  ? Center(
                      child: Text('No hay peticiones de servicio registradas.',
                          style: Theme.of(context).textTheme.titleMedium))
                  : ListView.builder(
                      itemCount: _peticiones.length,
                      itemBuilder: (context, index) {
                        final peticion = _peticiones[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                          child: ListTile(
                            leading: CircleAvatar(
                                child: Icon(_getStatusIcon(peticion['ESTADO']))),
                            title: Text(peticion['SERVICIOTIPO']),
                            subtitle: Text(
                                'Puerto: ${peticion['NOMBREPUERTO']} - Estado: ${peticion['ESTADO']}'),
                            trailing: Text(peticion['FECHAPETICION']
                                .toString()
                                .substring(0, 10)),
                          ),
                        );
                      },
                    ),
            ),
      // ***** EL BOTÓN FLOTANTE AHORA LLAMA AL NUEVO MÉTODO *****
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPeticionForm,
        tooltip: 'Nueva Petición de Servicio',
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getStatusIcon(String? estado) {
    switch (estado) {
      case 'Pendiente': return Icons.hourglass_top;
      case 'Aprobado': return Icons.check_circle_outline;
      case 'Completado': return Icons.check_circle;
      case 'Rechazado': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }
}

// ***** WIDGET INTERNO PARA EL FORMULARIO *****
class _AddPeticionForm extends StatefulWidget {
  final int usuarioId;

  const _AddPeticionForm({required this.usuarioId});

  @override
  State<_AddPeticionForm> createState() => _AddPeticionFormState();
}

class _AddPeticionFormState extends State<_AddPeticionForm> {
  final _formKey = GlobalKey<FormState>();
  final _escalaIdController = TextEditingController();
  final _servicioIdController = TextEditingController();
  final _notasController = TextEditingController();
  bool _isSaving = false;

  Future<void> _submitPeticion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      const url = 'http://localhost:3000/api/peticiones';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'escalaId': int.parse(_escalaIdController.text),
            'servicioId': int.parse(_servicioIdController.text),
            'usuarioId': widget.usuarioId,
            'notas': _notasController.text,
          }),
        );

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Petición creada con éxito'),
                backgroundColor: Colors.green));
            Navigator.of(context).pop(true); // Cierra el formulario y devuelve 'true'
          }
        } else {
          final responseBody = jsonDecode(response.body);
          throw Exception(
              'Error al crear petición: ${responseBody['message']}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _escalaIdController.dispose();
    _servicioIdController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nueva Petición de Servicio',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _escalaIdController,
              decoration: const InputDecoration(labelText: 'ID de la Escala Portuaria'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _servicioIdController,
              decoration: const InputDecoration(labelText: 'ID del Servicio Requerido'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(labelText: 'Notas (Opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitPeticion,
                  child: const Text('Enviar Petición'),
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}