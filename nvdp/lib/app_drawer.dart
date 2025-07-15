import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'login.dart';
import 'main.dart';
import 'gestion_barcos.dart';
import 'tripulantes.dart';
import 'map.dart';
import 'analisis.dart';
import 'about.dart';
import 'gestion_usuarios.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // ***** LÓGICA DE ROLES *****
    // Obtenemos el servicio de autenticación para saber el rol del usuario
    final authService = Provider.of<AuthService>(context, listen: false);
    final esAdmin = authService.userRole == 'administrador';

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
                Image.asset(
                  'assets/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.directions_boat, color: Colors.white, size: 60);
                  },
                ),
                const SizedBox(height: 10),
                const Text('NVDPA', style: TextStyle(color: Colors.white, fontSize: 24)),
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
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GestionBarcosScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gestión de Tripulantes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TripulantesScreen()),
              );
            },
          ),
          // ***** NUEVA SECCIÓN AÑADIDA *****
          if (esAdmin)
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Gestión de Usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GestionUsuariosScreen()),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Mapa de Puertos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MapaScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Análisis Logístico (IA)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalisisScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}