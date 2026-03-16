import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Acces Contacts',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF0E5A8A),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Projet Acces aux Contacts'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PermissionStatus? _permissionStatus;
  bool _isRequesting = false;
  bool _isLoadingContacts = false;
  List<Contact> _contacts = <Contact>[];
  String? _contactsError;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
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
    final Color statusColor = _statusColor(_permissionStatus);
    final Color statusBgColor = _statusBgColor(_permissionStatus);

    return Scaffold(
      body: Container(
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
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF1E293B),
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Acces intelligent aux contacts',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                                      _statusLabel(_permissionStatus),
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
                                onPressed: _isRequesting
                                    ? null
                                    : _requestContactsPermission,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  backgroundColor: const Color(0xFF0E5A8A),
                                  foregroundColor: Colors.white,
                                ),
                                icon: _isRequesting
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
                                  _isRequesting
                                      ? 'Demande en cours...'
                                      : 'Demander la permission',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openSettings,
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
                                onPressed:
                                    (_isLoadingContacts ||
                                        !_canReadContacts(_permissionStatus))
                                    ? null
                                    : _loadContacts,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: _isLoadingContacts
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
                                  'Contacts detectes: ${_contacts.length}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (!_canReadContacts(_permissionStatus))
                              const Text(
                                'Autorise d abord l acces pour afficher les contacts.',
                              )
                            else if (_contactsError != null)
                              Text(
                                _contactsError!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                ),
                              )
                            else if (_isLoadingContacts)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_contacts.isEmpty)
                              const Text(
                                'Aucun contact trouve sur cet appareil.',
                              )
                            else
                              ..._contacts.take(8).map((contact) {
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
                            Icon(
                              Icons.lock_person_rounded,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}
