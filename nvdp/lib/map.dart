import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPuertos();
  }

  Future<void> _fetchPuertos() async {
    const url = '$apiBaseUrl/api/puertos';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> puertosData = jsonDecode(response.body);
        final List<Marker> loadedMarkers = [];
        for (var puerto in puertosData) {
          loadedMarkers.add(
            Marker(
              point: LatLng(puerto['LATITUD'], puerto['LONGITUD']),
              width: 80,
              height: 80,
              child: Tooltip(
                message: puerto['NOMBRE'],
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ),
          );
        }
        if (mounted) {
          setState(() {
            _markers = loadedMarkers;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Fallo al cargar los puertos');
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
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
                initialCenter: LatLng(20, 0), 
                initialZoom: 2.0, 
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