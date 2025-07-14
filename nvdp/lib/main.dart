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
    final theme = ThemeData(
      textTheme: GoogleFonts.latoTextTheme(
        Theme.of(context).textTheme,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF003366),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003366), 
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFf9a825),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'NVDPA',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}


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
      drawer: const AppDrawer(),
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

                      // ***** DEPURACIÓN *****
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
