import 'package:flutter/material.dart';
import 'ui_components.dart';

class DeviceTab extends StatelessWidget {
  final String? deviceId;
  final int simCount;
  final bool isDualSim;
  final bool hasSimCard;

  const DeviceTab({
    super.key,
    this.deviceId,
    required this.simCount,
    required this.isDualSim,
    required this.hasSimCard,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Indispensable pour que le Pull-to-Refresh fonctionne même avec peu de contenu
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.purple, size: 28),
                      SizedBox(width: 8),
                      Text('Matériel du Téléphone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Infos(label: 'Identifiant (IMEI)', value: deviceId ?? 'Accès refusé par Android'),
                  Infos(label: 'Nombre de Slots SIM', value: '$simCount emplacement(s) physique(s)'),
                  Infos(label: 'Compatible Dual SIM', value: isDualSim ? 'Oui' : 'Non'),
                  Infos(label: 'Puce(s) présente(s)', value: hasSimCard ? 'Oui' : 'Aucune puce insérée'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade700, size: 32),
                  const SizedBox(height: 12),
                  Text('Note sur la Sécurité Android', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  const SizedBox(height: 8),
                  const Text(
                    "Depuis Android 10, le numéro de téléphone et l'IMEI sont masqués aux applications tierces pour protéger la vie privée de l'utilisateur, même si toutes les permissions sont accordées.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}