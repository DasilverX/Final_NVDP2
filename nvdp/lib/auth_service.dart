// lib/auth_service.dart

import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  String? get userRole {
    if (_userData == null) return null;
    switch (_userData!['id_rol']) {
      case 1:
        return 'administrador';
      case 2:
        return 'capitan';
      case 3:
        return 'operador';
      default:
        return 'visitante';
    }
  }

  String? get userName => _userData?['nombre_usuario'];

  void login(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void logout() {
    _userData = null;
    notifyListeners();
  }


  void updateUserBarcoId(int barcoId) {
    if (_userData != null) {
      _userData!['id_barco'] = barcoId;
      notifyListeners();
    }
  }
}