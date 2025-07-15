import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl =
      "http://localhost:3000";

  // --- LOGIN ---
  Future<Map<String, dynamic>?> login(
    String nombreUsuario,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_usuario': nombreUsuario, 'password': password}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  // --- BARCOS (CON PAGINACIÓN) ---
  Future<Map<String, dynamic>> getBarcosPaginado({
    int page = 1,
    String search = '',
  }) async {
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

  Future<Map<String, dynamic>?> addBarco(Map<String, dynamic> barcoData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/barcos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(barcoData),
    );
    if (response.statusCode == 201) {
      // Devolvemos el cuerpo de la respuesta que contiene el nuevo ID
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> deleteBarco(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/barcos/$id'));
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Error al eliminar',
      );
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

  Future<List<dynamic>> getPuertos() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/puertos'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar los puertos');
    }
  }

  // --- Funciones para TRIPULANTES ---
  Future<List<dynamic>> getTripulantes() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/tripulantes'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar la tripulación');
    }
  }

  Future<void> deleteTripulante(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/tripulantes/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Fallo al eliminar el tripulante');
    }
  }

  // --- Funciones para USUARIOS ---
  Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/usuarios'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar los usuarios');
    }
  }

  Future<void> deleteUsuario(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/usuarios/$id'));
    if (response.statusCode != 200) {
      throw Exception('Fallo al eliminar el usuario');
    }
  }

  // Función para crear un nuevo usuario
  Future<bool> addUsuario(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return response.statusCode == 201;
  }

Future<bool> updateTripulante(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/tripulantes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

Future<bool> addTripulante(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/tripulantes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    // 201 Created es el código para una creación exitosa
    return response.statusCode == 201;
  }

// --- Funciones para FACTURAS ---
  Future<List<dynamic>> getFacturas() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/facturas'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar las facturas');
    }
  }

  Future<List<dynamic>> getDetallesFactura(int facturaId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/facturas/$facturaId/detalles'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar los detalles de la factura');
    }
  }


// --- Funciones para PETICIONES ---
  Future<List<dynamic>> getPeticionesPorBarco(int barcoId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/peticiones/barco/$barcoId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar las peticiones');
    }
  }

  Future<bool> addPeticion(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/peticiones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }


}
