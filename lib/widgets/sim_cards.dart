import 'package:flutter/material.dart';
import 'package:sim_card_code/sim_card_code.dart';
import 'ui_components.dart';

class SimCardsTab extends StatelessWidget {
  final int simCount;
  final bool hasSimCard;
  final bool isDualSim;
  final List<SimCardInfo> allSimInfo;
  final SimCardInfo? basicSimInfo;

  const SimCardsTab({
    super.key,
    required this.simCount,
    required this.hasSimCard,
    required this.isDualSim,
    required this.allSimInfo,
    this.basicSimInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Indispensable pour que le Pull-to-Refresh fonctionne même avec peu de contenu
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          if (hasSimCard) ...[
            if (allSimInfo.isNotEmpty)
              ...allSimInfo.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildSimCardDetails(entry.value, entry.key),
              ))
            else if (basicSimInfo != null)
              _buildSimCardDetails(basicSimInfo!, 0)
            else
              const Center(child: Text("Cartes détectées, mais aucune info lisible.")),
          ] else
            _buildNoSimCard(),
        ],
      ),
    );
  }

  Widget _buildSimCardDetails(SimCardInfo simInfo, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sim_card, color: index == 0 ? Colors.blue : Colors.green, size: 28),
                const SizedBox(width: 10),
                Text('SIM ${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, thickness: 1.5),
            Infos(label: 'Emplacement (Slot)', value: simInfo.slotIndex?.toString() ?? 'Inconnu'),
            Infos(label: 'Opérateur', value: simInfo.operatorName ?? 'Non défini'),
            Infos(label: 'Code Opérateur', value: simInfo.operatorCode ?? 'Non défini'),
            Infos(label: 'Code Pays', value: simInfo.countryCode?.toUpperCase() ?? 'Non défini'),
            Infos(label: 'Numéro de Tél', value: (simInfo.phoneNumber == null || simInfo.phoneNumber!.isEmpty) ? 'Indisponible' : simInfo.phoneNumber!),
            Infos(label: 'N° de Série (ICCID)', value: (simInfo.serialNumber == null || simInfo.serialNumber!.isEmpty) ? 'Bloqué par sécurité' : simInfo.serialNumber!),
            Infos(label: 'État de la puce', value: simInfo.simState?.name.toUpperCase() ?? 'Inconnu'),
            Infos(label: 'Itinérance (Roaming)', value: simInfo.isRoaming == true ? 'Oui (Actif)' : 'Non'),
            Infos(label: 'Format eSIM', value: simInfo.isEsim == true ? 'Oui (Virtuelle)' : 'Non (Physique)'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSimCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.sim_card_alert, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune carte SIM détectée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Veuillez insérer une puce pour lire les données.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}