import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  bool get isLoggedIn => _user != null;

  String? get userRole => _user?['rol'];

  void login(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners(); // Notificar a los widgets que el estado cambió
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}