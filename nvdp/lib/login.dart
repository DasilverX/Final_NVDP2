import 'package:flutter/material.dart';
import 'package:nvdp/registro_barco.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'main.dart'; // Importa EscalasScreen
import 'capitanes.dart'; // Importa CapitanDashboardScreen
// Importa la pantalla de registro
import 'config.dart'; // Importa la URL del API
import 'package:http/http.dart' as http; // Importa el paquete http
import 'dart:convert'; // Importa las herramientas de JSON

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/api/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': _nombreController.text,
            'password': _passwordController.text,
          }),
        );

        if (mounted) {
          if (response.statusCode == 200) {
            final userData = jsonDecode(response.body);
            authService.login(userData);
            _navigateByUserRole(authService);
          } else {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'Error desconocido');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _navigateByUserRole(AuthService authService) {
    final userRole = authService.user!['rol'];
    
    if (userRole == 'administrador' || userRole == 'visitante' || userRole == 'operador') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EscalasScreen()),
      );
    } else if (userRole == 'capitan') {
      final barcoId = authService.user!['barcoId'];
      final nombreCapitan = authService.user!['nombre'];
      
      if (barcoId == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistrarBarcoScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => CapitanDashboardScreen(
                  barcoId: barcoId, 
                  nombreCapitan: nombreCapitan
              )
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo_nvdp.png', height: 120, errorBuilder: (c, e, s) => const Icon(Icons.directions_boat, size: 120)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Iniciar Sesión'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}