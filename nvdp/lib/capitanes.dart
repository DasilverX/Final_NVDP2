// lib/capitanes.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'api_service.dart';

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
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _peticionesFuture;

  @override
  void initState() {
    super.initState();
    _peticionesFuture = _apiService.getPeticionesPorBarco(widget.barcoId);
  }

  void _refreshPeticiones() {
    setState(() {
      _peticionesFuture = _apiService.getPeticionesPorBarco(widget.barcoId);
    });
  }

  void _showAddPeticionForm() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final usuarioId = authService.userData?['id_usuario'];

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se pudo identificar al usuario.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddPeticionForm(usuarioId: usuarioId),
    ).then((success) {
      if (success == true) {
        _refreshPeticiones();
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
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshPeticiones(),
        child: FutureBuilder<List<dynamic>>(
          future: _peticionesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final peticiones = snapshot.data ?? [];
            if (peticiones.isEmpty) {
              return Center(child: Text('No hay peticiones de servicio registradas.', style: Theme.of(context).textTheme.titleMedium));
            }
            return ListView.builder(
              itemCount: peticiones.length,
              itemBuilder: (context, index) {
                final peticion = peticiones[index];
                final date = DateTime.parse(peticion['FECHA_PETICION']);
                final dateFormatter = DateFormat('dd/MM/yyyy');

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_getStatusIcon(peticion['ESTADO']))),
                    title: Text(peticion['NOMBRE_SERVICIO']),
                    subtitle: Text('Puerto: ${peticion['NOMBRE_PUERTO']} - Estado: ${peticion['ESTADO']}'),
                    trailing: Text(dateFormatter.format(date)),
                  ),
                );
              },
            );
          },
        ),
      ),
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

class _AddPeticionForm extends StatefulWidget {
  final int usuarioId;
  const _AddPeticionForm({required this.usuarioId});
  @override
  State<_AddPeticionForm> createState() => _AddPeticionFormState();
}

class _AddPeticionFormState extends State<_AddPeticionForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final _escalaIdController = TextEditingController();
  final _servicioIdController = TextEditingController();
  final _notasController = TextEditingController();
  bool _isSaving = false;

  Future<void> _submitPeticion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final success = await _apiService.addPeticion({
          'escalaId': int.parse(_escalaIdController.text),
          'servicioId': int.parse(_servicioIdController.text),
          'usuarioId': widget.usuarioId,
          'notas': _notasController.text,
        });
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Petición creada con éxito'),
              backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        } else if(mounted) {
          throw Exception('Error al crear la petición');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
            Text('Nueva Petición de Servicio', style: Theme.of(context).textTheme.headlineSmall),
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