import 'dart:async';

import '../../app_ui.dart';
import '../../language/app_language.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

String speechLocaleForLanguage(String language) =>
    switch (language.trim().toLowerCase()) {
      'hindi' || 'हिंदी' || 'hi' || 'hi-in' => 'hi-IN',
      'english' || 'en' || 'en-in' => 'en-IN',
      _ => 'mr-IN',
    };

class VoiceRecordingScreen extends StatefulWidget {
  final String language;
  final ValueChanged<String> onVoiceResult;

  const VoiceRecordingScreen({
    super.key,
    required this.language,
    required this.onVoiceResult,
  });

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  static const green = Color(0xFF078746);
  static const darkGreen = Color(0xFF174D35);

  final stt.SpeechToText speech = stt.SpeechToText();
  final TextEditingController recognizedController = TextEditingController();

  bool available = false;
  bool isListening = false;
  bool isStarting = false;
  bool isPreparing = true;
  bool initialized = false;
  bool showLocaleChoices = false;

  String recognizedText = '';
  String statusKey = 'initializing';
  String? selectedLocaleId;
  String? selectedAlternativeLocaleId;
  List<stt.LocaleName> availableLocales = const [];
  Future<bool>? _initialization;
  Completer<bool>? _listeningStarted;

  String _text({
    required String mr,
    required String hi,
    required String en,
  }) {
    return AppLanguage.instance.text(mr: mr, hi: hi, en: en);
  }

  String get _localizedLanguageName => switch (AppLanguage.instance.language) {
        'Hindi' => _text(mr: 'हिंदी', hi: 'हिंदी', en: 'Hindi'),
        'English' => _text(mr: 'इंग्रजी', hi: 'अंग्रेज़ी', en: 'English'),
        _ => _text(mr: 'मराठी', hi: 'मराठी', en: 'Marathi'),
      };

