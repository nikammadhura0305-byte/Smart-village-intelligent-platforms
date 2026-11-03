import '../../app_ui.dart';
import '../../language/app_language.dart';
import 'department_assignment_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  static const Color primaryColor = Color(0xFF176B50);
  static const Color backgroundColor = Color(0xFFF4F7F5);

  String selectedFilter = 'All';

  final List<Map<String, String>> complaints = [
    {
      'id': 'GS-2026-001',
      'category': 'Water Supply',
      'location': 'Shivaji Nagar',
      'description': 'पाणी आज आले नाही.',
      'status': 'Pending',
      'priority': 'High',
    },
    {
      'id': 'GS-2026-002',
      'category': 'Road',
      'location': 'Main Village Road',
      'description': 'रस्त्यावर मोठे खड्डे आहेत.',
      'status': 'In Progress',
      'priority': 'Medium',
    },
    {
      'id': 'GS-2026-003',
      'category': 'Street Light',
      'location': 'Near Gram Panchayat',
      'description': 'स्ट्रीट लाईट बंद आहे.',
      'status': 'Pending',
      'priority': 'Medium',
    },
    {
      'id': 'GS-2026-004',
      'category': 'Sanitation',
      'location': 'Market Area',
      'description': 'परिसरात कचरा जमा झाला आहे.',
      'status': 'Resolved',
      'priority': 'Low',
    },
  ];

  List<Map<String, String>> get filteredComplaints {
    if (selectedFilter == 'All') return complaints;

    return complaints
        .where((item) => item['status'] == selectedFilter)
        .toList();
  }

  int get pendingCount =>
      complaints.where((c) => c['status'] == 'Pending').length;

  int get inProgressCount =>
      complaints.where((c) => c['status'] == 'In Progress').length;

  int get resolvedCount =>
      complaints.where((c) => c['status'] == 'Resolved').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Officer Dashboard',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'GramSaksham • Smart Village',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            const Text(
              'Complaint Overview',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF24332C),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: [
                _buildStatCard(
                  'Total Complaints',
                  '${complaints.length}',
                  Icons.assignment_outlined,
                  primaryColor,
                ),
                _buildStatCard(
                  'Pending',
                  '$pendingCount',
                  Icons.pending_actions,
                  const Color(0xFFE58A19),
                ),
                _buildStatCard(
                  'In Progress',
                  '$inProgressCount',
                  Icons.engineering_outlined,
                  const Color(0xFF2878C8),
                ),
                _buildStatCard(
                  'Resolved',
                  '$resolvedCount',
                  Icons.task_alt,
                  const Color(0xFF299764),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Citizen Complaints',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF24332C),
                    ),
                  ),
                ),
                Text(
                  '${filteredComplaints.length} ${AppLanguage.instance.translate('records')}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 12),
            if (filteredComplaints.isEmpty)
              _buildEmptyState()
            else
              ...filteredComplaints.map(_buildComplaintCard),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryColor,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo data is displayed. Connect a backend '
                        'to manage real village complaints.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF176B50),
            Color(0xFF27956C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'नमस्कार, अधिकारी!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage village complaints and track their progress.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24332C),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Pending', 'In Progress', 'Resolved'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
              ),
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, String> complaint) {
    final status = complaint['status'] ?? 'Pending';
    final priority = complaint['priority'] ?? 'Medium';

    final Color statusColor = status == 'Resolved'
        ? const Color(0xFF238653)
        : status == 'In Progress'
            ? const Color(0xFF2878C8)
            : const Color(0xFFE58A19);

    final Color priorityColor = priority == 'High'
        ? const Color(0xFFD93636)
        : priority == 'Low'
            ? const Color(0xFF238653)
            : const Color(0xFFE58A19);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E9E3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complaint['id'] ?? '',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(status),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                  ),
                  backgroundColor: statusColor.withOpacity(0.12),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint['category'] ?? 'General',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLanguage.instance.translate('Location:')} '
              '${complaint['location'] ?? ''}',
            ),
            const SizedBox(height: 8),
            Text(
              complaint['description'] ?? '',
              translate: false,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '${AppLanguage.instance.translate('Priority:')} $priority',
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DepartmentAssignmentScreen(
                          complaintId: complaint['id']!,
                          category: complaint['category']!,
                          location: complaint['location']!,
                          description: complaint['description']!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('Assign Department'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.black38),
          SizedBox(height: 12),
          Text(
            'No complaints found',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Try selecting a different filter.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
