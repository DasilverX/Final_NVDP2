import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "http://localhost:3000";

  String getBaseUrl() => _baseUrl;

  // =======================================================================
  // --- AUTENTICACIÓN ---
  // =======================================================================
  Future<Map<String, dynamic>?> login(String nombreUsuario, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_usuario': nombreUsuario, 'password': password}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  // =======================================================================
  // --- DASHBOARD Y REPORTES ---
  // =======================================================================
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/dashboard/summary'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar el resumen del dashboard');
  }

  Future<List<dynamic>> getFacturaAnalytics() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/analytics/facturas'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar la analítica de facturas');
  }

  Future<List<dynamic>> getReportePagosPorCliente() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/analytics/clientes-pagos'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar el reporte de clientes');
  }

  // =======================================================================
  // --- GESTIÓN (CRUDs) ---
  // =======================================================================

  // --- Barcos ---
  Future<Map<String, dynamic>> getBarcosPaginado({int page = 1, String search = ''}) async {
    final url = Uri.parse('$_baseUrl/api/barcos?page=$page&search=$search');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los barcos');
  }

  Future<Map<String, dynamic>> getBarcoById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/barcos/$id'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los detalles del barco');
  }
  
  Future<Map<String, dynamic>?> addBarco(Map<String, dynamic> barcoData) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/barcos'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(barcoData));
    if (response.statusCode == 201) return jsonDecode(response.body);
    return null;
  }

  Future<bool> updateBarco(int id, Map<String, dynamic> barcoData) async {
    final response = await http.put(Uri.parse('$_baseUrl/api/barcos/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(barcoData));
    return response.statusCode == 200;
  }

  Future<void> deleteBarco(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/barcos/$id'));
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)['error'] ?? 'Error al eliminar');
  }
  
  // --- Clientes ---
  Future<List<dynamic>> getClientes() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/clientes'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los clientes');
  }

  Future<bool> addCliente(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/clientes'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 201;
  }

  Future<bool> updateCliente(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$_baseUrl/api/clientes/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 200;
  }

  Future<void> deleteCliente(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/clientes/$id'));
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)['error'] ?? 'Fallo al eliminar el cliente');
  }

  // --- Tripulantes ---
  Future<List<dynamic>> getTripulantes() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/tripulantes'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar la tripulación');
  }

  Future<bool> addTripulante(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/tripulantes'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 201;
  }

  Future<bool> updateTripulante(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$_baseUrl/api/tripulantes/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 200;
  }

  Future<void> deleteTripulante(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/tripulantes/$id'));
    if (response.statusCode != 200) throw Exception('Fallo al eliminar el tripulante');
  }

  // --- Usuarios ---
  Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/usuarios'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los usuarios');
  }

  Future<bool> addUsuario(Map<String, dynamic> userData) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/usuarios'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(userData));
    return response.statusCode == 201;
  }

  Future<void> deleteUsuario(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/usuarios/$id'));
    if (response.statusCode != 200) throw Exception('Fallo al eliminar el usuario');
  }

  Future<bool> updateUsuario(int id, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/usuarios/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return response.statusCode == 200;
  }

  // =======================================================================
  // --- OPERACIONES (Facturas, Pagos, etc.) ---
  // =======================================================================
  Future<List<dynamic>> getFacturas() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/facturas'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar las facturas');
  }

  Future<List<dynamic>> getPagosSimulados() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/analytics/pagos-simulados'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar datos simulados');
  }


  Future<List<dynamic>> getFacturasPorBarco(int barcoId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/facturas/barco/$barcoId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar las facturas del barco');
  }

  Future<List<dynamic>> getDetallesFactura(int facturaId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/facturas/$facturaId/detalles'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los detalles de la factura');
  }

  Future<bool> addFactura(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/facturas'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 201;
  }

  Future<bool> updateFacturaStatus(int facturaId, String nuevoStatus) async {
    final response = await http.patch(Uri.parse('$_baseUrl/api/facturas/$facturaId/status'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'nuevoStatus': nuevoStatus}));
    return response.statusCode == 200;
  }

  Future<bool> realizarPago(int facturaId, double monto) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/pagos'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'id_factura': facturaId, 'monto_pagado': monto, 'id_metodo_pago': 1}));
    return response.statusCode == 201;
  }

  Future<List<dynamic>> getPeticionesPorBarco(int barcoId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/peticiones/barco/$barcoId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar las peticiones');
  }

  Future<bool> addPeticion(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/peticiones'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 201;
  }

  Future<bool> addDocumento(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/documentos'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return response.statusCode == 201;
  }

  // =======================================================================
  // --- LISTAS PARA DROPDOWNS ---
  // =======================================================================
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

  Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/roles'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Fallo al cargar los roles');
  }

  Future<List<dynamic>> getPuertos() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/puertos'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fallo al cargar los puertos');
    }
  }

  

}