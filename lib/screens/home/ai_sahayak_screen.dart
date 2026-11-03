import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_ui.dart';
import '../../language/app_language.dart';
import '../complaints/voice_recording_screen.dart';

class AiSahayakScreen extends StatefulWidget {
  const AiSahayakScreen({super.key});

  @override
  State<AiSahayakScreen> createState() => _AiSahayakScreenState();
}

class _AiSahayakScreenState extends State<AiSahayakScreen> {
  static const purple = Color(0xFF218653);
  static const darkPurple = Color(0xFF075B35);
  static const maxAttachmentBytes = 10 * 1024 * 1024;
  static const allowedFileExtensions = {
    'pdf',
    'txt',
    'doc',
    'docx',
  };

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<_ChatMessage> _messages = [];

  Uint8List? _pendingImageBytes;
  String? _pendingImageName;
  String? _pendingFileName;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_languageChanged);
    _messages.add(const _ChatMessage(isWelcome: true));
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_languageChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _say({
    required String mr,
    required String hi,
    required String en,
  }) {
    return AppLanguage.instance.text(mr: mr, hi: hi, en: en);
  }

  String _welcomeMessage() {
    return _say(
      mr: 'नमस्कार! मी ग्रामसक्षम सहाय्यक आहे. पाणी, वीज, रस्ते, स्वच्छता, कागदपत्रे, शिक्षण, सुरक्षा, शेती किंवा आरोग्य सेवांबद्दल विचारा.',
      hi: 'नमस्ते! मैं ग्रामसक्षम सहायक हूँ। पानी, बिजली, सड़क, सफाई, दस्तावेज़, शिक्षा, सुरक्षा, खेती या स्वास्थ्य सेवाओं के बारे में पूछें।',
      en: 'Hello! I am the GramSaksham assistant. Ask about water, electricity, roads, cleanliness, documents, education, safety, farming, or health services.',
    );
  }

  String _getReply(String question, {required bool hasAttachment}) {
    final q = question.toLowerCase();
    final reply = _say(
      mr: _marathiReply(q),
      hi: _hindiReply(q),
      en: _englishReply(q),
    );

    if (!hasAttachment) return reply;

    return '$reply\n\n${_say(
      mr: 'जोडलेली फाइल फक्त या डेमो चॅटमध्ये दाखवली आहे. ती backend कडे पाठवली किंवा तपासली जात नाही. समस्येचे तपशील मजकूरातही लिहा.',
      hi: 'संलग्न फ़ाइल केवल इस डेमो चैट में दिखाई गई है। इसे backend पर भेजा या जाँचा नहीं गया है। समस्या का विवरण संदेश में भी लिखें।',
      en: 'The attachment is shown only in this demo chat. It is not uploaded to a backend or analyzed. Please also describe the problem in your message.',
    )}';
  }

  String _marathiReply(String q) {
    if (_matches(q, ['पाणी', 'पाणीपुरवठा', 'water', 'pani', 'जल'])) {
      return 'पाणीपुरवठ्याची समस्या नोंदवण्यासाठी “समस्या नोंदवा” निवडा. गाव/परिसर, पाणी कधीपासून आले नाही आणि इतर संबंधित तपशील लिहा.';
    }
    if (_matches(q, ['वीज', 'बिजली', 'light', 'electricity', 'power'])) {
      return 'वीज किंवा पथदिव्याच्या समस्येसाठी “समस्या नोंदवा” निवडा. नेमके ठिकाण, समस्या कधीपासून आहे आणि प्रभावित परिसराचे वर्णन द्या.';
    }
    if (_matches(q, ['रस्ता', 'सड़क', 'road', 'खड्डा', 'गड्ढा'])) {
      return 'रस्त्याच्या समस्येसाठी “समस्या नोंदवा” निवडा. रस्त्याचे ठिकाण आणि नुकसानाचे वर्णन द्या. शक्य असल्यास तक्रारीत फोटोही जोडा.';
    }
    if (_matches(
        q, ['कचरा', 'स्वच्छता', 'कूड़ा', 'garbage', 'cleanliness', 'सफाई'])) {
      return 'कचरा किंवा स्वच्छतेच्या समस्येसाठी “समस्या नोंदवा” निवडा. कचरा कुठे साचला आहे, किती दिवसांपासून आणि परिसराचे वर्णन द्या.';
    }
    if (_matches(q, [
      'दस्तऐवज',
      'दस्तावेज',
      'कागदपत्र',
      'document',
      'आधार',
      'प्रमाणपत्र'
    ])) {
      return 'दस्तऐवज किंवा प्रमाणपत्रासाठी आवश्यक कागदपत्रे व कार्यालयीन वेळ ग्रामपंचायत कार्यालयात निश्चित करा. अडचण नोंदवायची असल्यास “समस्या नोंदवा” निवडा.';
    }
    if (_matches(
        q, ['शाळा', 'शिक्षण', 'school', 'education', 'अभ्यासिका', 'स्कूल'])) {
      return 'शाळा किंवा शिक्षण सुविधेच्या समस्येसाठी “समस्या नोंदवा” निवडा. शाळेचे नाव/ठिकाण, अडचण आणि ती कोणावर परिणाम करते हे लिहा.';
    }
    if (_matches(
        q, ['cctv', 'सुरक्षा', 'सुरक्षा', 'चोरी', 'camera', 'security'])) {
      return 'CCTV किंवा गावाच्या सुरक्षेच्या समस्येसाठी “समस्या नोंदवा” निवडा. ठिकाण आणि नेमकी अडचण द्या. तातडीचा धोका असल्यास स्थानिक आपत्कालीन सेवांशी संपर्क करा.';
    }
    if (_matches(
        q, ['शेती', 'खेती', 'farming', 'farmer', 'पीक', 'crop', 'किसान'])) {
      return 'शेतीविषयक स्थानिक सुविधेच्या समस्येसाठी “समस्या नोंदवा” निवडा. शेताचे ठिकाण, पीक आणि आवश्यक मदतीचे वर्णन द्या. कृषी सल्ल्यासाठी स्थानिक कृषी अधिकाऱ्यांशीही संपर्क करा.';
    }
    if (_matches(q, [
      'आरोग्य',
      'वैद्यकीय',
      'दवाखाना',
      'health',
      'medical',
      'doctor',
      'hospital',
      'स्वास्थ्य'
    ])) {
      return 'आरोग्य किंवा वैद्यकीय सेवेच्या उपलब्धतेच्या समस्येसाठी “समस्या नोंदवा” निवडा आणि केंद्राचे ठिकाण व अडचण नमूद करा. तातडीच्या वैद्यकीय गरजेसाठी स्थानिक आपत्कालीन सेवांशी संपर्क करा.';
    }
    if (_matches(q, ['तक्रार', 'शिकायत', 'complaint', 'report problem'])) {
      return 'तक्रार नोंदवण्यासाठी Home वरील “समस्या नोंदवा” निवडा. प्रकार, ठिकाण आणि समस्येचे वर्णन भरा; त्यानंतर तपशील तपासून सबमिट करा.';
    }
    if (_isGreeting(q)) {
      return 'नमस्कार! गावातील कोणत्या समस्येसाठी मदत हवी आहे? पाणी, वीज, रस्ते, स्वच्छता, कागदपत्रे, शिक्षण, सुरक्षा, शेती किंवा आरोग्याबद्दल विचारा.';
    }
    return 'मी गावातील सेवा आणि समस्या नोंदवण्याबाबत प्राथमिक मार्गदर्शन देऊ शकतो. कृपया समस्या, गाव/परिसर आणि ती कधीपासून आहे हे सांगा. नोंदणीसाठी “समस्या नोंदवा” वापरा.';
  }

  String _hindiReply(String q) {
    if (_matches(q, ['पानी', 'जल', 'water', 'pani'])) {
      return 'पानी की समस्या दर्ज करने के लिए “समस्या दर्ज करें” चुनें। गाँव/इलाके का नाम, पानी कब से नहीं आया और अन्य जरूरी जानकारी लिखें।';
    }
    if (_matches(q, ['बिजली', 'लाइट', 'light', 'electricity', 'power'])) {
      return 'बिजली या स्ट्रीट लाइट की समस्या के लिए “समस्या दर्ज करें” चुनें। सही स्थान, समस्या कब से है और प्रभावित इलाके का विवरण दें।';
    }
    if (_matches(q, ['सड़क', 'सडक', 'road', 'गड्ढा', 'खड्डा'])) {
      return 'सड़क की समस्या के लिए “समस्या दर्ज करें” चुनें। सड़क का स्थान और नुकसान का विवरण दें। संभव हो तो शिकायत में फ़ोटो भी जोड़ें।';
    }
    if (_matches(
        q, ['कचरा', 'सफाई', 'स्वच्छता', 'कूड़ा', 'garbage', 'cleanliness'])) {
      return 'कचरे या सफाई की समस्या के लिए “समस्या दर्ज करें” चुनें। कचरा कहाँ जमा है, कब से है और आसपास के क्षेत्र का विवरण दें।';
    }
    if (_matches(q, [
      'दस्तावेज',
      'दस्तऐवज',
      'कागदपत्र',
      'document',
      'आधार',
      'प्रमाणपत्र'
    ])) {
      return 'दस्तावेज़ या प्रमाणपत्र के लिए जरूरी कागज़ और कार्यालय का समय ग्राम पंचायत कार्यालय से सुनिश्चित करें। समस्या दर्ज करने के लिए “समस्या दर्ज करें” चुनें।';
    }
    if (_matches(q, ['स्कूल', 'शिक्षा', 'school', 'education', 'अभ्यासिका'])) {
      return 'स्कूल या शिक्षा सुविधा की समस्या के लिए “समस्या दर्ज करें” चुनें। स्कूल का नाम/स्थान, समस्या और उससे प्रभावित लोगों का विवरण लिखें।';
    }
    if (_matches(q, ['cctv', 'सुरक्षा', 'चोरी', 'camera', 'security'])) {
      return 'CCTV या गाँव की सुरक्षा की समस्या के लिए “समस्या दर्ज करें” चुनें। स्थान और समस्या का विवरण दें। तत्काल खतरे में स्थानीय आपातकालीन सेवाओं से संपर्क करें।';
    }
    if (_matches(q, ['खेती', 'किसान', 'farming', 'farmer', 'फसल', 'crop'])) {
      return 'खेती से जुड़ी स्थानीय सुविधा की समस्या के लिए “समस्या दर्ज करें” चुनें। खेत का स्थान, फसल और जरूरी सहायता का विवरण दें। कृषि सलाह के लिए स्थानीय कृषि अधिकारी से भी संपर्क करें।';
    }
    if (_matches(q, [
      'स्वास्थ्य',
      'चिकित्सा',
      'अस्पताल',
      'health',
      'medical',
      'doctor',
      'hospital'
    ])) {
      return 'स्वास्थ्य या चिकित्सा सेवा की उपलब्धता की समस्या के लिए “समस्या दर्ज करें” चुनें और केंद्र का स्थान व समस्या लिखें। तत्काल चिकित्सा जरूरत में स्थानीय आपातकालीन सेवाओं से संपर्क करें।';
    }
    if (_matches(q, ['तक्रार', 'शिकायत', 'complaint', 'report problem'])) {
      return 'शिकायत दर्ज करने के लिए Home पर “समस्या दर्ज करें” चुनें। प्रकार, स्थान और समस्या का विवरण भरें, फिर जाँचकर जमा करें।';
    }
    if (_isGreeting(q)) {
      return 'नमस्ते! गाँव की किस समस्या में मदद चाहिए? पानी, बिजली, सड़क, सफाई, दस्तावेज़, शिक्षा, सुरक्षा, खेती या स्वास्थ्य के बारे में पूछें।';
    }
    return 'मैं गाँव की सेवाओं और समस्या दर्ज करने के बारे में प्रारंभिक मार्गदर्शन दे सकता हूँ। समस्या, गाँव/इलाका और यह कब से है, बताएं। शिकायत दर्ज करने के लिए “समस्या दर्ज करें” चुनें।';
  }

  String _englishReply(String q) {
    if (_matches(q, ['पाणी', 'पानी', 'water', 'pani'])) {
      return 'To report a water-supply problem, choose “Report a problem.” Include your village/area, when the supply stopped, and any useful details.';
    }
    if (_matches(q, ['वीज', 'बिजली', 'light', 'electricity', 'power'])) {
      return 'For an electricity or street-light problem, choose “Report a problem.” Give the exact location, when it began, and which area is affected.';
    }
    if (_matches(q, ['रस्ता', 'सड़क', 'road', 'खड्डा', 'गड्ढा'])) {
      return 'For a road problem, choose “Report a problem.” Describe the road location and damage. Add a photo to the complaint if possible.';
    }
    if (_matches(q, [
      'कचरा',
      'स्वच्छता',
      'कूड़ा',
      'garbage',
      'cleanliness',
      'sanitation'
    ])) {
      return 'For a garbage or cleanliness problem, choose “Report a problem.” Describe where waste has collected, how long it has been there, and the nearby area.';
    }
    if (_matches(q, [
      'दस्तऐवज',
      'दस्तावेज',
      'कागदपत्र',
      'document',
      'आधार',
      'certificate'
    ])) {
      return 'For a document or certificate, confirm the required papers and office hours with the village council. Choose “Report a problem” if you need to report an issue.';
    }
    if (_matches(
        q, ['शाळा', 'स्कूल', 'शिक्षा', 'school', 'education', 'अभ्यासिका'])) {
      return 'For a school or education-facility problem, choose “Report a problem.” Include the school name/location, what is wrong, and who is affected.';
    }
    if (_matches(
        q, ['cctv', 'सुरक्षा', 'चोरी', 'camera', 'security', 'theft'])) {
      return 'For a CCTV or village-safety concern, choose “Report a problem” and include the location and details. Contact local emergency services if there is immediate danger.';
    }
    if (_matches(
        q, ['शेती', 'खेती', 'farming', 'farmer', 'पीक', 'फसल', 'crop'])) {
      return 'For a local farming-service problem, choose “Report a problem.” Include the field location, crop, and help needed. Contact a local agriculture officer for farming advice.';
    }
    if (_matches(q, [
      'आरोग्य',
      'स्वास्थ्य',
      'वैद्यकीय',
      'health',
      'medical',
      'doctor',
      'hospital'
    ])) {
      return 'For a health-service availability problem, choose “Report a problem” and include the facility location and issue. Contact local emergency services for urgent medical needs.';
    }
    if (_matches(q, ['तक्रार', 'शिकायत', 'complaint', 'report problem'])) {
      return 'To submit a complaint, choose “Report a problem” on Home. Enter the category, location, and description, then review and submit it.';
    }
    if (_isGreeting(q)) {
      return 'Hello! What village issue can I help with? Ask about water, electricity, roads, cleanliness, documents, education, safety, farming, or health services.';
    }
    return 'I can offer basic guidance about village services and reporting problems. Please describe the issue, your village/area, and when it started. Choose “Report a problem” to submit it.';
  }

  bool _matches(String input, List<String> terms) {
    return terms.any(input.contains);
  }

  bool _isGreeting(String input) {
    final normalized = input.trim();
    return normalized == 'hi' ||
        normalized == 'hey' ||
        normalized == 'नमस्कार' ||
        normalized == 'नमस्ते' ||
        normalized.contains('hello');
  }

  Future<void> _sendMessage() async {
    if (_isResponding) return;

    final question = _controller.text.trim();
    final imageBytes = _pendingImageBytes;
    final imageName = _pendingImageName;
    final fileName = _pendingFileName;
    final hasAttachment = imageBytes != null || fileName != null;
    if (question.isEmpty && !hasAttachment) return;

    setState(() {
      _messages.add(_ChatMessage(
        isUser: true,
        text: question,
        imageBytes: imageBytes,
        fileName: imageName ?? fileName,
      ));
      _controller.clear();
      _pendingImageBytes = null;
      _pendingImageName = null;
      _pendingFileName = null;
      _isResponding = true;
    });
    _scrollToLatest();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(
        responseQuestion: question,
        hasAttachment: hasAttachment,
      ));
      _isResponding = false;
    });
    _scrollToLatest();
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _messages
        ..clear()
        ..add(const _ChatMessage(isWelcome: true));
      _controller.clear();
      _pendingImageBytes = null;
      _pendingImageName = null;
      _pendingFileName = null;
    });
    await _scrollToLatest();
  }

  Future<void> _scrollToLatest() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openVoiceInput() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => VoiceRecordingScreen(
          language: AppLanguage.instance.language,
          onVoiceResult: (_) {},
        ),
      ),
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    final currentText = _controller.text.trim();
    _controller
      ..text =
          currentText.isEmpty ? result.trim() : '$currentText ${result.trim()}'
      ..selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (photo == null) return;

      final size = await photo.length();
      if (size > maxAttachmentBytes) {
        _showMessage(_say(
          mr: 'फोटोचा आकार १० MB पेक्षा जास्त नसावा.',
          hi: 'फ़ोटो का आकार १० MB से अधिक नहीं होना चाहिए।',
          en: 'The photo must be 10 MB or smaller.',
        ));
        return;
      }

      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageName = photo.name;
        _pendingFileName = null;
      });
    } catch (error) {
      debugPrint('Could not select assistant photo: $error');
      _showMessage(_say(
        mr: 'फोटो निवडता आला नाही. पुन्हा प्रयत्न करा.',
        hi: 'फ़ोटो नहीं चुनी जा सकी। फिर से प्रयास करें।',
        en: 'Could not select the photo. Please try again.',
      ));
    }
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isEmpty) return;

      final file = files.single;
      final extension = file.extension?.toLowerCase();
      if (extension == null || !allowedFileExtensions.contains(extension)) {
        _showMessage(_say(
          mr: 'या प्रकारची फाइल समर्थित नाही. PDF, TXT, DOC किंवा DOCX निवडा.',
          hi: 'यह फ़ाइल प्रकार समर्थित नहीं है। PDF, TXT, DOC या DOCX चुनें।',
          en: 'This file type is not supported. Choose a PDF, TXT, DOC, or DOCX file.',
        ));
        return;
      }
      final fileSize = await file.length();
      if (fileSize == null) {
        _showMessage(_say(
          mr: 'फाइलचा आकार तपासता आला नाही. दुसरी फाइल निवडा.',
          hi: 'फ़ाइल का आकार जाँचा नहीं जा सका। दूसरी फ़ाइल चुनें।',
          en: 'Could not verify the file size. Choose another file.',
        ));
        return;
      }
      if (fileSize > maxAttachmentBytes) {
        _showMessage(_say(
          mr: 'फाइलचा आकार १० MB पेक्षा जास्त नसावा.',
          hi: 'फ़ाइल का आकार १० MB से अधिक नहीं होना चाहिए।',
          en: 'The file must be 10 MB or smaller.',
        ));
        return;
      }

      if (!mounted) return;
      setState(() {
        _pendingFileName = file.name;
        _pendingImageBytes = null;
        _pendingImageName = null;
      });
    } catch (error) {
      debugPrint('Could not select assistant file: $error');
      _showMessage(_say(
        mr: 'फाइल निवडता आली नाही. पुन्हा प्रयत्न करा.',
        hi: 'फ़ाइल नहीं चुनी जा सकी। फिर से प्रयास करें।',
        en: 'Could not select the file. Please try again.',
      ));
    }
  }

  Future<void> _openAttachment() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_say(
                mr: 'गॅलरीतून फोटो निवडा',
                hi: 'गैलरी से फ़ोटो चुनें',
                en: 'Choose a photo from gallery',
              )),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(_say(
                mr: 'फाइल निवडा',
                hi: 'फ़ाइल चुनें',
                en: 'Choose a file',
              )),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePendingAttachment() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageName = null;
      _pendingFileName = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, translate: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FB),
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: Text(
          _say(mr: 'AI सहाय्यक', hi: 'AI सहायक', en: 'AI Assistant'),
          translate: false,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _say(
              mr: 'नवीन संभाषण',
              hi: 'नई बातचीत',
              en: 'New conversation',
            ),
            onPressed: _isResponding ? null : _startNewConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFEDE3FA),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: purple,
                      child: Icon(
                        Icons.psychology_alt_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _say(
                              mr: 'ग्रामसक्षम सहाय्यक',
                              hi: 'ग्रामसक्षम सहायक',
                              en: 'GramSaksham assistant',
                            ),
                            translate: false,
                            style: const TextStyle(
                              color: darkPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _say(
                              mr: 'डेमो सहाय्यक • backend जोडलेला नाही',
                              hi: 'डेमो सहायक • backend जुड़ा नहीं है',
                              en: 'Demo assistant • no backend connected',
                            ),
                            translate: false,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length + (_isResponding ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isResponding && index == _messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final message = _messages[index];
                    return _messageBubble(message);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _suggestion('पाणी आले नाही'),
                  _suggestion('दस्तऐवज समस्या'),
                  _suggestion('रस्त्याची समस्या'),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pendingImageBytes != null ||
                          _pendingFileName != null)
                        _pendingAttachmentPreview(),
                      Row(
                        children: [
                          IconButton(
                            tooltip: _say(
                              mr: 'बोलून सांगा',
                              hi: 'बोलकर बताएं',
                              en: 'Use voice input',
                            ),
                            onPressed: _isResponding ? null : _openVoiceInput,
                            icon: const Icon(Icons.mic_none_rounded),
                            color: purple,
                          ),
                          IconButton(
                            tooltip: _say(
                              mr: 'फोटो किंवा फाइल जोडा',
                              hi: 'फ़ोटो या फ़ाइल जोड़ें',
                              en: 'Attach a photo or file',
                            ),
                            onPressed: _isResponding ? null : _openAttachment,
                            icon: const Icon(Icons.add_rounded),
                            color: purple,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: _say(
                                  mr: 'तुमचा प्रश्न लिहा...',
                                  hi: 'अपना प्रश्न लिखें...',
                                  en: 'Type your question...',
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF6F2FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: _isResponding ? null : _sendMessage,
                            style: IconButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  purple.withValues(alpha: 0.4),
                              disabledForegroundColor: Colors.white70,
                            ),
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: message.isUser ? purple : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: message.isUser
              ? null
              : Border.all(color: const Color(0xFFE1D6EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  message.imageBytes!,
                  width: 220,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              if (message.fileName != null) const SizedBox(height: 6),
            ],
            if (message.fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.imageBytes == null
                          ? Icons.insert_drive_file_outlined
                          : Icons.image_outlined,
                      size: 18,
                      color: message.isUser ? Colors.white : purple,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message.fileName!,
                        translate: false,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : darkPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (message.hasContent)
              Text(
                message.isWelcome
                    ? _welcomeMessage()
                    : message.responseQuestion == null
                        ? message.text
                        : _getReply(
                            message.responseQuestion!,
                            hasAttachment: message.hasAttachment,
                          ),
                translate: false,
                style: TextStyle(
                  height: 1.4,
                  color: message.isUser ? Colors.white : darkPurple,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pendingAttachmentPreview() {
    final imageBytes = _pendingImageBytes;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                imageBytes,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            )
          else
            const Icon(Icons.insert_drive_file_outlined, color: purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pendingImageName ?? _pendingFileName ?? '',
              translate: false,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: _say(mr: 'काढून टाका', hi: 'हटाएँ', en: 'Remove'),
            onPressed: _removePendingAttachment,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _suggestion(String marathiText) {
    return ActionChip(
      label: Text(marathiText),
      onPressed: _isResponding
          ? null
          : () {
              _controller.text = AppLanguage.instance.translate(marathiText);
              _sendMessage();
            },
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE1D6EF)),
      labelStyle: const TextStyle(
        color: darkPurple,
        fontSize: 12,
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final bool isWelcome;
  final String text;
  final String? responseQuestion;
  final bool hasAttachment;
  final Uint8List? imageBytes;
  final String? fileName;

  const _ChatMessage({
    this.isUser = false,
    this.isWelcome = false,
    this.text = '',
    this.responseQuestion,
    this.hasAttachment = false,
    this.imageBytes,
    this.fileName,
  });

  bool get hasContent =>
      isWelcome || responseQuestion != null || text.isNotEmpty;
}
