import 'package:flutter/material.dart';
import 'config.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
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

class NvdpaApp extends StatefulWidget {
  const NvdpaApp({super.key});

  @override
  State<NvdpaApp> createState() => _NvdpaAppState();
}

class _NvdpaAppState extends State<NvdpaApp> {
  @override
  void initState() {
    super.initState();
    _simulateAdminLogin();
  }

  void _simulateAdminLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
         final Map<String, dynamic> mockAdminUserData = {
      "message": "Login simulado para desarrollo",
      "user": {
        "ID_USUARIO": 1,
        "NOMBRE_USUARIO": "admin",
        "ROL": "administrador"
      }
    };
      
      authService.login(mockAdminUserData as String);
    });
  }

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
      home: const EscalasScreen(),
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
  bool _isLoadingEscalas = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEscalas();
  }

  Future<void> _fetchEscalas() async {
    // NOTA: Asegúrate que esta ruta exista en tu API de Node.js
    const url = '$apiBaseUrl/api/escalas'; 
    try {
      final response = await http.get(Uri.parse(url));
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _escalas = jsonDecode(response.body);
            _isLoadingEscalas = false;
          });
        } else {
          throw Exception('Fallo al cargar las escalas. Código: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoadingEscalas = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Si los datos del usuario aún no están listos, muestra una pantalla de carga.
    if (authService.user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Iniciando sesión de administrador...'),
            ],
          ),
        ),
      );
    }
    
    // Una vez que los datos del usuario están listos, construimos el dashboard.
    final userDetails = authService.user!['user'];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text('Bienvenido, ${userDetails?['NOMBRE_USUARIO'] ?? 'Admin'}'),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingEscalas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar los datos:\n$_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    if (_escalas.isEmpty) {
      return const Center(child: Text('No hay escalas para mostrar.'));
    }
    return ListView.builder(
      itemCount: _escalas.length,
      itemBuilder: (context, index) {
        final escala = _escalas[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(Icons.anchor, color: Color(0xFF003366)),
            title: Text(escala['NOMBRE_BARCO'] ?? 'Sin nombre'),
            subtitle: Text(
              '${escala['NOMBRE_CLIENTE'] ?? 'N/A'} - Puerto: ${escala['NOMBRE_PUERTO'] ?? 'N/A'}',
            ),
            onTap: () {
              final barcoId = escala['ID_BARCO'];
              if (barcoId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        BarcoDetalleScreen(barcoId: barcoId),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}