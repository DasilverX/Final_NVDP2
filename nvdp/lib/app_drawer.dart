// lib/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

// Importa todas tus pantallas
import 'main.dart'; 
import 'gestion_barcos.dart';
import 'tripulantes.dart';
import 'gestion_usuarios.dart';
import 'map.dart';
import 'contabilidad_screen.dart';
import 'reporte_clientes.dart';
import 'add_documento.dart';
import 'capitan_facturas.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: const Row(
              children: [
                Icon(Icons.directions_boat, size: 48, color: Colors.white),
                SizedBox(width: 16),
                Text('NVDPA', style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),

          // --- Común para todos ---
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio (Dashboard)'),
            onTap: () => _navigate(context, const DashboardScreen(), replace: true),
          ),

          // --- Sección de Logística y Admin ---
          if (authService.esAdmin || authService.esLogistica)
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Mapa de Puertos'),
              onTap: () => _navigate(context, const MapaScreen()),
            ),

          // --- Sección de Contabilidad y Admin ---
          if (authService.esAdmin || authService.esContador) ...[
            const Divider(),
            _buildSectionTitle(context, 'Finanzas'),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Contabilidad'),
              onTap: () => _navigate(context, const ContabilidadScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Reporte por Cliente'),
              onTap: () => _navigate(context, const ReporteClientesScreen()),
            ),
          ],
          
          // --- Sección solo para Capitán ---
          if (authService.esCapitan)
            ListTile(
              leading: const Icon(Icons.payment_outlined),
              title: const Text('Mis Facturas y Pagos'),
              onTap: () {
                final barcoId = authService.userData?['id_barco'];
                if (barcoId != null) {
                  _navigate(context, CapitanFacturasScreen(barcoId: barcoId));
                }
              },
            ),

          // --- Sección solo para Administradores ---
          if (authService.esAdmin) ...[
            const Divider(),
            _buildSectionTitle(context, 'Administración'),
            ListTile(
              leading: const Icon(Icons.sailing_outlined),
              title: const Text('Gestión de Barcos'),
              onTap: () => _navigate(context, const GestionBarcosScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Gestión de Tripulantes'),
              onTap: () => _navigate(context, const TripulantesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Gestión de Usuarios'),
              onTap: () => _navigate(context, const GestionUsuariosScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Añadir Documento'),
              onTap: () => _navigate(context, const AddDocumentoScreen()),
            ),
          ],
          
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

  // Helper para la navegación, ahora es un método privado de la clase
  void _navigate(BuildContext context, Widget screen, {bool replace = false}) {
    Navigator.of(context).pop();
    if (replace) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  // Helper para los títulos de sección
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}