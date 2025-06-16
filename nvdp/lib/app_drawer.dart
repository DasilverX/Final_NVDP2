import 'package:flutter/material.dart';
import 'package:nvdp/about.dart';
import 'package:nvdp/map.dart';
import 'gestion_barcos.dart';
import 'package:nvdp/login.dart';
import 'package:nvdp/tripulantes.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'analisis.dart';
import 'main.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aquí va tu logo
                Image.asset(
                  'assets/logo.png', // Asegúrate de que este nombre coincida con tu archivo
                  height: 60,
                  // Si hay un error al cargar el logo, muestra un icono de respaldo
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.directions_boat,
                      color: Colors.white,
                      size: 60,
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'NVDPA',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio (Escalas)'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const EscalasScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_boat),
            title: const Text('Gestión de Barcos'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GestionBarcosScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Mapa de Puertos'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MapaScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Análisis Logístico (IA)'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalisisScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gestión de Tripulantes'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TripulantesScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              // Cierra el drawer antes de navegar para que no se quede abierto
              Navigator.pop(context);
              // Navega a la nueva pantalla
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          const Divider(), // El divisor que ya tenías
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              // Limpiamos los datos del usuario
              Provider.of<AuthService>(context, listen: false).logout();
              // Navegamos a la pantalla de login y eliminamos todas las rutas anteriores
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
