import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  String? get userRole => _user?['user']?['ROL'];
  
  // Getter para obtener el ID del barco del usuario si existe
  int? get userBarcoId => _user?['user']?['ID_BARCO'];

  void login(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  // --- FUNCIÓN NUEVA Y CORREGIDA ---
  // Esta función actualiza el mapa del usuario con el ID del nuevo barco.
  void updateUserBarcoId(int barcoId) {
    if (_user != null && _user!['user'] != null) {
      _user!['user']['ID_BARCO'] = barcoId;
      // Notificamos a los listeners para que la UI se actualice si es necesario.
      notifyListeners();
    }
  }
}