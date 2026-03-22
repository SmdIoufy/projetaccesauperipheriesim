import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_code/sim_card_code.dart';

import 'widgets/device.dart';
import 'widgets/sim_cards.dart';
import 'widgets/ui_components.dart';

void main() {
  runApp(const SimCardManagerApp());
}

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

class SimCardDashboard extends StatefulWidget {
  const SimCardDashboard({super.key});

  @override
  State<SimCardDashboard> createState() => _SimCardDashboardState();
}

class _SimCardDashboardState extends State<SimCardDashboard> {
  int _currentIndex = 0;

  SimCardInfo? _basicSimInfo;
  List<SimCardInfo> _allSimInfo = [];
  NetworkInfo? _networkInfo;
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
      final status = await Permission.phone.status;
      if (!status.isGranted) {
        await Permission.phone.request();
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
        SimCardManager.networkInfo,
        SimCardManager.deviceId,
        SimCardManager.hasSimCard,
        SimCardManager.isDualSim,
        SimCardManager.simCount,
      ]);

      if (!mounted) return;
      setState(() {
        _basicSimInfo = results[0] as SimCardInfo?;
        _allSimInfo = results[1] as List<SimCardInfo>;
        _networkInfo = results[2] as NetworkInfo?;
        _deviceId = results[3] as String?;
        _hasSimCard = results[4] as bool;
        _isDualSim = results[5] as bool;
        _simCount = results[6] as int;
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
        (a, b) => (a.displayName ?? '')
            .toLowerCase()
            .compareTo((b.displayName ?? '').toLowerCase()),
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

class ContactsTab extends StatelessWidget {
  const ContactsTab({
    super.key,
    required this.permissionStatus,
    required this.isRequesting,
    required this.isLoadingContacts,
    required this.contacts,
    required this.contactsError,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBgColor,
    required this.onRequestPermission,
    required this.onOpenSettings,
    required this.onLoadContacts,
  });

  final PermissionStatus? permissionStatus;
  final bool isRequesting;
  final bool isLoadingContacts;
  final List<Contact> contacts;
  final String? contactsError;
  final String statusLabel;
  final Color statusColor;
  final Color statusBgColor;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onLoadContacts;

  bool _canReadContacts(PermissionStatus? status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF6FF), Color(0xFFF9F5EC)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projet Acces aux Contacts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF1E293B),
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Acces intelligent aux contacts',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                height: 1.2,
                              ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x160F172A),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.contact_phone_rounded,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Etat de la permission',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isRequesting ? null : onRequestPermission,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: const Color(0xFF0E5A8A),
                                foregroundColor: Colors.white,
                              ),
                              icon: isRequesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.verified_user_rounded),
                              label: Text(
                                isRequesting
                                    ? 'Demande en cours...'
                                    : 'Demander la permission',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onOpenSettings,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.settings_rounded),
                              label: const Text('Ouvrir les parametres'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: (isLoadingContacts ||
                                      !_canReadContacts(permissionStatus))
                                  ? null
                                  : onLoadContacts,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: isLoadingContacts
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                              label: const Text('Charger les contacts'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                color: Color(0xFF0E5A8A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Contacts detectes: ${contacts.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (!_canReadContacts(permissionStatus))
                            const Text(
                              'Autorise d abord l acces pour afficher les contacts.',
                            )
                          else if (contactsError != null)
                            Text(
                              contactsError!,
                              style: const TextStyle(color: Color(0xFF991B1B)),
                            )
                          else if (isLoadingContacts)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (contacts.isEmpty)
                            const Text('Aucun contact trouve sur cet appareil.')
                          else
                            ...contacts.take(8).map((contact) {
                              final String displayName =
                                  (contact.displayName ?? '').trim();
                              final String initial = displayName.isNotEmpty
                                  ? displayName.substring(0, 1).toUpperCase()
                                  : '?';
                              final String phone = contact.phones.isNotEmpty
                                  ? (contact.phones.first.normalizedNumber ??
                                      contact.phones.first.number)
                                  : 'Numero non renseigne';
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE0F2FE),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Color(0xFF075985),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                      : 'Sans nom',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_person_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ton consentement est prioritaire: les contacts ne sont pas accessibles sans accord explicite.',
                              style: TextStyle(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
