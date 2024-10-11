// lib/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seguridad_vial_app/data/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            secondary: const Icon(Icons.dark_mode),
            value:
                false, // Aquí podrías conectar con un provider para manejar el tema
            onChanged: (bool value) {
              // Acción para cambiar el tema
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navegar a configuración de notificaciones
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar Contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navegar a pantalla de cambio de contraseña
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Cuenta'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navegar a pantalla de cuenta
            },
          ),
        ],
      ),
    );
  }
}
