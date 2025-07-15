// lib/main.dart

import 'package:flutter/material.dart';
import 'package:nvdp/contabilidad_screen.dart';
import 'package:nvdp/tripulantes.dart';
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // CORRECCIÓN: Usamos .userData en lugar de .user
    if (authService.userData != null) {
      return const EscalasScreen();
    } else {
      return LoginScreen();
    }
  }
}

class EscalasScreen extends StatefulWidget { // Le mantenemos el nombre por ahora
  const EscalasScreen({super.key});

  @override
  State<EscalasScreen> createState() => _EscalasScreenState();
}

class _EscalasScreenState extends State<EscalasScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _apiService.getDashboardSummary();
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AuthService>(context).userName;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text('Dashboard: ${userName ?? 'Usuario'}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No hay datos para mostrar.'));
          }

          final summary = snapshot.data!;

          // Creamos el grid con las tarjetas de resumen
          return GridView.count(
            crossAxisCount: 2, // 2 columnas
            padding: const EdgeInsets.all(16.0),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: <Widget>[
              _buildSummaryCard(
                context,
                title: 'Barcos Registrados',
                value: summary['TOTALBARCOS'].toString(),
                icon: Icons.directions_boat,
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GestionBarcosScreen()));
                }
              ),
              _buildSummaryCard(
                context,
                title: 'Tripulantes Activos',
                value: summary['TOTALTRIPULANTES'].toString(),
                icon: Icons.people,
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TripulantesScreen()));
                }
              ),
              _buildSummaryCard(
                context,
                title: 'Facturas Pendientes',
                value: summary['FACTURASPENDIENTES'].toString(),
                icon: Icons.receipt,
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ContabilidadScreen()));
                }
              ),
              // Puedes añadir más tarjetas aquí
            ],
          );
        },
      ),
    );
  }

  // Widget auxiliar para crear las tarjetas del dashboard
  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}