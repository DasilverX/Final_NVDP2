// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';
import 'login.dart';
import 'app_drawer.dart';
import 'api_service.dart';
import 'barco_detalle.dart';
import 'gestion_barcos.dart';

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
       textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme,),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366), brightness: Brightness.light,),
      cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),),),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF003366), foregroundColor: Colors.white, elevation: 4,),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFf9a825),),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'NVDPA',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

// Este Widget decide qué pantalla mostrar basado en el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Si hay un usuario, muestra el Dashboard. Si no, muestra la pantalla de Login.
    if (authService.user != null) {
      return const EscalasScreen();
    } else {
      return LoginScreen();
    }
  }
}

// Esta es tu pantalla principal o Dashboard
class EscalasScreen extends StatefulWidget {
  const EscalasScreen({super.key});

  @override
  State<EscalasScreen> createState() => _EscalasScreenState();
}

class _EscalasScreenState extends State<EscalasScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _escalasFuture;

  @override
  void initState() {
    super.initState();
    _escalasFuture = _apiService.getEscalas();
  }

  Future<void> _refreshEscalas() async {
    setState(() {
      _escalasFuture = _apiService.getEscalas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = Provider.of<AuthService>(context).user!['user'];

    return Scaffold(
      drawer: const AppDrawer(), // Asegúrate que tu AppDrawer funcione correctamente
      appBar: AppBar(
        title: Text('Dashboard: ${userDetails?['NOMBRE_USUARIO'] ?? 'Admin'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_boat),
            tooltip: 'Gestionar Barcos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GestionBarcosScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEscalas,
        child: FutureBuilder<List<dynamic>>(
          future: _escalasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay escalas para mostrar.'));
            }

            final escalas = snapshot.data!;
            return ListView.builder(
              itemCount: escalas.length,
              itemBuilder: (context, index) {
                final escala = escalas[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.anchor, color: Color(0xFF003366)),
                    title: Text(escala['NOMBRE_BARCO'] ?? 'Sin nombre'),
                    subtitle: Text(
                      'Cliente: ${escala['NOMBRE_CLIENTE'] ?? 'N/A'}\nPuerto: ${escala['NOMBRE_PUERTO'] ?? 'N/A'}',
                    ),
                    isThreeLine: true,
                    onTap: () {
                      final barcoId = escala['ID_BARCO'];
                      if (barcoId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BarcoDetalleScreen(barcoId: barcoId),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}