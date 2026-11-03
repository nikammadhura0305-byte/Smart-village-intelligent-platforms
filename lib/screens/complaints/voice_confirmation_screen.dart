import '../../app_ui.dart';
import '../../language/app_language.dart';

class VoiceConfirmationScreen extends StatefulWidget {
  final String complaintText;
  final String language;
  final VoidCallback? onConfirm;

  const VoiceConfirmationScreen({
    super.key,
    required this.complaintText,
    this.language = 'मराठी',
    this.onConfirm,
  });

  @override
  State<VoiceConfirmationScreen> createState() =>
      _VoiceConfirmationScreenState();
}

class _VoiceConfirmationScreenState extends State<VoiceConfirmationScreen> {
  static const green = Color(0xFF078746);
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.complaintText,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F4),
      appBar: AppBar(
        title: const Text('तक्रार तपासा'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF087A3E),
                        Color(0xFF22B66A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'तुमची तक्रार तपासा',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'पुढे जाण्यापूर्वी तक्रारीतील माहिती बरोबर आहे का ते पाहा.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: green,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'निवडलेली भाषा',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.language,
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'तक्रारीचे वर्णन',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF174D35),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  minLines: 5,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: AppLanguage.instance.translate(
                      'तुमची तक्रार येथे लिहा...',
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 8,
                        bottom: 100,
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: green,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5E5D9),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: green,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: green,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'काही शब्द चुकीचे आले असतील तर वरील मजकूर बदलू शकता.',
                          style: TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'कृपया तक्रारीचे वर्णन लिहा.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (widget.onConfirm != null) {
                        widget.onConfirm!();
                      } else {
                        Navigator.pop(
                          context,
                          controller.text.trim(),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'तक्रार Confirm करा',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('मागे जा'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
