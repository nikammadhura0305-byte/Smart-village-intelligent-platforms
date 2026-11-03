import 'package:flutter/material.dart';
import '../language/app_language.dart';
import '../widgets/gramsaksham_mark.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLanguage = 'Marathi';

  static const Color green = Color(0xFF087A3E);
  static const Color darkGreen = Color(0xFF07552F);

  final List<Map<String, String>> languages = [
    {
      'name': 'मराठी',
      'english': 'Marathi',
      'flag': '🇮🇳',
    },
    {
      'name': 'हिंदी',
      'english': 'Hindi',
      'flag': '🇮🇳',
    },
    {
      'name': 'English',
      'english': 'English',
      'flag': '🇬🇧',
    },
  ];

  String getText({
    required String mr,
    required String hi,
    required String en,
  }) {
    return AppLanguage.instance.text(
      mr: mr,
      hi: hi,
      en: en,
    );
  }

  @override
  void initState() {
    super.initState();
    selectedLanguage = AppLanguage.instance.language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 22),
                  const GramSakshamMark(size: 90),
                  const SizedBox(height: 24),
                  Text(
                    getText(
                      mr: 'भाषा निवडा',
                      hi: 'भाषा चुनें',
                      en: 'Select Language',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getText(
                      mr: 'तुमची भाषा निवडा',
                      hi: 'अपनी भाषा चुनें',
                      en: 'Choose Your Language',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getText(
                      mr: 'तुमची आवडती भाषा निवडा',
                      hi: 'अपनी पसंदीदा भाषा चुनें',
                      en: 'Select your preferred language',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...languages.map((language) {
                    final isSelected = selectedLanguage == language['english'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final newLanguage = language['english']!;

                          setState(() {
                            selectedLanguage = newLanguage;
                          });

                          try {
                            await AppLanguage.instance.setLanguage(newLanguage);
                          } catch (error) {
                            debugPrint('Could not save app language: $error');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  getText(
                                    mr: 'भाषा जतन करता आली नाही.',
                                    hi: 'भाषा सहेजी नहीं जा सकी।',
                                    en: 'Could not save the selected language.',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 17,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE7F6E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  isSelected ? green : const Color(0xFFE1E8E1),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                language['flag']!,
                                style: const TextStyle(
                                  fontSize: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language['name']!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      language['english']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.arrow_forward_ios,
                                size: isSelected ? 24 : 18,
                                color: isSelected ? green : Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        try {
                          await AppLanguage.instance
                              .setLanguage(selectedLanguage);
                        } catch (error) {
                          debugPrint('Could not save app language: $error');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                getText(
                                  mr: 'भाषा जतन करता आली नाही.',
                                  hi: 'भाषा सहेजी नहीं जा सकी।',
                                  en: 'Could not save the selected language.',
                                ),
                              ),
                            ),
                          );
                        }

                        if (!context.mounted) return;
                        Navigator.pushNamed(
                          context,
                          '/login',
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            getText(
                              mr: 'पुढे',
                              hi: 'आगे बढ़ें',
                              en: 'Continue',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                          ),
                        ],
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
}
