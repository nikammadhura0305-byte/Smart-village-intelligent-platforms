import '../../app_ui.dart';
import 'ai_processing_screen.dart';

class AutoSyncScreen extends StatefulWidget {
  final String category;
  final String location;
  final String description;

  const AutoSyncScreen({
    super.key,
    required this.category,
    required this.location,
    required this.description,
  });

  @override
  State<AutoSyncScreen> createState() => _AutoSyncScreenState();
}

class _AutoSyncScreenState extends State<AutoSyncScreen> {
  static const Color green = Color(0xFF218653);
  static const Color darkGreen = Color(0xFF145C3A);

  bool _internetAvailable = true;
  bool _syncing = false;
  bool _synced = false;

  Future<void> _startSync() async {
    if (_syncing || _synced) return;

    if (!_internetAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('इंटरनेट उपलब्ध झाल्यावर पुन्हा प्रयत्न करा.'),
        ),
      );
      return;
    }

    setState(() => _syncing = true);

    // Demo animation only; real server sync is not connected.
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _syncing = false;
      _synced = true;
    });
  }

  void _continueToAI() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AIProcessingScreen(
          category: widget.category,
          location: widget.location,
          description: widget.description,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text(
          'तक्रार ऑटो सिंक',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 105,
                      width: 105,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _synced
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_sync_rounded,
                        color: green,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _synced
                        ? 'सिंक प्रक्रिया पूर्ण!'
                        : _syncing
                            ? 'तक्रार सिंक होत आहे...'
                            : 'ऑटो सिंक व्यवस्थापन',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _synced
                        ? 'आता AI विश्लेषणाच्या पुढील टप्प्यावर जा.'
                        : 'इंटरनेट उपलब्ध असल्याचे डेमो निवडा आणि '
                            'तक्रार सिंक प्रक्रिया सुरू करा.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(18),
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
                          'सिंक स्थिती',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        const Divider(height: 28),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeTrackColor: green,
                          title: const Text(
                            'डेमो इंटरनेट उपलब्ध',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _internetAvailable
                                ? 'इंटरनेट उपलब्ध असल्याचे डेमो'
                                : 'इंटरनेट उपलब्ध नाही असे डेमो',
                          ),
                          value: _internetAvailable,
                          onChanged: _syncing || _synced
                              ? null
                              : (value) {
                                  setState(() {
                                    _internetAvailable = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        _statusRow(
                          Icons.save_rounded,
                          'तक्रारीची माहिती',
                          'प्राप्त',
                          green,
                        ),
                        const SizedBox(height: 18),
                        _statusRow(
                          Icons.wifi_rounded,
                          'इंटरनेट',
                          _internetAvailable ? 'उपलब्ध' : 'उपलब्ध नाही',
                          _internetAvailable ? green : Colors.orange,
                        ),
                        const SizedBox(height: 18),
                        _statusRow(
                          Icons.cloud_upload_rounded,
                          'सिंक स्थिती',
                          _synced
                              ? 'पूर्ण'
                              : _syncing
                                  ? 'प्रक्रिया सुरू'
                                  : 'प्रतीक्षेत',
                          _synced ? green : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'तक्रारीचा सारांश',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _summary('प्रकार', widget.category),
                        _summary('ठिकाण', widget.location),
                        _summary('वर्णन', widget.description,
                            translateValue: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_syncing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(
                        color: green,
                        backgroundColor: Color(0xFFDDE9E0),
                        minHeight: 5,
                      ),
                    ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _syncing || _synced ? null : _startSync,
                      icon: Icon(
                        _synced
                            ? Icons.check_circle
                            : Icons.cloud_upload_rounded,
                      ),
                      label: Text(
                        _synced
                            ? 'सिंक पूर्ण'
                            : _syncing
                                ? 'सिंक होत आहे...'
                                : 'आता सिंक करा',
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _synced ? _continueToAI : null,
                      icon: const Icon(Icons.psychology_alt_rounded),
                      label: const Text('पुढे जा — AI विश्लेषण'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkGreen,
                        side: const BorderSide(color: green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('मागील स्क्रीनवर जा'),
                    style: TextButton.styleFrom(
                      foregroundColor: darkGreen,
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

  Widget _statusRow(
    IconData icon,
    String title,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Flexible(
          child: Text(
            status,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(
    String title,
    String value, {
    bool translateValue = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$title:',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'माहिती उपलब्ध नाही' : value,
              translate: value.trim().isEmpty || translateValue,
              softWrap: true,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF26352B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
