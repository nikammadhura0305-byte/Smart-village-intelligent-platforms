import 'dart:async';
import '../../app_ui.dart';
import 'complaint_success_screen.dart';

class AIProcessingScreen extends StatefulWidget {
  final String category;
  final String location;
  final String description;

  const AIProcessingScreen({
    super.key,
    required this.category,
    required this.location,
    required this.description,
  });

  @override
  State<AIProcessingScreen> createState() => _AIProcessingScreenState();
}

class _AIProcessingScreenState extends State<AIProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  final List<String> _steps = [
    'तक्रारीची माहिती तपासत आहोत',
    'समस्येचा प्रकार ओळखत आहोत',
    'विभाग निश्चित करत आहोत',
    'तक्रार नोंदणीसाठी तयार करत आहोत',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _processComplaint();
  }

  Future<void> _processComplaint() async {
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    _controller.stop();
    setState(() => _completed = true);

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final complaintId = 'GS${DateTime.now().millisecondsSinceEpoch}';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintSuccessScreen(
          complaintId: complaintId,
          category: widget.category,
          location: widget.location,
          description: widget.description,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16845B);
    const dark = Color(0xFF173D30);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI तक्रार विश्लेषण',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 6.28318,
                      child: child,
                    );
                  },
                  child: Container(
                    height: 112,
                    width: 112,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: green.withValues(alpha: 0.25),
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: green.withValues(alpha: 0.12),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      size: 58,
                      color: green,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _completed ? 'विश्लेषण पूर्ण!' : 'AI तक्रार तपासत आहे...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _completed
                      ? 'तक्रार पुढील टप्प्यासाठी तयार आहे.'
                      : 'कृपया थोडा वेळ थांबा.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE0EBE4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'तक्रारीची माहिती',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detail(
                        Icons.category_outlined,
                        'समस्या',
                        widget.category,
                      ),
                      const SizedBox(height: 12),
                      _detail(
                        Icons.location_on_outlined,
                        'ठिकाण',
                        widget.location,
                      ),
                      const SizedBox(height: 12),
                      _detail(
                        Icons.description_outlined,
                        'वर्णन',
                        widget.description,
                        translateValue: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: List.generate(
                      _steps.length,
                      (index) {
                        final done = _completed;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 17),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: done ? green : Colors.blueGrey,
                                size: 23,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _steps[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: dark,
                                    fontWeight: done
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (!_completed)
                  const LinearProgressIndicator(
                    color: green,
                    backgroundColor: Color(0xFFDCEBE1),
                    minHeight: 5,
                  ),
                const SizedBox(height: 12),
                Text(
                  _completed
                      ? 'पुढील स्क्रीन उघडत आहे...'
                      : 'GramSaksham • Smart Village',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(
    IconData icon,
    String title,
    String value, {
    bool translateValue = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF16845B), size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'माहिती उपलब्ध नाही' : value,
                translate: value.isEmpty || translateValue,
                style: const TextStyle(
                  color: Color(0xFF173D30),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
