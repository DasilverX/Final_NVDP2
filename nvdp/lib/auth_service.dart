import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart'; // Importamos la URL base de la API

class AuthService with ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token; // Opcional: para guardar un token JWT en el futuro

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null;
  String? get userRole {
    if (_user == null || _user!['user'] == null) return null;
    return _user!['user']['ROL'].toString().toLowerCase(); // Aseguramos que el rol venga en minúsculas
  }

  // ***** MÉTODO DE LOGIN ACTUALIZADO *****
  // Ahora toma el usuario y contraseña, y devuelve si tuvo éxito.
  Future<void> login(String nombre, String password) async {
    final url = Uri.parse('$apiBaseUrl/api/auth/login'); // Usamos la URL del archivo de config

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'nombre': nombre, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Si el login es exitoso, guardamos los datos del usuario
        _user = jsonDecode(response.body);
        
        // Opcional: si tu API devuelve un token, guárdalo aquí
        // _token = _user!['token'];
        
        notifyListeners(); // Notificamos a los widgets que el estado cambió
      } else {
        // Si el servidor devuelve un error, lo lanzamos para que la UI lo atrape
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error de autenticación');
      }
    } catch (e) {
      // Relanzamos la excepción para que la UI pueda mostrar un mensaje
      throw Exception('No se pudo conectar al servidor. Revisa tu conexión.');
    }
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }

  void updateUserBarcoId(int barcoId) {
    if (_user != null && _user!['user'] != null) {
      final newUserMap = Map<String, dynamic>.from(_user!);
      newUserMap['user']['BARCOID'] = barcoId; // Asumiendo que el campo se llama BARCOID
      _user = newUserMap;
      notifyListeners();
    }
  }
}