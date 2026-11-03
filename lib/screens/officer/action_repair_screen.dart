import '../../app_ui.dart';
import '../../language/app_language.dart';

class ActionRepairScreen extends StatefulWidget {
  final String complaintId;
  final String category;
  final String location;

  const ActionRepairScreen({
    super.key,
    this.complaintId = 'GS-2026-001',
    this.category = 'Water Supply',
    this.location = 'Village Location',
  });

  @override
  State<ActionRepairScreen> createState() => _ActionRepairScreenState();
}

class _ActionRepairScreenState extends State<ActionRepairScreen> {
  static const Color primary = Color(0xFF176B55);

  final _formKey = GlobalKey<FormState>();
  final _actionController = TextEditingController();
  final _officerController = TextEditingController();
  final _remarksController = TextEditingController();

  String _status = 'In Progress';
  String _repairType = 'Repair Work';

  @override
  void dispose() {
    _actionController.dispose();
    _officerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _saveAction() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Action details recorded for this demo.',
        ),
        backgroundColor: primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Action / Repair'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF176B55),
                            Color(0xFF25896D),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.handyman_outlined,
                            color: Colors.white,
                            size: 38,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Action & Repair Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Record the work performed and update '
                            'the complaint status.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _detailCard(
                      Icons.confirmation_number_outlined,
                      'Complaint ID',
                      widget.complaintId,
                    ),
                    _detailCard(
                      Icons.category_outlined,
                      'Complaint Category',
                      widget.category,
                    ),
                    _detailCard(
                      Icons.location_on_outlined,
                      'Village / Location',
                      widget.location,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Update Work Details',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _repairType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLanguage.instance.translate(
                          'Type of Action',
                        ),
                        prefixIcon: Icon(Icons.build_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Repair Work',
                          child: Text('Repair Work'),
                        ),
                        DropdownMenuItem(
                          value: 'Inspection',
                          child: Text('Inspection'),
                        ),
                        DropdownMenuItem(
                          value: 'Maintenance',
                          child: Text('Maintenance'),
                        ),
                        DropdownMenuItem(
                          value: 'Replacement',
                          child: Text('Replacement'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _repairType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _actionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: AppLanguage.instance.translate(
                          'Action Taken',
                        ),
                        hintText: AppLanguage.instance.translate(
                          'Describe the work completed or started...',
                        ),
                        prefixIcon: Icon(Icons.edit_note),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLanguage.instance.translate(
                            'Please enter the action taken',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _officerController,
                      decoration: InputDecoration(
                        labelText: AppLanguage.instance.translate(
                          'Responsible Officer',
                        ),
                        hintText: AppLanguage.instance.translate(
                          'Enter officer name',
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLanguage.instance.translate(
                            'Please enter officer name',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: AppLanguage.instance.translate(
                          'Current Work Status',
                        ),
                        prefixIcon: Icon(Icons.track_changes),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
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
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'On Hold',
                          child: Text('On Hold'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppLanguage.instance.translate(
                          'Additional Remarks (Optional)',
                        ),
                        hintText: AppLanguage.instance.translate(
                          'Add any extra information...',
                        ),
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _saveAction,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text(
                          'Save Action Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Demo mode: details are not saved to a database.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E9E5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5F3EC),
          child: Icon(icon, color: primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF24352D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
