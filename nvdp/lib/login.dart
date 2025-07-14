import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'main.dart'; // Importa EscalasScreen
import 'capitanes.dart'; // Importa CapitanDashboardScreen
import 'registro_barco.dart'; // Importa la pantalla de registro de barco

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

  // ***** FUNCIÓN DE LOGIN SIMPLIFICADA *****
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Llamamos al nuevo método de login en nuestro servicio
      await authService.login(
        _nombreController.text,
        _passwordController.text,
      );

      // Si el login fue exitoso (no lanzó excepción), navegamos
      if (mounted) {
        _navigateByUserRole(authService);
      }

    } catch (e) {
      // Si el servicio lanzó una excepción, la mostramos aquí
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByUserRole(AuthService authService) {
    final role = authService.userRole;
    
    if (role == 'administrador' || role == 'visitante' || role == 'operador') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EscalasScreen()),
      );
    } else if (role == 'capitan') {
      final user = authService.user!['user'];
      final barcoId = user['BARCOID'];
      final nombreCapitan = user['NOMBRE'];

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
                Image.asset('assets/logo.png', height: 120, errorBuilder: (c, e, s) => const Icon(Icons.directions_boat, size: 120)),
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