import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart'; // Asegúrate de tener este archivo con tu apiBaseUrl

class ApiService {
  final String _baseUrl = apiBaseUrl; // Usamos la variable del config

  // --- LOGIN ---
  Future<Map<String, dynamic>?> login(String nombreUsuario, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_usuario': nombreUsuario, 'password': password}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  // --- BARCOS (CON PAGINACIÓN) ---
  Future<Map<String, dynamic>> getBarcosPaginado({int page = 1, String search = ''}) async {
    final url = Uri.parse('$_baseUrl/api/barcos?page=$page&search=$search');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los barcos');
  }

  Future<bool> updateBarco(int id, Map<String, dynamic> barcoData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/barcos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(barcoData),
    );
    return response.statusCode == 200;
  }
  
  Future<bool> addBarco(Map<String, dynamic> barcoData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/barcos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(barcoData),
    );
    return response.statusCode == 201;
  }

  Future<void> deleteBarco(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/barcos/$id'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error al eliminar');
    }
  }

  // --- ESCALAS ---
  Future<List<dynamic>> getEscalas() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/escalas'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar las escalas');
  }

 Future<Map<String, dynamic>> getBarcoById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/barcos/$id'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar los detalles del barco');
    }
  }

}