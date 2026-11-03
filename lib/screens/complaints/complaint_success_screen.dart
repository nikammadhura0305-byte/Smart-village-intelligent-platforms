import '../../app_ui.dart';

class ComplaintSuccessScreen extends StatelessWidget {
  final String complaintId;
  final String category;
  final String location;
  final String description;

  const ComplaintSuccessScreen({
    super.key,
    required this.complaintId,
    required this.category,
    required this.location,
    required this.description,
  });

  static const Color green = Color(0xFF218653);
  static const Color darkGreen = Color(0xFF145C3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'तक्रार यशस्वी',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      height: 125,
                      width: 125,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: green,
                        size: 86,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'तक्रार यशस्वीरीत्या नोंदवली!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'तुमच्या समस्येची माहिती मिळाली आहे. '
                    'पुढील कार्यवाहीसाठी तक्रारीचा तपशील जतन करा.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFDDE9E0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'तक्रार क्रमांक',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          complaintId,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                        const Divider(height: 30),
                        _detail(
                          Icons.category_rounded,
                          'तक्रारीचा प्रकार',
                          category,
                        ),
                        const SizedBox(height: 20),
                        _detail(
                          Icons.location_on_rounded,
                          'ठिकाण',
                          location,
                        ),
                        const SizedBox(height: 20),
                        _detail(
                          Icons.description_rounded,
                          'तक्रारीचे वर्णन',
                          description,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F4E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: darkGreen,
                          size: 25,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'हा प्रोटोटाइप आहे. तक्रार क्रमांक '
                            'सध्या डेमोसाठी तयार केला जातो. '
                            'प्रत्यक्ष नोंदणीसाठी backend जोडणे आवश्यक आहे.',
                            style: TextStyle(
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text(
                        'मुख्य स्क्रीनवर जा',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'तक्रार क्रमांक निवडून कॉपी करता येईल.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.confirmation_number_rounded),
                    label: const Text('तक्रार क्रमांक जतन करा'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkGreen,
                      side: const BorderSide(color: green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                value.trim().isEmpty ? 'माहिती उपलब्ध नाही' : value,
                translate: value.trim().isEmpty,
                softWrap: true,
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
