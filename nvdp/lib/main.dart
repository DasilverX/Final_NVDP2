import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Importamos el paquete de gráficas

import 'auth_service.dart';
import 'login.dart';
import 'app_drawer.dart';
import 'api_service.dart';
import 'gestion_barcos.dart';
import 'tripulantes.dart';
import 'contabilidad_screen.dart';
import 'gestion_usuarios.dart';
import 'map.dart';


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
      textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366), brightness: Brightness.light),
      cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF003366), foregroundColor: Colors.white, elevation: 2),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFf9a825)),
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
    if (authService.userData != null) {
      return const DashboardScreen();
    } else {
      return LoginScreen();
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  // Este Future ahora cargará ambos datos a la vez
  late Future<List<dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    // Usamos Future.wait para ejecutar ambas llamadas al API en paralelo
    _dashboardDataFuture = Future.wait([
      _apiService.getDashboardSummary(),
      _apiService.getFacturaAnalytics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AuthService>(context).userName;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text('Dashboard: ${userName ?? 'Usuario'}')),
      body: FutureBuilder<List<dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          
          // Extraemos los resultados de las dos llamadas al API
          final summary = snapshot.data?[0] as Map<String, dynamic>? ?? {};
          final chartData = snapshot.data?[1] as List<dynamic>? ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Análisis de Facturación', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: chartData.isEmpty 
                    ? const Center(child: Text('No hay datos para la gráfica.'))
                    : PieChart(_buildPieChartData(chartData)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Accesos Rápidos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: <Widget>[
                  _buildSummaryCard(context, title: 'Barcos', value: (summary['TOTALBARCOS'] ?? 0).toString(), icon: Icons.directions_boat, color: Colors.blue, onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GestionBarcosScreen()));
                  }),
                  _buildSummaryCard(context, title: 'Tripulantes', value: (summary['TOTALTRIPULANTES'] ?? 0).toString(), icon: Icons.people, color: Colors.green, onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TripulantesScreen()));
                  }),
                  _buildSummaryCard(context, title: 'Facturas', value: (summary['FACTURASPENDIENTES'] ?? 0).toString(), icon: Icons.receipt, color: Colors.orange, onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ContabilidadScreen()));
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Widget para construir las tarjetas de resumen (más pequeñas)
  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  // Función para construir los datos de la gráfica de pastel
  PieChartData _buildPieChartData(List<dynamic> chartData) {
    final Map<String, Color> statusColors = {
      'Pagado': Colors.green,
      'Pendiente': Colors.orange,
      'Borrador': Colors.blueGrey,
      'Cancelado': Colors.red,
    };

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: chartData.map((data) {
        final status = data['ESTADO_FACTURA'] as String;
        final total = (data['TOTAL'] as num).toDouble();
        
        return PieChartSectionData(
          color: statusColors[status] ?? Colors.grey,
          value: total,
          title: '${total.toInt()}',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
    );
  }
}