import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nvdp/registro_barco.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'main.dart'; // Importamos main para navegar a EscalasScreen
import 'capitanes.dart';
import 'config.dart';

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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      const url = '$apiBaseUrl/api/login';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': _nombreController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          // Usamos Provider para guardar los datos del usuario logueado
          Provider.of<AuthService>(context, listen: false).login(userData);

          // Navegamos a la pantalla principal y quitamos la de login del historial
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const EscalasScreen()),
          );
        }
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          // Guardamos los datos del usuario en nuestro servicio de autenticación
          Provider.of<AuthService>(context, listen: false).login(userData);

          // ***** LÓGICA DE REDIRECCIÓN POR ROL *****
          if (userData['rol'] == 'capitan') {
            // Si es capitán y su barco es nulo, vamos a la pantalla de registro.
            if (userData['barcoId'] == null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const RegistrarBarcoScreen(),
                ),
              );
            } else {
              // Si es capitán CON barco, vamos a su dashboard normal.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CapitanDashboardScreen(
                    // <-- 'const' ELIMINADO
                    barcoId: userData['barcoId'],
                    nombreCapitan: userData['nombre'],
                  ),
                ),
              );
            }
          } else {
            // Si es admin o visitante, vamos a la pantalla principal de siempre
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const EscalasScreen()),
            );
          }
        } else {
          final responseBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${responseBody['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NVDPA - Inicio de Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ***** LOGO AÑADIDO AQUÍ *****
                Image.asset(
                  'assets/logo_nvdp.png', // Asegúrate que el nombre del archivo sea correcto
                  height: 120, // Ajusta el tamaño como prefieras
                  errorBuilder: (context, error, stackTrace) {
                    // Muestra un icono si el logo no carga
                    return const Icon(Icons.directions_boat, size: 120);
                  },
                ),
                const SizedBox(
                  height: 24,
                ), // Un espacio entre el logo y el formulario
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese su usuario' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese su contraseña' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                        ),
                        onPressed: _login,
                        child: const Text('Ingresar'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