  String get statusText => switch (statusKey) {
        'initializing' => _text(
            mr: 'माइक सुरू होत आहे...',
            hi: 'माइक शुरू हो रहा है...',
            en: 'Starting microphone...',
          ),
        'listening' => _text(
            mr: 'तुमचे बोलणे ऐकत आहे...',
            hi: 'आपकी बात सुन रहे हैं...',
            en: 'Listening to you...',
          ),
        'capturing' => _text(
            mr: 'मजकूर मिळत आहे. बोलणे पूर्ण झाल्यावर तपासा.',
            hi: 'पाठ मिल रहा है। बोलना पूरा होने पर जाँचें।',
            en: 'Capturing text. Review it when you finish speaking.',
          ),
        'captured' => _text(
            mr: 'मजकूर मिळाला. तपासून घ्या.',
            hi: 'पाठ मिल गया। कृपया जाँचें।',
            en: 'Text captured. Please review it.',
          ),
        'noSpeech' => _text(
            mr: 'आवाज मिळाला नाही. पुन्हा प्रयत्न करा.',
            hi: 'आवाज़ नहीं मिली। फिर से प्रयास करें।',
            en: 'No speech detected. Please try again.',
          ),
        'permissionDenied' => _text(
            mr: 'माइकची परवानगी नाकारली आहे. ब्राउझर किंवा उपकरणाच्या सेटिंग्जमध्ये परवानगी द्या.',
            hi: 'माइक की अनुमति अस्वीकार की गई। ब्राउज़र या डिवाइस सेटिंग्स में अनुमति दें।',
            en: 'Microphone permission was denied. Allow it in your browser or device settings.',
          ),
        'networkError' => _text(
            mr: 'भाषण ओळख सेवेसाठी नेटवर्क उपलब्ध नाही. इंटरनेट तपासून पुन्हा प्रयत्न करा.',
            hi: 'वाणी पहचान सेवा के लिए नेटवर्क उपलब्ध नहीं है। इंटरनेट जाँचकर फिर प्रयास करें।',
            en: 'The speech recognition service is unavailable on the network. Check your connection and try again.',
          ),
        'localeError' => _text(
            mr: 'या ब्राउझर किंवा speech सेवेत निवडलेल्या भाषेचे ओळख समर्थन उपलब्ध नाही.',
            hi: 'इस ब्राउज़र या speech सेवा में चुनी गई भाषा का पहचान समर्थन उपलब्ध नहीं है।',
            en: 'The browser or speech service does not support recognition in the selected language.',
          ),
        'chooseLocale' => _text(
            mr: availableLocales.isEmpty
                ? 'निवडलेल्या भाषेत आवाज ओळखता आला नाही. ब्राउझरने पर्यायी भाषा दिलेली नाही.'
                : 'निवडलेल्या भाषेत आवाज ओळखता आला नाही. खालील उपलब्ध भाषांपैकी एक स्पष्टपणे निवडून पुन्हा प्रयत्न करा.',
            hi: availableLocales.isEmpty
                ? 'चुनी गई भाषा में आवाज़ पहचानी नहीं जा सकी। ब्राउज़र ने कोई वैकल्पिक भाषा नहीं दी।'
                : 'चुनी गई भाषा में आवाज़ पहचानी नहीं जा सकी। नीचे उपलब्ध भाषा स्पष्ट रूप से चुनकर फिर प्रयास करें।',
            en: availableLocales.isEmpty
                ? 'Speech recognition failed in the selected language. The browser did not report an alternative locale.'
                : 'Speech recognition failed in the selected language. Explicitly choose an available language below and try again.',
          ),
        'noMicrophone' => _text(
            mr: 'माइक उपलब्ध नाही. उपकरणाचा माइक आणि ब्राउझर परवानगी तपासा.',
            hi: 'माइक उपलब्ध नहीं है। डिवाइस का माइक और ब्राउज़र अनुमति जाँचें।',
            en: 'No microphone is available. Check the device microphone and browser permission.',
          ),
        'unavailable' => _text(
            mr: 'या ब्राउझर किंवा उपकरणावर speech recognition उपलब्ध नाही.',
            hi: 'इस ब्राउज़र या डिवाइस पर speech पहचान उपलब्ध नहीं है।',
            en: 'Speech recognition is not available in this browser or on this device.',
          ),
        'startFailed' => _text(
            mr: 'माइक सुरू झाला नाही. परवानगी, इंटरनेट आणि speech सेवा तपासा.',
            hi: 'माइक शुरू नहीं हुआ। अनुमति, इंटरनेट और speech सेवा जाँचें।',
            en: 'Listening did not start. Check microphone permission, internet, and speech service.',
          ),
        _ => _text(
            mr: 'माइक बटण दाबून तुमची समस्या सांगा.',
            hi: 'माइक बटन दबाकर अपनी समस्या बताएँ।',
            en: 'Press the microphone button and describe your problem.',
          ),
      };

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_languageChanged);
    unawaited(initializeSpeech());
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

  Future<bool> initializeSpeech() {
    return _initialization ??= _initializeSpeech();
  }

  Future<bool> _initializeSpeech() async {
    try {
      final result = await speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (!mounted) return;

          setState(() {
            if (status == 'listening') {
              isListening = true;
              isStarting = false;
              statusKey = 'listening';
              if (!(_listeningStarted?.isCompleted ?? true)) {
                _listeningStarted!.complete(true);
              }
            } else if (status == 'done' || status == 'notListening') {
              isListening = false;
              if (status == 'done' &&
                  !isStarting &&
                  (statusKey == 'listening' ||
                      statusKey == 'capturing' ||
                      statusKey == 'initializing')) {
                statusKey = recognizedController.text.trim().isEmpty
                    ? 'noSpeech'
                    : 'captured';
              }
            }
          });
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (!(_listeningStarted?.isCompleted ?? true)) {
            _listeningStarted!.complete(false);
          }
          if (!mounted) return;

          setState(() {
            isListening = false;
            isStarting = false;
            statusKey = _errorStatusKey(error.errorMsg);
            showLocaleChoices = statusKey == 'chooseLocale';
          });
        },
      );

      if (!mounted) return false;

      setState(() {
        initialized = true;
        available = result;
        statusKey = result
            ? 'instructions'
            : speech.lastError == null
                ? 'unavailable'
                : _errorStatusKey(speech.lastError!.errorMsg);
      });
      if (result) {
        try {
          availableLocales = await speech.locales();
        } catch (error) {
          debugPrint('Could not read available speech locales: $error');
        }
      }
      if (mounted) setState(() => isPreparing = false);
      return result;
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (!mounted) return false;

      setState(() {
        isPreparing = false;
        available = false;
        statusKey = 'unavailable';
      });
      return false;
    }
  }

  Future<String?> findLocale() async {
    final requestedLocale = speechLocaleForLanguage(
      AppLanguage.instance.language,
    );

    if (kIsWeb) {
      // The Web Speech API exposes the browser's current language, not its
      // recognizer's supported-language list. Request the selected locale
      // directly and report any rejection from the browser.
      return requestedLocale;
    }

    try {
      for (final locale in availableLocales) {
        if (locale.localeId.replaceAll('_', '-').toLowerCase() ==
            requestedLocale.toLowerCase()) {
          return locale.localeId;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Locale error: $e');
      return null;
    }
  }

  String _errorStatusKey(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('not-allowed') ||
        normalized.contains('service-not-allowed') ||
        normalized.contains('permission')) {
      return 'permissionDenied';
    }
    if (normalized.contains('language') ||
        normalized.contains('locale') ||
        normalized.contains('lang') ||
        normalized.contains('no-match')) {
      return 'chooseLocale';
    }
    if (normalized.contains('network')) return 'networkError';
    if (normalized.contains('no-speech')) return 'noSpeech';
    if (normalized.contains('audio-capture')) return 'noMicrophone';
    if (normalized.contains('not supported') ||
        normalized.contains('speech_not_supported')) {
      return 'unavailable';
    }
    return 'startFailed';
  }

  Future<void> toggleListening() async {
    if (isStarting) return;

    if (speech.isListening) {
      await speech.stop();
      if (!mounted) return;

      setState(() {
        isListening = false;
        statusKey =
            recognizedController.text.trim().isEmpty ? 'noSpeech' : 'captured';
      });
      return;
    }

    setState(() {
      isStarting = true;
      showLocaleChoices = false;
      statusKey = 'initializing';
    });

    try {
      final speechAvailable =
          initialized ? available : await initializeSpeech();

      if (!mounted) return;

      if (!speechAvailable) {
        setState(() {
          isStarting = false;
          statusKey = 'unavailable';
        });
        return;
      }

      selectedLocaleId = selectedAlternativeLocaleId ?? await findLocale();

      if (!mounted) return;

      if (selectedLocaleId == null) {
        setState(() {
          isStarting = false;
          statusKey = 'chooseLocale';
          showLocaleChoices = true;
        });
        return;
      }

      _listeningStarted = Completer<bool>();
      setState(() {
        recognizedText = '';
        recognizedController.clear();
        statusKey = 'initializing';
      });

      await speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: selectedLocaleId!,
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: true,
        ),
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            recognizedText = result.recognizedWords;
            recognizedController.value = TextEditingValue(
              text: recognizedText,
              selection: TextSelection.collapsed(offset: recognizedText.length),
            );
            if (isListening) statusKey = 'capturing';
          });
        },
      );

      final started = await _listeningStarted!.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () => false,
      );
      if (!mounted) return;
      if (!started && isStarting) {
        await speech.cancel();
        setState(() {
          isStarting = false;
          isListening = false;
          statusKey = speech.lastError == null
              ? 'startFailed'
              : _errorStatusKey(speech.lastError!.errorMsg);
        });
      }
    } catch (e) {
      debugPrint('Listen error: $e');
      if (!mounted) return;

      setState(() {
        isStarting = false;
        isListening = false;
        statusKey = speech.lastError == null
            ? 'startFailed'
            : _errorStatusKey(speech.lastError!.errorMsg);
        showLocaleChoices = statusKey == 'chooseLocale';
      });
    }
  }

  Future<void> finishRecording() async {
    if (speech.isListening) {
      await speech.stop();
    }

    if (!mounted) return;

    final text = recognizedController.text.trim();

    if (text.isEmpty) {
      setState(() {
        statusKey = 'noSpeech';
      });
      return;
    }

    widget.onVoiceResult(text);
    Navigator.pop(context, text);
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_languageChanged);
    recognizedController.dispose();
    speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F1),
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 54,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () async {
            await speech.stop();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          splashRadius: 22,
        ),
        title: Text(
          _text(
            mr: 'आवाजातून तक्रार',
            hi: 'आवाज़ से शिकायत',
            en: 'Voice complaint',
          ),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const Icon(
                      Icons.account_circle_rounded,
                      size: 78,
                      color: green,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _text(
                        mr: 'तुमची समस्या बोला',
                        hi: 'अपनी समस्या बोलें',
                        en: 'Speak about your problem',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _text(
                        mr: 'निवडलेली भाषा: $_localizedLanguageName',
                        hi: 'चुनी गई भाषा: $_localizedLanguageName',
                        en: 'Selected language: $_localizedLanguageName',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: isStarting || isPreparing ? null : toggleListening,
                      child: CircleAvatar(
                        radius: 78,
                        backgroundColor: green,
                        child: Icon(
                          isStarting || isPreparing
                              ? Icons.hourglass_top_rounded
                              : isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (showLocaleChoices && availableLocales.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _text(
                            mr: 'उपलब्ध speech भाषा',
                            hi: 'उपलब्ध speech भाषाएँ',
                            en: 'Available speech languages',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedAlternativeLocaleId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        hint: Text(
                          _text(
                            mr: 'भाषा स्पष्टपणे निवडा',
                            hi: 'भाषा स्पष्ट रूप से चुनें',
                            en: 'Choose a language explicitly',
                          ),
                        ),
                        items: availableLocales
                            .map(
                              (locale) => DropdownMenuItem<String>(
                                value: locale.localeId,
                                child: Text(
                                  '${locale.name} (${locale.localeId})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isStarting
                            ? null
                            : (localeId) {
                                setState(() {
                                  selectedAlternativeLocaleId = localeId;
                                });
                              },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_text(
                          mr: 'निवडलेली speech भाषा:',
                          hi: 'चुनी गई speech भाषा:',
                          en: 'Selected speech language:',
                        )} ${selectedAlternativeLocaleId ?? speechLocaleForLanguage(AppLanguage.instance.language)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (isListening) ...[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: green,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _text(
                          mr: 'ओळखलेला मजकूर',
                          hi: 'पहचाना गया पाठ',
                          en: 'Recognized text',
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F1A11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDEDED9),
                        ),
                      ),
                      child: TextField(
                        controller: recognizedController,
                        onChanged: (value) => recognizedText = value,
                        minLines: 2,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: _text(
                            mr: 'उदा. पाणी आज आले नाही.',
                            hi: 'उदा. आज पानी नहीं आया।',
                            en: 'Example: The water did not come today.',
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: Color(0xFF2B2D2B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: isStarting || isListening ? null : finishRecording,
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _text(
                      mr: 'वापरलेले वाक्य',
                      hi: 'इस वाक्य का उपयोग करें',
                      en: 'Use this text',
                    ),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
