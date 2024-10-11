// lib/presentation/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seguridad_vial_app/data/providers/zone_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final zoneProvider = Provider.of<ZoneProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
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
      body: zoneProvider.reports.isEmpty
          ? const Center(
              child: Text(
                'No hay reportes en el historial.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: zoneProvider.reports.length,
              itemBuilder: (context, index) {
                final report = zoneProvider.reports[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.report,
                      color: Colors.deepPurple,
                      size: 30,
                    ),
                    title: Text(
                      report.type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(report.description),
                    trailing: Text(
                      '${report.latitude}, ${report.longitude}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    onTap: () {
                      // Acción al tocar el reporte, por ejemplo, mostrar detalles
                    },
                  ),
                );
              },
            ),
    );
  }
}
