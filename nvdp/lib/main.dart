import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'auth_service.dart';
import 'login.dart';
import 'app_drawer.dart';
import 'api_service.dart';
import 'gestion_barcos.dart';
import 'tripulantes.dart';
import 'contabilidad_screen.dart';
import 'gestion_usuarios.dart'; // Ahora este import sí se usa

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
      cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),),
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
  late Future<List<dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = Future.wait([
      _apiService.getDashboardSummary(),
      _apiService.getPagosSimulados(),
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
          
          final summary = snapshot.data?[0] as Map<String, dynamic>? ?? {};
          final chartData = snapshot.data?[1] as List<dynamic>? ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Facturación Pagada', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                child: Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: chartData.isEmpty 
                    ? const Center(child: Text('No hay datos para la gráfica.'))
                    : BarChart(_buildBarChartData(chartData)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Accesos Rápidos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              GridView.count(
                // Ajustamos a 2 columnas para que quepan 4 tarjetas de forma balanceada
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2, // Ajustamos la proporción
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
                  // --- TARJETA AÑADIDA ---
                  _buildSummaryCard(
                    context,
                    title: 'Usuarios',
                    value: 'Gestionar',
                    icon: Icons.manage_accounts,
                    color: Colors.grey,
                    onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const GestionUsuariosScreen()));
                    }
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
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

  BarChartData _buildBarChartData(List<dynamic> chartData) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 50000,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(chartData[value.toInt()]['MES'], style: const TextStyle(fontSize: 12)));
            },
            reservedSize: 32,
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: chartData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return BarChartGroupData(x: index, barRods: [ BarChartRodData(toY: (data['MONTO'] as num).toDouble(), color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(4))]);
      }).toList(),
      gridData: const FlGridData(show: false),
    );
  }
}