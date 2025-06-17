import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos el tema que ya definimos para que los estilos de texto sean consistentes
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de NVDPA'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/logo_nvdp.png', height: 120),
              const SizedBox(height: 24),
              Text(
                'NVDPA',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistema de Gestión para Agencia Naviera',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Versión 1.0.0',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 40),
              Text(
                'Desarrollado por:',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'El mas bello',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}