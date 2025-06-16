import 'package:flutter/material.dart';
import 'config.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'login.dart';
import 'tripulantes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'barco_detalle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_drawer.dart';

void main() {
  runApp(
    // Envolvemos la app con el ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const NvdpaApp(),
    ),
  );
}

class NvdpaApp extends StatelessWidget {
  const NvdpaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos nuestro tema personalizado aquí
    final theme = ThemeData(
      // Usamos la fuente 'Lato' para todo el texto de la app
      textTheme: GoogleFonts.latoTextTheme(
        Theme.of(context).textTheme,
      ),
      // Definimos la paleta de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF003366), // Un azul marino como color principal
        brightness: Brightness.light,
      ),
      // Personalizamos la apariencia de las tarjetas
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      // Personalizamos la barra de navegación
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003366), // Azul marino
        foregroundColor: Colors.white, // Texto e iconos en blanco
        elevation: 4,
      ),
      // Personalizamos los botones flotantes
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFf9a825), // Un color de acento, como un dorado/amarillo
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'NVDPA',
      theme: theme, // Aplicamos nuestro tema personalizado
      debugShowCheckedModeBanner: false, // Ocultamos la cinta de "Debug"
      home: const LoginScreen(),
    );
  }
}


// El código de EscalasScreen (la pantalla principal) se queda igual que antes
class EscalasScreen extends StatefulWidget {
  const EscalasScreen({super.key});

  @override
  State<EscalasScreen> createState() => _EscalasScreenState();
}

class _EscalasScreenState extends State<EscalasScreen> {
  List _escalas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEscalas();
  }

  Future<void> _fetchEscalas() async {
    const url = '$apiBaseUrl/api/escalas';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _escalas = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar las escalas');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el rol del usuario para mostrar su nombre
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      drawer: const AppDrawer(), // 1. Añadimos el menú lateral
      appBar: AppBar(
        title: Text('Bienvenido, ${user?['nombre'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Gestionar Tripulantes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TripulantesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
              itemCount: _escalas.length,
              itemBuilder: (context, index) {
                final escala = _escalas[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.anchor),
                    title: Text(escala['NOMBREBARCO'] ?? 'Sin nombre'),
                    subtitle: Text(
                      '${escala['NOMBRECLIENTE']} - Puerto: ${escala['NOMBREPUERTO']}',
                    ),
                    onTap: () {
                      final barcoId = escala['BARCOID'];

                      // ***** PASO DE DEPURACIÓN *****
                      // Imprimimos en la consola para ver qué estamos recibiendo.
                      print(
                        'Se ha tocado una tarjeta. Intentando navegar al Barco ID: $barcoId',
                      );

                      if (barcoId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                BarcoDetalleScreen(barcoId: barcoId),
                          ),
                        );
                      } else {
                        // Si el ID es nulo, lo sabremos.
                        print(
                          'Navegación cancelada porque el BarcoID es nulo.',
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
