import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  bool get isLoggedIn => _user != null;

  String? get userRole => _user?['rol'];

  void login(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  // ***** NUEVA FUNCIÓN AÑADIDA AQUÍ *****
  void updateUserBarcoId(int barcoId) {
    if (_user != null) {
      // Creamos una nueva copia del mapa y actualizamos el barcoId
      final newUserMap = Map<String, dynamic>.from(_user!);
      newUserMap['barcoId'] = barcoId;
      _user = newUserMap;
      
      notifyListeners(); // Notificamos a la app del cambio
    }
  }
}