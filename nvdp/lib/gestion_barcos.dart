import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'add_barco.dart';

class GestionBarcosScreen extends StatefulWidget {
  const GestionBarcosScreen({super.key});
  @override
  State<GestionBarcosScreen> createState() => _GestionBarcosScreenState();
}

class _GestionBarcosScreenState extends State<GestionBarcosScreen> {
  final ApiService _apiService = ApiService();
  List _barcos = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchTerm = '';
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchBarcos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchBarcos({bool isNewSearch = false}) async {
    if (isNewSearch) {
      _currentPage = 1;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getBarcosPaginado(page: _currentPage, search: _searchTerm);
      if (mounted) {
        setState(() {
          _barcos = data['barcos'] ?? [];
          _totalPages = data['totalPages'] ?? 1;
          _currentPage = data['currentPage'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _navigateToForm({Map<String, dynamic>? barco}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddBarcoScreen(barco: barco)),
    );
    if (result == true) {
      _fetchBarcos(isNewSearch: true);
    }
  }
  
  void _deleteBarco(int id, String nombre) async {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Seguro que quieres eliminar el barco "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _apiService.deleteBarco(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barco eliminado'), backgroundColor: Colors.green));
                _fetchBarcos(isNewSearch: true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchTerm != query) {
        setState(() => _searchTerm = query);
        _fetchBarcos(isNewSearch: true);
      }
    });
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
      _fetchBarcos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).esAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Barcos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Nombre o IMO',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ) : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchBarcos(isNewSearch: true),
                    child: _barcos.isEmpty 
                      ? const Center(child: Text('No se encontraron barcos.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _barcos.length,
                          itemBuilder: (context, index) {
                            final barco = _barcos[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.directions_boat)),
                                title: Text(barco['NOMBRE_BARCO'] ?? 'Sin Nombre'),
                                subtitle: Text(
                                  'IMO: ${barco['NUMERO_IMO']}\nPropietario: ${barco['NOMBRE_CLIENTE'] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                isThreeLine: true,
                                trailing: esAdmin ? IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                                  onPressed: () => _deleteBarco(barco['ID_BARCO'], barco['NOMBRE_BARCO']),
                                ) : null,
                                onTap: esAdmin ? () => _navigateToForm(barco: barco) : null,
                              ),
                            );
                          },
                        ),
                  ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                    child: const Text('Anterior'),
                  ),
                  Text('Página $_currentPage de $_totalPages'),
                  ElevatedButton(
                    onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: esAdmin ? FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}