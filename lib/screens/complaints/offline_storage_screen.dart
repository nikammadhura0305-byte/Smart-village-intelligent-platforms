import '../../app_ui.dart';

class OfflineStorageScreen extends StatefulWidget {
  final String category;
  final String location;
  final String description;

  const OfflineStorageScreen({
    super.key,
    required this.category,
    required this.location,
    required this.description,
  });

  @override
  State<OfflineStorageScreen> createState() => _OfflineStorageScreenState();
}

class _OfflineStorageScreenState extends State<OfflineStorageScreen> {
  static const Color green = Color(0xFF218653);
  static const Color darkGreen = Color(0xFF145C3A);

  bool _saved = false;
  bool _saving = false;

  Future<void> _saveComplaint() async {
    if (_saving || _saved) return;

    setState(() => _saving = true);

    // Demo only: this does not write to a database.
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text(
          'ऑफलाइन तक्रार जतन',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _saved
                        ? Icons.check_circle_rounded
                        : Icons.cloud_off_rounded,
                    color: green,
                    size: 62,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _saved
                    ? 'तक्रार ऑफलाइन जतन झाली!'
                    : 'इंटरनेट नसले तरी चिंता नाही',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _saved
                    ? 'डेमो पूर्ण झाला. प्रत्यक्ष फोनमध्ये '
                        'जतन करण्यासाठी database जोडणे आवश्यक आहे.'
                    : 'तक्रारीची माहिती तपासा आणि ऑफलाइन '
                        'जतन प्रक्रिया सुरू करा.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDDE9E0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'तक्रारीची माहिती',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const Divider(height: 28),
                    _detail(
                      Icons.category_rounded,
                      'तक्रारीचा प्रकार',
                      widget.category,
                    ),
                    const SizedBox(height: 20),
                    _detail(
                      Icons.location_on_rounded,
                      'ठिकाण',
                      widget.location,
                    ),
                    const SizedBox(height: 20),
                    _detail(
                      Icons.description_rounded,
                      'वर्णन',
                      widget.description.trim().isEmpty
                          ? 'वर्णन दिलेले नाही'
                          : widget.description,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          _saved ? Icons.check_circle : Icons.schedule_rounded,
                          color: _saved ? green : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _saved
                                ? 'डेमो: जतन प्रक्रिया पूर्ण'
                                : 'जतन करण्यासाठी तयार',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (_saving || _saved) ? null : _saveComplaint,
                  icon: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _saved ? Icons.check_circle : Icons.save_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'जतन करत आहे...'
                        : _saved
                            ? 'डेमो पूर्ण'
                            : 'ऑफलाइन जतन करा',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('मागील स्क्रीनवर जा'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF26352B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
