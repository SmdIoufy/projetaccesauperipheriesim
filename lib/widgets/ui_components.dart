import 'package:flutter/material.dart';

// Widget pour afficher une ligne d'information (Clé : Valeur)
class Infos extends StatelessWidget {
  final String label;
  final String value;

  const Infos({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}



// Widget pour afficher un bel écran d'erreur
class ErrorDisplay extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorDisplay({super.key, required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de lecture', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}