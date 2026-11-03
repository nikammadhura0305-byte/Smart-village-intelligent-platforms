import '../../app_ui.dart';
import '../../language/app_language.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const green = Color(0xFF218653);
  static const darkGreen = Color(0xFF145C3A);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        String text({
          required String mr,
          required String hi,
          required String en,
        }) =>
            AppLanguage.instance.text(mr: mr, hi: hi, en: en);

        final notifications = [
          (
            title: text(
              mr: 'ग्रामसक्षममध्ये स्वागत!',
              hi: 'ग्रामसक्षम में आपका स्वागत है!',
              en: 'Welcome to GramSaksham!',
            ),
            message: text(
              mr: 'गावातील समस्या नोंदवण्यासाठी समस्या नोंदवा हा पर्याय वापरा.',
              hi: 'गाँव की समस्या दर्ज करने के लिए समस्या दर्ज करें विकल्प चुनें।',
              en: 'Choose Report a problem to report an issue in your village.',
            ),
            date: text(mr: 'माहिती', hi: 'जानकारी', en: 'Info'),
            icon: Icons.waving_hand_rounded,
            color: const Color(0xFF218653),
          ),
          (
            title: text(
              mr: 'तक्रारींचे अपडेट',
              hi: 'शिकायत अपडेट',
              en: 'Complaint updates',
            ),
            message: text(
              mr: 'तक्रार सबमिट केल्यानंतर स्थिती पाहण्यासाठी माझ्या तक्रारी उघडा.',
              hi: 'शिकायत जमा करने के बाद उसकी स्थिति देखने के लिए मेरी शिकायतें खोलें।',
              en: 'Open My Complaints to check the status after submitting a complaint.',
            ),
            date: text(mr: 'माहिती', hi: 'जानकारी', en: 'Info'),
            icon: Icons.assignment_rounded,
            color: const Color(0xFF2376C9),
          ),
          (
            title: text(
              mr: 'ग्रामपंचायत सेवा',
              hi: 'ग्राम पंचायत सेवाएँ',
              en: 'Village council services',
            ),
            message: text(
              mr: 'सेवेसंबंधी अद्ययावत माहितीसाठी ग्रामपंचायत कार्यालयाशी संपर्क साधा.',
              hi: 'सेवाओं की नवीनतम जानकारी के लिए ग्राम पंचायत कार्यालय से संपर्क करें।',
              en: 'Contact the village council office for updated service information.',
            ),
            date: text(mr: 'माहिती', hi: 'जानकारी', en: 'Info'),
            icon: Icons.account_balance_rounded,
            color: const Color(0xFFE58A16),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF3F7F4),
          appBar: AppBar(
            backgroundColor: darkGreen,
            foregroundColor: Colors.white,
            title: Text(
              text(mr: 'सूचना', hi: 'सूचनाएँ', en: 'Notifications'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF218653), Color(0xFF145C3A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text(
                              mr: 'सूचना केंद्र',
                              hi: 'सूचना केंद्र',
                              en: 'Notifications',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            text(
                              mr: 'ग्रामसक्षम सेवांबद्दल महत्त्वाची माहिती',
                              hi: 'ग्रामसक्षम सेवाओं की महत्वपूर्ण जानकारी',
                              en: 'Important information about GramSaksham services',
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                text(
                  mr: 'अलीकडील सूचना',
                  hi: 'हाल की सूचनाएँ',
                  en: 'Recent notifications',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 12),
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      text(
                        mr: 'नवीन सूचना नाहीत.',
                        hi: 'कोई नई सूचनाएँ नहीं हैं।',
                        en: 'No new notifications.',
                      ),
                    ),
                  ),
                ),
              ...notifications.map((item) {
                final color = item.color;
                final icon = item.icon;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xFFDDE9E0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 25),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.message,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.date,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                text(
                  mr: 'टीप: या आवृत्तीत नमुना सूचना दाखवल्या आहेत. '
                      'प्रत्यक्ष तक्रार अपडेट्स आणि मोबाइल push notifications '
                      'दाखवण्यासाठी notification service/backend जोडणे आवश्यक आहे.',
                  hi: 'नोट: इस संस्करण में नमूना सूचनाएँ दिखाई गई हैं। '
                      'वास्तविक शिकायत अपडेट और मोबाइल पुश सूचनाओं के लिए '
                      'notification सेवा/backend जोड़ना होगा।',
                  en: 'Note: This version shows sample notifications. '
                      'A notification service/backend is needed for real '
                      'complaint updates and mobile push notifications.',
                ),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
