import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sim_card_code/sim_card_code.dart';

import '../widgets/contacts_tab.dart';
import '../widgets/device.dart';
import '../widgets/sim_cards.dart';
import '../widgets/ui_components.dart';

class SimCardDashboard extends StatefulWidget {
  const SimCardDashboard({super.key});

  @override
  State<SimCardDashboard> createState() => _SimCardDashboardState();
}

class _SimCardDashboardState extends State<SimCardDashboard> {
  int _currentIndex = 0;

  SimCardInfo? _basicSimInfo;
  List<SimCardInfo> _allSimInfo = [];
  String? _deviceId;
  bool _hasSimCard = false;
  bool _isDualSim = false;
  int _simCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  PermissionStatus? _permissionStatus;
  bool _isRequesting = false;
  bool _isLoadingContacts = false;
  List<Contact> _contacts = <Contact>[];
  String? _contactsError;

  @override
  void initState() {
    super.initState();
    SimCardManager.clearCache();
    _loadAllInformation();
    _refreshPermissionStatus();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await ph.Permission.phone.status;
      if (!status.isGranted) {
        await ph.Permission.phone.request();
      }
    }
  }

  Future<void> _loadAllInformation() async {
    if (_allSimInfo.isEmpty && _errorMessage == null) {
      setState(() => _isLoading = true);
    }

    await requestPermissions();

    try {
      final results = await Future.wait([
        SimCardManager.basicSimInfo,
        SimCardManager.allSimInfo,
        SimCardManager.deviceId,
        SimCardManager.hasSimCard,
        SimCardManager.isDualSim,
        SimCardManager.simCount,
      ]);

      if (!mounted) return;
      setState(() {
        _basicSimInfo = results[0] as SimCardInfo?;
        _allSimInfo = results[1] as List<SimCardInfo>;
        _deviceId = results[2] as String?;
        _hasSimCard = results[3] as bool;
        _isDualSim = results[4] as bool;
        _simCount = results[5] as int;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur :\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPermissionStatus() async {
    final PermissionStatus status = await FlutterContacts.permissions.check(
      PermissionType.read,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionStatus = status;
    });

    if (_canReadContacts(status)) {
      await _loadContacts();
    } else {
      setState(() {
        _contacts = <Contact>[];
      });
    }
  }

  Future<void> _requestContactsPermission() async {
    setState(() {
      _isRequesting = true;
    });

    final PermissionStatus status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = status;
      _isRequesting = false;
    });

    if (_canReadContacts(status)) {
      await _loadContacts();
    } else {
      setState(() {
        _contacts = <Contact>[];
      });
    }
  }

  bool _canReadContacts(PermissionStatus? status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  Future<void> _loadContacts() async {
    if (!_canReadContacts(_permissionStatus)) {
      return;
    }

    setState(() {
      _isLoadingContacts = true;
      _contactsError = null;
    });

    try {
      final List<Contact> contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      contacts.sort(
        (a, b) => (a.displayName ?? '').toLowerCase().compareTo(
          (b.displayName ?? '').toLowerCase(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _contacts = contacts;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _contactsError =
            'Impossible de lire les contacts pour le moment. Reessaie.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
        });
      }
    }
  }

  String _statusLabel(PermissionStatus? status) {
    return switch (status) {
      PermissionStatus.granted => 'Acces autorise',
      PermissionStatus.limited => 'Acces limite',
      PermissionStatus.denied => 'Acces refuse (reessayable)',
      PermissionStatus.permanentlyDenied =>
        'Acces refuse definitivement (ouvrir les parametres)',
      PermissionStatus.restricted => 'Acces restreint par le systeme',
      PermissionStatus.notDetermined => 'Permission non demandee',
      null => 'Verification en cours...',
    };
  }

  Color _statusColor(PermissionStatus? status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited => const Color(0xFF166534),
      PermissionStatus.denied ||
      PermissionStatus.notDetermined => const Color(0xFF92400E),
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted => const Color(0xFF991B1B),
      null => const Color(0xFF0F172A),
    };
  }

  Color _statusBgColor(PermissionStatus? status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited => const Color(0xFFD1FAE5),
      PermissionStatus.denied ||
      PermissionStatus.notDetermined => const Color(0xFFFEF3C7),
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted => const Color(0xFFFEE2E2),
      null => const Color(0xFFE2E8F0),
    };
  }

  Future<void> _openSettings() async {
    await FlutterContacts.permissions.openSettings();
    await _refreshPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
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
      ContactsTab(
        permissionStatus: _permissionStatus,
        isRequesting: _isRequesting,
        isLoadingContacts: _isLoadingContacts,
        contacts: _contacts,
        contactsError: _contactsError,
        statusLabel: _statusLabel(_permissionStatus),
        statusColor: _statusColor(_permissionStatus),
        statusBgColor: _statusBgColor(_permissionStatus),
        onRequestPermission: _requestContactsPermission,
        onOpenSettings: _openSettings,
        onLoadContacts: _loadContacts,
      ),
    ];

    final bool showingSimTabs = _currentIndex != 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyseur SIM Expert'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: showingSimTabs
                ? _loadAllInformation
                : _refreshPermissionStatus,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: showingSimTabs
          ? (_isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? ErrorDisplay(
                    errorMessage: _errorMessage!,
                    onRetry: _loadAllInformation,
                  )
                : RefreshIndicator(
                    onRefresh: _loadAllInformation,
                    child: pages[_currentIndex],
                  ))
          : pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sim_card),
            label: 'Cartes SIM',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: 'Appareil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}
