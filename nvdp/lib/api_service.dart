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

// --- Funciones para ROLES ---
  Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/roles'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar los roles');
    }
  }

  // --- Función para el Dashboard ---
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/dashboard/summary'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar el resumen del dashboard');
    }
  }

 Future<List<dynamic>> getFacturaAnalytics() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/analytics/facturas'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar la analítica de facturas');
    }
  }

// En lib/api_service.dart, dentro de la clase ApiService

  Future<bool> updateFacturaStatus(int facturaId, String nuevoStatus) async {
    final response = await http.patch( // Usamos PATCH porque solo actualizamos un campo
      Uri.parse('$_baseUrl/api/facturas/$facturaId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nuevoStatus': nuevoStatus}),
    );
    return response.statusCode == 200;
  }


    // --- Función para DOCUMENTOS ---
  Future<bool> addDocumento(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/documentos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }


// --- Funciones para CLIENTES ---
  Future<List<dynamic>> getClientes() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/clientes'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los clientes');
  }

  Future<bool> addCliente(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateCliente(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/clientes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<void> deleteCliente(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/clientes/$id'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Fallo al eliminar el cliente');
    }
  }

  Future<bool> addFactura(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/facturas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  // --- Función para REPORTES ---
  Future<List<dynamic>> getReportePagosPorCliente() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/analytics/clientes-pagos'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar el reporte de clientes');
    }
  }

  // --- Funciones para obtener listas para Dropdowns ---
  Future<List<dynamic>> getPaises() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/paises'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los países');
  }

  Future<List<dynamic>> getTiposDeBarco() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/tipos-barco'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los tipos de barco');
  }

 Future<List<dynamic>> getFacturasPorBarco(int barcoId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/facturas/barco/$barcoId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar las facturas del barco');
  }

  Future<bool> realizarPago(int facturaId, double monto) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/pagos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_factura': facturaId,
        'monto_pagado': monto,
        'id_metodo_pago': 1, // Usamos 1 (Transferencia) como default
      }),
    );
    return response.statusCode == 201;
  }


}
