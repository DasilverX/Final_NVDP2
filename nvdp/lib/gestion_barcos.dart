import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nvdp/add_barco.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'config.dart';

class GestionBarcosScreen extends StatefulWidget {
  const GestionBarcosScreen({super.key});

  @override
  State<GestionBarcosScreen> createState() => _GestionBarcosScreenState();
}

class _GestionBarcosScreenState extends State<GestionBarcosScreen> {
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

    final url = Uri.parse(
        '$apiBaseUrl/api/barcos?page=$_currentPage&search=$_searchTerm');
    try {
      final response = await http.get(url);
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _barcos = data['barcos'];
          _totalPages = data['totalPages'];
          _currentPage = data['currentPage'];
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar los barcos');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  Future<void> _deleteBarco(int id) async {
    final url = '$apiBaseUrl/api/barcos/$id';
    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Barco eliminado exitosamente'),
              backgroundColor: Colors.green));
        }
        _fetchBarcos(isNewSearch: true);
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody['error'] ?? 'Error al eliminar');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showDeleteConfirmationDialog(int id, String nombre) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
              '¿Estás seguro de que deseas eliminar el barco $nombre?\n\nADVERTENCIA: Esta acción solo funcionará si el barco no tiene escalas portuarias registradas.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBarco(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchTerm = query);
        _fetchBarcos(isNewSearch: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = Provider.of<AuthService>(context).userRole == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Barcos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por Nombre, IMO, Tipo o Bandera',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _barcos.isEmpty
                      ? const Center(child: Text('No se encontraron barcos.'))
                      : RefreshIndicator(
                          onRefresh: () => _fetchBarcos(isNewSearch: true),
                          child: ListView.builder(
                            itemCount: _barcos.length,
                            itemBuilder: (context, index) {
                              final barco = _barcos[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0, vertical: 6.0),
                                child: InkWell(
                                  onTap: esAdmin
                                      ? () async {
                                          final result = await Navigator.of(
                                                  context)
                                              .push<bool>(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddBarcoScreen(barco: barco),
                                            ),
                                          );
                                          if (result == true) {
                                            _fetchBarcos(isNewSearch: true);
                                          }
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          barco['NOMBRE'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'IMO: ${barco['NUMEROIMO']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const Divider(height: 20),
                                        _buildInfoRow(context, Icons.flag_outlined,
                                            'Bandera', barco['BANDERA']),
                                        _buildInfoRow(context, Icons.category_outlined,
                                            'Tipo', barco['TIPO']),
                                        _buildInfoRow(context, Icons.business_center_outlined,
                                            'Propietario', barco['NOMBREPROPIETARIO']),
                                        if (esAdmin)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: IconButton(
                                              icon: Icon(Icons.delete_outline,
                                                  color: Colors.red[700]),
                                              onPressed: () {
                                                _showDeleteConfirmationDialog(
                                                    barco['BARCOID'],
                                                    barco['NOMBRE']);
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _fetchBarcos();
                          }
                        : null,
                    child: const Text('Anterior'),
                  ),
                  Text('Página $_currentPage de $_totalPages'),
                  ElevatedButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _fetchBarcos();
                          }
                        : null,
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: esAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddBarcoScreen(),
                  ),
                );
                if (result == true) {
                  _fetchBarcos(isNewSearch: true);
                }
              },
              tooltip: 'Añadir Barco',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value ?? 'N/A',
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}