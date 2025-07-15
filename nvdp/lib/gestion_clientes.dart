// lib/gestion_clientes.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'add_clientes.dart'; // Importamos el formulario

class GestionClientesScreen extends StatefulWidget {
  const GestionClientesScreen({super.key});
  @override
  State<GestionClientesScreen> createState() => _GestionClientesScreenState();
}

class _GestionClientesScreenState extends State<GestionClientesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _clientesFuture;

  @override
  void initState() {
    super.initState();
    _clientesFuture = _apiService.getClientes();
  }

  void _refreshData() {
    setState(() {
      _clientesFuture = _apiService.getClientes();
    });
  }

  void _navigateToForm({Map<String, dynamic>? cliente}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddClienteScreen(cliente: cliente)),
    );
    if (result == true) _refreshData();
  }
  
  void _deleteCliente(int id, String nombre) async {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Seguro que quieres eliminar al cliente "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _apiService.deleteCliente(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado'), backgroundColor: Colors.green));
                _refreshData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).esAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Clientes')),
      body: FutureBuilder<List<dynamic>>(
        future: _clientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final clientes = snapshot.data ?? [];
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(cliente['NOMBRE_CLIENTE']),
                  subtitle: Text('RUC: ${cliente['RUC_CLIENTE'] ?? 'N/A'}'),
                  trailing: esAdmin ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteCliente(cliente['ID_CLIENTE'], cliente['NOMBRE_CLIENTE']),
                  ) : null,
                  onTap: esAdmin ? () => _navigateToForm(cliente: cliente) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: esAdmin ? FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}