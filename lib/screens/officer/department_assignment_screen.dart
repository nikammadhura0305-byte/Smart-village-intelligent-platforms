import '../../app_ui.dart';
import '../../language/app_language.dart';

class DepartmentAssignmentScreen extends StatefulWidget {
  final String complaintId;
  final String category;
  final String location;
  final String description;

  const DepartmentAssignmentScreen({
    super.key,
    this.complaintId = 'GS-2026-001',
    this.category = 'Water Supply',
    this.location = 'Village Location',
    this.description = 'Water supply issue reported by citizen.',
  });

  @override
  State<DepartmentAssignmentScreen> createState() =>
      _DepartmentAssignmentScreenState();
}

class _DepartmentAssignmentScreenState
    extends State<DepartmentAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDepartment;
  String? _selectedPriority;
  final _officerController = TextEditingController();
  final _remarksController = TextEditingController();

  final List<String> _departments = [
    'Water Supply Department',
    'Electricity Department',
    'Roads and Public Works',
    'Sanitation Department',
    'Health Department',
    'Gram Panchayat',
  ];

  @override
  void dispose() {
    _officerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _assignComplaint() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null || _selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select department and priority.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Assignment Saved'),
        content: Text(
          'Complaint ${widget.complaintId} has been assigned to '
          '$_selectedDepartment.\n\n'
          'Officer: ${_officerController.text.trim()}\n'
          'Priority: $_selectedPriority',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF176B55);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Department'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.assignment_ind, color: primary, size: 36),
                        SizedBox(height: 10),
                        Text(
                          'Complaint Assignment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Review the complaint and route it to the '
                          'appropriate department.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _infoCard('Complaint ID', widget.complaintId),
                  _infoCard('Category', widget.category),
                  _infoCard('Location', widget.location),
                  _infoCard('Description', widget.description),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppLanguage.instance.translate(
                        'Select Department',
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: _departments
                        .map(
                          (department) => DropdownMenuItem(
                            value: department,
                            child: Text(department),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedDepartment = value);
                    },
                    validator: (value) => value == null
                        ? AppLanguage.instance.translate(
                            'Select a department',
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _officerController,
                    decoration: InputDecoration(
                      labelText: AppLanguage.instance.translate(
                        'Assigned Officer Name',
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppLanguage.instance.translate('Enter officer name')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Complaint Priority',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Low',
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 'Medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'High',
                        child: Text('High'),
                      ),
                      DropdownMenuItem(
                        value: 'Urgent',
                        child: Text('Urgent'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPriority = value);
                    },
                    validator: (value) =>
                        value == null ? 'Select priority' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppLanguage.instance.translate(
                        'Remarks (optional)',
                      ),
                      hintText: AppLanguage.instance.translate(
                        'Add assignment instructions',
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _assignComplaint,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Assign Complaint',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
