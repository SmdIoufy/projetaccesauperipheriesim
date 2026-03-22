import 'package:flutter/material.dart';

import '../screens/sim_card_dashboard.dart';

class SimCardManagerApp extends StatelessWidget {
  const SimCardManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestionnaire SIM Complet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF0E5A8A),
        ),
        useMaterial3: true,
      ),
      home: const SimCardDashboard(),
    );
  }
}
