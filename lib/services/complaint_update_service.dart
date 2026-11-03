
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// GramSaksham local demo service.
/// No Firebase or backend required.
class ComplaintUpdateService {
  static const String _complaintsKey = 'gramsaksham_demo_complaints';
  static const String _updatesKey = 'gramsaksham_demo_updates';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<List<Map<String, dynamic>>> getComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_complaintsKey);

    if (raw == null) return [];

    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> getUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_updatesKey);

    if (raw == null) return [];

    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> submitComplaint({
    required String category,
    required String description,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final complaints = await getComplaints();

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    complaints.insert(0, {
      'id': id,
      'category': category,
      'description': description,
      'location': location,
      'status': 'Submitted',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_complaintsKey, jsonEncode(complaints));
  }

  static Future<void> publishUpdate({
    required String complaintId,
    required String status,
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final complaints = await getComplaints();
    final updates = await getUpdates();

    final index =
        complaints.indexWhere((item) => item['id'] == complaintId);

    if (index == -1) {
      throw Exception('Complaint sapadli nahi.');
    }

    final updateId = DateTime.now().microsecondsSinceEpoch.toString();

    complaints[index]['status'] = status;

    updates.insert(0, {
      'id': updateId,
      'complaintId': complaintId,
      'category': complaints[index]['category'],
      'location': complaints[index]['location'],
      'status': status,
      'message': message,
      'publishedAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_complaintsKey, jsonEncode(complaints));
    await prefs.setString(_updatesKey, jsonEncode(updates));

    const androidDetails = AndroidNotificationDetails(
      'gramsaksham_updates',
      'GramSaksham Complaint Updates',
      channelDescription: 'Authority updates for demo complaints',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'GramSaksham: Complaint Update',
      body: message,
      notificationDetails: details,
    );
  }
}

/// Main demo screen with citizen, authority and notification tabs.
class AuthorityUpdatesDemoScreen extends StatefulWidget {
  const AuthorityUpdatesDemoScreen({super.key});

  @override
  State<AuthorityUpdatesDemoScreen> createState() =>
      _AuthorityUpdatesDemoScreenState();
}

class _AuthorityUpdatesDemoScreenState
    extends State<AuthorityUpdatesDemoScreen> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    ComplaintUpdateService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CitizenComplaintPage(),
      const AuthorityDashboardPage(),
      const CitizenNotificationsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GramSaksham'),
        backgroundColor: const Color(0xFF176B45),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Complaint',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Authority',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Updates',
          ),
        ],
      ),
    );
  }
}

/// Citizen complaint form.
class CitizenComplaintPage extends StatefulWidget {
  const CitizenComplaintPage({super.key});

  @override
  State<CitizenComplaintPage> createState() => _CitizenComplaintPageState();
}

class _CitizenComplaintPageState extends State<CitizenComplaintPage> {
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  String category = 'Water Supply';
  bool saving = false;

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await ComplaintUpdateService.submitComplaint(
        category: category,
        description: descriptionController.text.trim(),
        location: locationController.text.trim(),
      );

      if (!mounted) return;

      descriptionController.clear();
      locationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint local demo madhye save zali.'),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Report a Village Problem',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Demo mode: complaint ya device var save hoil.'),
        const SizedBox(height: 20),
        Form(
          key: formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Complaint Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Water Supply',
                    child: Text('Water Supply'),
                  ),
                  DropdownMenuItem(
                    value: 'Road',
                    child: Text('Road'),
                  ),
                  DropdownMenuItem(
                    value: 'Electricity',
                    child: Text('Electricity'),
                  ),
                  DropdownMenuItem(
                    value: 'Sanitation',
                    child: Text('Sanitation'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Village / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Location enter kara'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Complaint Description',
                  hintText: 'Example: Aaj pani ale nahi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Complaint details enter kara'
                        : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : submit,
                  icon: const Icon(Icons.send),
                  label: Text(
                    saving ? 'Saving...' : 'Submit Complaint',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B45),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Demo authority dashboard.
class AuthorityDashboardPage extends StatefulWidget {
  const AuthorityDashboardPage({super.key});

  @override
  State<AuthorityDashboardPage> createState() =>
      _AuthorityDashboardPageState();
}

class _AuthorityDashboardPageState extends State<AuthorityDashboardPage> {
  Future<void> publishFor(Map<String, dynamic> complaint) async {
    final messageController = TextEditingController();
    String status = 'In Progress';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Publish Authority Update'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Complaint Status',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Authority-confirmed message',
                        hintText:
                            'Enter only verified information from the authority.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Demo officer manually enters this update.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Update message enter kara.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        await ComplaintUpdateService.publishUpdate(
          complaintId: complaint['id'] as String,
          status: status,
          message: messageController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update published on this device.'),
          ),
        );

        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ComplaintUpdateService.getComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No complaints yet.\nSubmit a complaint from the Complaint tab first.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final item = complaints[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category'] ?? 'Complaint',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Location: ${item['location']}'),
                    Text('Description: ${item['description']}'),
                    const SizedBox(height: 6),
                    Text('Status: ${item['status']}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => publishFor(item),
                        icon: const Icon(Icons.campaign_outlined),
                        label: const Text('Publish Update'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Citizen notifications page.
class CitizenNotificationsPage extends StatefulWidget {
  const CitizenNotificationsPage({super.key});

  @override
  State<CitizenNotificationsPage> createState() =>
      _CitizenNotificationsPageState();
}

class _CitizenNotificationsPageState
    extends State<CitizenNotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ComplaintUpdateService.getUpdates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final updates = snapshot.data ?? [];

        if (updates.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'No authority updates yet.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Authority ne update publish kelyavar ithe disel.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final item = updates[index];
              final date = DateTime.tryParse(
                item['publishedAt']?.toString() ?? '',
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.notifications_active),
                  ),
                  title: Text(item['category'] ?? 'Complaint Update'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['message'] ?? ''),
                        const SizedBox(height: 8),
                        Text('Status: ${item['status']}'),
                        Text('Location: ${item['location']}'),
                        if (date != null)
                          Text(
                            'Published: ${date.day}/${date.month}/${date.year} '
                            '${date.hour.toString().padLeft(2, '0')}:'
                            '${date.minute.toString().padLeft(2, '0')}',
                          ),
                        const SizedBox(height: 4),
                        const Text(
                          'Local demo update',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
