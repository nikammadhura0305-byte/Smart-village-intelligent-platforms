import '../../app_ui.dart';
import '../../language/app_language.dart';

class VerificationScreen extends StatefulWidget {
  final String complaintId;
  final String category;
  final String location;

  const VerificationScreen({
    super.key,
    this.complaintId = 'GS-2026-001',
    this.category = 'Water Supply',
    this.location = 'Village Location',
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color primary = Color(0xFF176B55);

  String _result = 'Pending Verification';
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _verifyComplaint() {
    if (_result == 'Pending Verification') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a verification result.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          _result == 'Verified' ? Icons.verified : Icons.warning_amber_rounded,
          color: _result == 'Verified' ? Colors.green : Colors.orange,
          size: 48,
        ),
        title: const Text('Verification Recorded'),
        content: Text(
          'Complaint: ${widget.complaintId}\n'
          'Result: $_result\n\n'
          'Demo mode: this result has not been saved to a database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Complaint Verification'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primary, Color(0xFF27876C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Verify Completed Work',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Review the reported work and record '
                          'the verification result.',
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
                    'Verification Checklist',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _checkItem(
                    Icons.assignment_turned_in_outlined,
                    'Action details reviewed',
                  ),
                  _checkItem(
                    Icons.location_searching,
                    'Complaint location checked',
                  ),
                  _checkItem(
                    Icons.rule_outlined,
                    'Resolution quality assessed',
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Verification Result',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _resultOption(
                    title: 'Verified',
                    subtitle: 'Work is completed satisfactorily',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  _resultOption(
                    title: 'Rejected',
                    subtitle: 'Work does not meet requirements',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                  _resultOption(
                    title: 'Needs Rework',
                    subtitle: 'Additional work is required',
                    icon: Icons.build_circle_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppLanguage.instance.translate(
                        'Verification Remarks',
                      ),
                      hintText: AppLanguage.instance.translate(
                        'Enter observations or feedback...',
                      ),
                      prefixIcon: Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _verifyComplaint,
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text(
                        'Submit Verification',
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
                    'Demo mode: verification is not stored permanently.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailCard(IconData icon, String title, String value) {
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
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _checkItem(IconData icon, String label) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: primary),
        title: Text(label),
        trailing: const Icon(
          Icons.check_circle_outline,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _resultOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _result == title;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : const Color(0xFFE2E9E5),
          width: selected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: title,
        groupValue: _result,
        activeColor: color,
        onChanged: (value) {
          if (value != null) {
            setState(() => _result = value);
          }
        },
        secondary: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
