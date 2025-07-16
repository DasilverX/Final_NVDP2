import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // AJUSTE 1: Creamos una instancia del ApiService
  final ApiService _apiService = ApiService();
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPuertos();
  }

  Future<void> _fetchPuertos() async {
    try {
      // CORRECCIÓN: El nombre correcto de la función es getPuertos()
      final List<dynamic> puertosData = await _apiService.getPuertos();
      final List<Marker> loadedMarkers = [];

      for (var puerto in puertosData) {
        if (puerto['LATITUD'] != null && puerto['LONGITUD'] != null) {
          loadedMarkers.add(
            Marker(
              point: LatLng(puerto['LATITUD'], puerto['LONGITUD']),
              width: 80,
              height: 80,
              child: Tooltip(
                message: puerto['NOMBRE_PUERTO'] ?? 'Puerto sin nombre',
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _markers = loadedMarkers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Puertos Globales'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(8.9, -79.5), // Centrado en Panamá
                initialZoom: 7.0, 
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nvdp',
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
    );
  }
}