// lib/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'main.dart'; // Contiene DashboardScreen
import 'gestion_barcos.dart';
import 'tripulantes.dart';
import 'gestion_usuarios.dart';
import 'map.dart';
import 'contabilidad_screen.dart';
import 'add_documento.dart';
import 'gestion_clientes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos los nuevos getters para una lógica más clara
    final authService = Provider.of<AuthService>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Row(
              children: [
                Icon(Icons.directions_boat, size: 48, color: Colors.white),
                SizedBox(width: 16),
                Text(
                  'NVDPA',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio (Dashboard)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
          ),

          // --- SECCIÓN SOLO PARA ADMINISTRADORES ---
          if (authService.esAdmin) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Administración',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sailing_outlined),
              title: const Text('Gestión de Barcos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestionBarcosScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Gestión de Tripulantes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripulantesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Gestión de Usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestionUsuariosScreen(),
                  ),
                );
              },
            ),
          ],

          // --- SECCIÓN PARA ADMIN Y OTROS ROLES ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Contabilidad'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContabilidadScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_page_outlined),
            title: const Text('Gestión de Clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestionClientesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Añadir Documento'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDocumentoScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Mapa de Puertos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapaScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.of(context).pop();
              authService.logout();
            },
          ),
        ],
      ),
    );
  }
}
