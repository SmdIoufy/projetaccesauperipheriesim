import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_code/sim_card_code.dart';

// Importation de nos classes UI séparées
import 'widgets/sim_cards.dart';
import 'widgets/device.dart';
import 'widgets/ui_components.dart';

void main() {
  runApp(const SimCardManagerApp());
}

class SimCardManagerApp extends StatelessWidget {
  const SimCardManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestionnaire SIM Complet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SimCardDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimCardDashboard extends StatefulWidget {
  const SimCardDashboard({super.key});

  @override
  State<SimCardDashboard> createState() => _SimCardDashboardState();
}

class _SimCardDashboardState extends State<SimCardDashboard> {
  // --- Index pour la navigation en footer ---
  int _currentIndex = 0;

  // --- Données d'état ---
  SimCardInfo? _basicSimInfo;
  List<SimCardInfo> _allSimInfo = [];
  NetworkInfo? _networkInfo;
  String? _deviceId;
  bool _hasSimCard = false;
  bool _isDualSim = false;
  int _simCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SimCardManager.clearCache();
    _loadAllInformation();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        await Permission.phone.request();
      }
    }
  }

  Future<void> _loadAllInformation() async {
    // N'affiche le loader plein écran que lors du tout premier chargement
    if (_allSimInfo.isEmpty && _errorMessage == null) {
      setState(() {
        _isLoading = true;
      });
    }

    await requestPermissions();

    try {
      final results = await Future.wait([
        SimCardManager.basicSimInfo,
        SimCardManager.allSimInfo,
        SimCardManager.networkInfo,
        SimCardManager.deviceId,
        SimCardManager.hasSimCard,
        SimCardManager.isDualSim,
        SimCardManager.simCount,
      ]);

      if (mounted) {
        setState(() {
          _basicSimInfo = results[0] as SimCardInfo?;
          _allSimInfo = results[1] as List<SimCardInfo>;
          _networkInfo = results[2] as NetworkInfo?;
          _deviceId = results[3] as String?;
          _hasSimCard = results[4] as bool;
          _isDualSim = results[5] as bool;
          _simCount = results[6] as int;

          _isLoading = false;
          _errorMessage = null; // Réinitialise l'erreur en cas de succès
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur :\n$e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Liste des écrans à afficher en fonction de l'onglet cliqué dans le footer
    final List<Widget> pages = [
      SimCardsTab(
        simCount: _simCount,
        hasSimCard: _hasSimCard,
        isDualSim: _isDualSim,
        allSimInfo: _allSimInfo,
        basicSimInfo: _basicSimInfo,
      ),
      DeviceTab(
        deviceId: _deviceId,
        simCount: _simCount,
        isDualSim: _isDualSim,
        hasSimCard: _hasSimCard,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyseur SIM Expert'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllInformation,
            tooltip: 'Actualiser',
          ),
        ],
      ),

      // On affiche le loader, l'erreur, ou le contenu avec le RefreshIndicator
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? ErrorDisplay(errorMessage: _errorMessage!, onRetry: _loadAllInformation)
          : RefreshIndicator(
        onRefresh: _loadAllInformation,
        child: pages[_currentIndex],
      ),

      // La barre de navigation en footer
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Change la page instantanément
          });
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed, // Permet de garder les icônes toujours bien visibles
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sim_card),
            label: 'Cartes SIM',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: 'Appareil',
          ),
        ],
      ),
    );
  }
}