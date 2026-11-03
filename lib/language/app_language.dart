import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  static final AppLanguage instance = AppLanguage._();

  AppLanguage._();

  String _language = 'Marathi';
  SharedPreferences? _preferences;

  static const supportedLocales = [
    Locale('mr'),
    Locale('hi'),
    Locale('en'),
  ];

  String get language => _language;

  Locale get locale => switch (_language) {
        'Hindi' => const Locale('hi'),
        'English' => const Locale('en'),
        _ => const Locale('mr'),
      };

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    _language = _preferences!.getString('app_language') ?? 'Marathi';
  }

  Future<void> setLanguage(String value) async {
    if (value != 'Marathi' && value != 'Hindi' && value != 'English') {
      throw ArgumentError.value(value, 'value', 'Unsupported app language');
    }
    if (_language == value) return;
    _language = value;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    final saved = await _preferences!.setString('app_language', value);
    if (!saved) {
      throw StateError('Could not save the selected app language.');
    }
  }

  String translate(String value) {
    final translations = _translations[value];
    return translations?[locale.languageCode] ?? value;
  }

  String text({
    required String mr,
    required String hi,
    required String en,
  }) {
    switch (_language) {
      case 'Hindi':
        return hi;
      case 'English':
        return en;
      default:
        return mr;
    }
  }

  static const Map<String, Map<String, String>> _translations = {
    'ग्रामसक्षम': {'mr': 'ग्रामसक्षम', 'hi': 'ग्रामसक्षम', 'en': 'GramSaksham'},
    'आपले स्वागत आहे': {
      'mr': 'आपले स्वागत आहे',
      'hi': 'आपका स्वागत है',
      'en': 'Welcome'
    },
    'मोबाईल नंबर': {
      'mr': 'मोबाईल नंबर',
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile number'
    },
    'पासवर्ड': {'mr': 'पासवर्ड', 'hi': 'पासवर्ड', 'en': 'Password'},
    '10 अंकी मोबाइल नंबर टाका': {
      'mr': '10 अंकी मोबाइल नंबर टाका',
      'hi': '10 अंकों का मोबाइल नंबर दर्ज करें',
      'en': 'Enter a 10-digit mobile number'
    },
    'पासवर्ड टाका': {
      'mr': 'पासवर्ड टाका',
      'hi': 'पासवर्ड दर्ज करें',
      'en': 'Enter your password'
    },
    'पासवर्ड विसरलात?': {
      'mr': 'पासवर्ड विसरलात?',
      'hi': 'पासवर्ड भूल गए?',
      'en': 'Forgot password?'
    },
    'Login': {'mr': 'लॉग इन', 'hi': 'लॉग इन', 'en': 'Login'},
    "Don't have an account?": {
      'mr': 'खाते नाही?',
      'hi': 'खाता नहीं है?',
      'en': "Don't have an account?"
    },
    'Register': {'mr': 'नोंदणी करा', 'hi': 'पंजीकरण करें', 'en': 'Register'},
    'Please register first!': {
      'mr': 'कृपया आधी नोंदणी करा!',
      'hi': 'कृपया पहले पंजीकरण करें!',
      'en': 'Please register first!'
    },
    'चुकीचा मोबाइल नंबर किंवा पासवर्ड!': {
      'mr': 'चुकीचा मोबाइल नंबर किंवा पासवर्ड!',
      'hi': 'गलत मोबाइल नंबर या पासवर्ड!',
      'en': 'Incorrect mobile number or password!'
    },
    'Password reset feature coming soon.': {
      'mr': 'पासवर्ड रीसेटची सुविधा लवकरच उपलब्ध होईल.',
      'hi': 'पासवर्ड रीसेट की सुविधा जल्द उपलब्ध होगी।',
      'en': 'Password reset feature coming soon.'
    },
    'नवीन खाते तयार करा': {
      'mr': 'नवीन खाते तयार करा',
      'hi': 'नया खाता बनाएँ',
      'en': 'Create a new account'
    },
    'ग्रामसक्षममध्ये आपले स्वागत आहे': {
      'mr': 'ग्रामसक्षममध्ये आपले स्वागत आहे',
      'hi': 'ग्रामसक्षम में आपका स्वागत है',
      'en': 'Welcome to GramSaksham'
    },
    'पूर्ण नाव': {'mr': 'पूर्ण नाव', 'hi': 'पूरा नाम', 'en': 'Full name'},
    'तुमचे पूर्ण नाव टाका': {
      'mr': 'तुमचे पूर्ण नाव टाका',
      'hi': 'अपना पूरा नाम दर्ज करें',
      'en': 'Enter your full name'
    },
    'कृपया तुमचे नाव टाका': {
      'mr': 'कृपया तुमचे नाव टाका',
      'hi': 'कृपया अपना नाम दर्ज करें',
      'en': 'Please enter your name'
    },
    '10 अंकी मोबाईल नंबर': {
      'mr': '10 अंकी मोबाईल नंबर',
      'hi': '10 अंकों का मोबाइल नंबर',
      'en': '10-digit mobile number'
    },
    'योग्य 10 अंकी मोबाईल नंबर टाका': {
      'mr': 'योग्य 10 अंकी मोबाईल नंबर टाका',
      'hi': 'सही 10 अंकों का मोबाइल नंबर दर्ज करें',
      'en': 'Enter a valid 10-digit mobile number'
    },
    'गावाचे नाव': {
      'mr': 'गावाचे नाव',
      'hi': 'गाँव का नाम',
      'en': 'Village name'
    },
    'तुमच्या गावाचे नाव टाका': {
      'mr': 'तुमच्या गावाचे नाव टाका',
      'hi': 'अपने गाँव का नाम दर्ज करें',
      'en': 'Enter your village name'
    },
    'कृपया गावाचे नाव टाका': {
      'mr': 'कृपया गावाचे नाव टाका',
      'hi': 'कृपया गाँव का नाम दर्ज करें',
      'en': 'Please enter your village name'
    },
    'पासवर्ड तयार करा': {
      'mr': 'पासवर्ड तयार करा',
      'hi': 'पासवर्ड बनाएँ',
      'en': 'Create a password'
    },
    'किमान 6 अक्षरे': {
      'mr': 'किमान 6 अक्षरे',
      'hi': 'कम से कम 6 अक्षर',
      'en': 'At least 6 characters'
    },
    'पासवर्ड किमान 6 अक्षरांचा असावा': {
      'mr': 'पासवर्ड किमान 6 अक्षरांचा असावा',
      'hi': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
      'en': 'Password must be at least 6 characters'
    },
    'पासवर्ड पुन्हा टाका': {
      'mr': 'पासवर्ड पुन्हा टाका',
      'hi': 'पासवर्ड फिर से दर्ज करें',
      'en': 'Re-enter password'
    },
    'दोन्ही पासवर्ड जुळत नाहीत': {
      'mr': 'दोन्ही पासवर्ड जुळत नाहीत',
      'hi': 'दोनों पासवर्ड मेल नहीं खाते',
      'en': 'Passwords do not match'
    },
    'Register करा': {
      'mr': 'नोंदणी करा',
      'hi': 'पंजीकरण करें',
      'en': 'Register'
    },
    'आधीच खाते आहे?': {
      'mr': 'आधीच खाते आहे?',
      'hi': 'पहले से खाता है?',
      'en': 'Already have an account?'
    },
    'ग्रामसक्षम • स्मार्ट व्हिलेज सेवा': {
      'mr': 'ग्रामसक्षम • स्मार्ट व्हिलेज सेवा',
      'hi': 'ग्रामसक्षम • स्मार्ट ग्राम सेवाएँ',
      'en': 'GramSaksham • Smart Village Services'
    },
    'Registration successful!': {
      'mr': 'नोंदणी यशस्वी झाली!',
      'hi': 'पंजीकरण सफल हुआ!',
      'en': 'Registration successful!'
    },
    'Registration failed. Please try again.': {
      'mr': 'नोंदणी अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      'hi': 'पंजीकरण विफल। कृपया फिर से प्रयास करें।',
      'en': 'Registration failed. Please try again.'
    },
    'नमस्कार!': {'mr': 'नमस्कार!', 'hi': 'नमस्ते!', 'en': 'Hello!'},
    'गावातील सेवा आणि सुविधांसाठी पर्याय निवडा.': {
      'mr': 'गावातील सेवा आणि सुविधांसाठी पर्याय निवडा.',
      'hi': 'गाँव की सेवाओं और सुविधाओं के लिए विकल्प चुनें।',
      'en': 'Choose an option for village services and facilities.'
    },
    'समस्या नोंदवा': {
      'mr': 'समस्या नोंदवा',
      'hi': 'समस्या दर्ज करें',
      'en': 'Report a problem'
    },
    'माझ्या तक्रारी': {
      'mr': 'माझ्या तक्रारी',
      'hi': 'मेरी शिकायतें',
      'en': 'My complaints'
    },
    'सूचना': {'mr': 'सूचना', 'hi': 'सूचनाएँ', 'en': 'Notifications'},
    'AI सहाय्यक': {'mr': 'AI सहाय्यक', 'hi': 'AI सहायक', 'en': 'AI assistant'},
    'Report Problem': {
      'mr': 'समस्या नोंदवा',
      'hi': 'समस्या दर्ज करें',
      'en': 'Report Problem'
    },
    'My Complaints': {
      'mr': 'माझ्या तक्रारी',
      'hi': 'मेरी शिकायतें',
      'en': 'My Complaints'
    },
    'Notifications': {'mr': 'सूचना', 'hi': 'सूचनाएँ', 'en': 'Notifications'},
    'AI Assistant': {
      'mr': 'AI सहाय्यक',
      'hi': 'AI सहायक',
      'en': 'AI Assistant'
    },
    'Home': {'mr': 'मुख्यपृष्ठ', 'hi': 'होम', 'en': 'Home'},
    'Complaints': {'mr': 'तक्रारी', 'hi': 'शिकायतें', 'en': 'Complaints'},
    'Profile': {'mr': 'प्रोफाइल', 'hi': 'प्रोफ़ाइल', 'en': 'Profile'},
    'गावातील समस्या नोंदवा आणि उपलब्ध सेवांसाठी मदत मिळवा.': {
      'mr': 'गावातील समस्या नोंदवा आणि उपलब्ध सेवांसाठी मदत मिळवा.',
      'hi': 'गाँव की समस्याएँ दर्ज करें और उपलब्ध सेवाओं में सहायता पाएँ।',
      'en': 'Report village problems and get help with available services.'
    },
    'Profile लवकरच उपलब्ध होईल.': {
      'mr': 'प्रोफाइल लवकरच उपलब्ध होईल.',
      'hi': 'प्रोफ़ाइल जल्द उपलब्ध होगी।',
      'en': 'Profile will be available soon.'
    },
    'पाणी समस्या': {
      'mr': 'पाणी समस्या',
      'hi': 'पानी की समस्या',
      'en': 'Water problem'
    },
    'वीज समस्या': {
      'mr': 'वीज समस्या',
      'hi': 'बिजली की समस्या',
      'en': 'Electricity problem'
    },
    'रस्ता समस्या': {
      'mr': 'रस्ता समस्या',
      'hi': 'सड़क की समस्या',
      'en': 'Road problem'
    },
    'स्वच्छता': {'mr': 'स्वच्छता', 'hi': 'स्वच्छता', 'en': 'Cleanliness'},
    'दस्तऐवज': {'mr': 'दस्तऐवज', 'hi': 'दस्तावेज़', 'en': 'Documents'},
    'अभ्यासिका': {
      'mr': 'अभ्यासिका',
      'hi': 'अध्ययन केंद्र',
      'en': 'Study centre'
    },
    'CCTV / सुरक्षा': {
      'mr': 'CCTV / सुरक्षा',
      'hi': 'CCTV / सुरक्षा',
      'en': 'CCTV / Security'
    },
    'शेती': {'mr': 'शेती', 'hi': 'खेती', 'en': 'Farming'},
    'वैद्यकीय सेवा': {
      'mr': 'वैद्यकीय सेवा',
      'hi': 'चिकित्सा सेवा',
      'en': 'Medical services'
    },
    'इतर समस्या': {
      'mr': 'इतर समस्या',
      'hi': 'अन्य समस्या',
      'en': 'Other problem'
    },
    'Birth Certificate': {
      'mr': 'जन्म प्रमाणपत्र',
      'hi': 'जन्म प्रमाण पत्र',
      'en': 'Birth Certificate'
    },
    'Caste Certificate': {
      'mr': 'जात प्रमाणपत्र',
      'hi': 'जाति प्रमाण पत्र',
      'en': 'Caste Certificate'
    },
    'Income Certificate': {
      'mr': 'उत्पन्न प्रमाणपत्र',
      'hi': 'आय प्रमाण पत्र',
      'en': 'Income Certificate'
    },
    'Domicile Certificate': {
      'mr': 'अधिवास प्रमाणपत्र',
      'hi': 'निवास प्रमाण पत्र',
      'en': 'Domicile Certificate'
    },
    'Residence Certificate': {
      'mr': 'रहिवासी प्रमाणपत्र',
      'hi': 'निवास प्रमाण पत्र',
      'en': 'Residence Certificate'
    },
    'Death Certificate': {
      'mr': 'मृत्यू प्रमाणपत्र',
      'hi': 'मृत्यु प्रमाण पत्र',
      'en': 'Death Certificate'
    },
    'Marriage Certificate': {
      'mr': 'विवाह प्रमाणपत्र',
      'hi': 'विवाह प्रमाण पत्र',
      'en': 'Marriage Certificate'
    },
    'Ration Card': {
      'mr': 'रेशन कार्ड',
      'hi': 'राशन कार्ड',
      'en': 'Ration Card'
    },
    'Aadhaar Card Issue': {
      'mr': 'आधार कार्ड समस्या',
      'hi': 'आधार कार्ड समस्या',
      'en': 'Aadhaar Card Issue'
    },
    'Other Documents': {
      'mr': 'इतर दस्तऐवज',
      'hi': 'अन्य दस्तावेज़',
      'en': 'Other Documents'
    },
    'दस्तऐवज सेवा': {
      'mr': 'दस्तऐवज सेवा',
      'hi': 'दस्तावेज़ सेवा',
      'en': 'Document services'
    },
    'तुमचा आवश्यक दस्तऐवज निवडा': {
      'mr': 'तुमचा आवश्यक दस्तऐवज निवडा',
      'hi': 'अपना आवश्यक दस्तावेज़ चुनें',
      'en': 'Select the document you need'
    },
    'दस्तऐवज शोधा...': {
      'mr': 'दस्तऐवज शोधा...',
      'hi': 'दस्तावेज़ खोजें...',
      'en': 'Search documents...'
    },
    'दस्तऐवज सापडला नाही.': {
      'mr': 'दस्तऐवज सापडला नाही.',
      'hi': 'कोई दस्तावेज़ नहीं मिला।',
      'en': 'No documents found.'
    },
    'निवड निश्चित करा': {
      'mr': 'निवड निश्चित करा',
      'hi': 'चयन की पुष्टि करें',
      'en': 'Confirm selection'
    },
    'निवडलेला दस्तऐवज': {
      'mr': 'निवडलेला दस्तऐवज',
      'hi': 'चुना गया दस्तावेज़',
      'en': 'Selected document'
    },
    'तुमची समस्या सांगा': {
      'mr': 'तुमची समस्या सांगा',
      'hi': 'अपनी समस्या बताएँ',
      'en': 'Tell us about your problem'
    },
    'लिहा, बोलून सांगा किंवा फोटो जोडा.': {
      'mr': 'लिहा, बोलून सांगा किंवा फोटो जोडा.',
      'hi': 'लिखें, बोलकर बताएँ या फ़ोटो जोड़ें।',
      'en': 'Write, speak, or add a photo.'
    },
    '१. तक्रारीची भाषा': {
      'mr': '१. तक्रारीची भाषा',
      'hi': '१. शिकायत की भाषा',
      'en': '1. Complaint language'
    },
    '२. समस्येचा प्रकार निवडा': {
      'mr': '२. समस्येचा प्रकार निवडा',
      'hi': '२. समस्या का प्रकार चुनें',
      'en': '2. Choose a problem type'
    },
    '३. समस्येचे ठिकाण': {
      'mr': '३. समस्येचे ठिकाण',
      'hi': '३. समस्या का स्थान',
      'en': '3. Problem location'
    },
    '४. समस्येचे वर्णन': {
      'mr': '४. समस्येचे वर्णन',
      'hi': '४. समस्या का विवरण',
      'en': '4. Problem description'
    },
    '५. फोटो / व्हिडिओ जोडा': {
      'mr': '५. फोटो / व्हिडिओ जोडा',
      'hi': '५. फ़ोटो / वीडियो जोड़ें',
      'en': '5. Add a photo / video'
    },
    'भाषा निवडा': {
      'mr': 'भाषा निवडा',
      'hi': 'भाषा चुनें',
      'en': 'Select language'
    },
    'समस्येचे ठिकाण लिहा.': {
      'mr': 'समस्येचे ठिकाण लिहा.',
      'hi': 'समस्या का स्थान लिखें।',
      'en': 'Enter the problem location.'
    },
    'गाव / परिसर / ठिकाण लिहा': {
      'mr': 'गाव / परिसर / ठिकाण लिहा',
      'hi': 'गाँव / क्षेत्र / स्थान लिखें',
      'en': 'Enter village / area / location'
    },
    'गाव / परिसर / GPS coordinates': {
      'mr': 'गाव / परिसर / GPS coordinates',
      'hi': 'गाँव / क्षेत्र / GPS निर्देशांक',
      'en': 'Village / area / GPS coordinates'
    },
    'उदा. आमच्या गावात तीन दिवसांपासून पाणी आले नाही.': {
      'mr': 'उदा. आमच्या गावात तीन दिवसांपासून पाणी आले नाही.',
      'hi': 'उदा. हमारे गाँव में तीन दिनों से पानी नहीं आया है।',
      'en': 'Example: Our village has had no water for three days.'
    },
    'किमान १० अक्षरांत समस्या लिहा.': {
      'mr': 'किमान १० अक्षरांत समस्या लिहा.',
      'hi': 'समस्या कम से कम 10 अक्षरों में लिखें।',
      'en': 'Describe the problem in at least 10 characters.'
    },
    'बोलून तक्रार सांगा': {
      'mr': 'बोलून तक्रार सांगा',
      'hi': 'बोलकर शिकायत बताएँ',
      'en': 'Speak your complaint'
    },
    'फोटो निवडा': {
      'mr': 'फोटो निवडा',
      'hi': 'फ़ोटो चुनें',
      'en': 'Choose photo'
    },
    'व्हिडिओ निवडा': {
      'mr': 'व्हिडिओ निवडा',
      'hi': 'वीडियो चुनें',
      'en': 'Choose video'
    },
    'पुढे जा — तक्रार तपासा': {
      'mr': 'पुढे जा — तक्रार तपासा',
      'hi': 'आगे बढ़ें — शिकायत जाँचें',
      'en': 'Continue — review complaint'
    },
    'कृपया समस्येचा प्रकार निवडा.': {
      'mr': 'कृपया समस्येचा प्रकार निवडा.',
      'hi': 'कृपया समस्या का प्रकार चुनें।',
      'en': 'Please choose a problem type.'
    },
    'कृपया दस्तऐवजाचा प्रकार निवडा.': {
      'mr': 'कृपया दस्तऐवजाचा प्रकार निवडा.',
      'hi': 'कृपया दस्तावेज़ का प्रकार चुनें।',
      'en': 'Please choose a document type.'
    },
    'फोटो किंवा व्हिडिओ निवडता आला नाही.': {
      'mr': 'फोटो किंवा व्हिडिओ निवडता आला नाही.',
      'hi': 'फ़ोटो या वीडियो नहीं चुना जा सका।',
      'en': 'Could not select the photo or video.'
    },
    'तक्रारीचा आढावा': {
      'mr': 'तक्रारीचा आढावा',
      'hi': 'शिकायत की समीक्षा',
      'en': 'Complaint review'
    },
    'तक्रार तपासून घ्या': {
      'mr': 'तक्रार तपासून घ्या',
      'hi': 'शिकायत की जाँच करें',
      'en': 'Review your complaint'
    },
    'सबमिट करण्यापूर्वी माहिती तपासा.': {
      'mr': 'सबमिट करण्यापूर्वी माहिती तपासा.',
      'hi': 'जमा करने से पहले जानकारी जाँचें।',
      'en': 'Review the information before submitting.'
    },
    'तक्रारीचा प्रकार': {
      'mr': 'तक्रारीचा प्रकार',
      'hi': 'शिकायत का प्रकार',
      'en': 'Complaint type'
    },
    'ठिकाण': {'mr': 'ठिकाण', 'hi': 'स्थान', 'en': 'Location'},
    'ठिकाण दिलेले नाही': {
      'mr': 'ठिकाण दिलेले नाही',
      'hi': 'स्थान नहीं दिया गया',
      'en': 'Location not provided'
    },
    'तक्रारीचे वर्णन': {
      'mr': 'तक्रारीचे वर्णन',
      'hi': 'शिकायत का विवरण',
      'en': 'Complaint description'
    },
    'वर्णन दिलेले नाही': {
      'mr': 'वर्णन दिलेले नाही',
      'hi': 'विवरण नहीं दिया गया',
      'en': 'Description not provided'
    },
    'फोटो / व्हिडिओ': {
      'mr': 'फोटो / व्हिडिओ',
      'hi': 'फ़ोटो / वीडियो',
      'en': 'Photo / video'
    },
    'बदल करा': {'mr': 'बदल करा', 'hi': 'बदलें', 'en': 'Edit'},
    'सबमिट': {'mr': 'सबमिट', 'hi': 'जमा करें', 'en': 'Submit'},
    'माहिती योग्य असल्याची खात्री करा.': {
      'mr': 'माहिती योग्य असल्याची खात्री करा.',
      'hi': 'जानकारी सही होने की पुष्टि करें।',
      'en': 'Make sure the information is correct.'
    },
    'तक्रार सबमिट करायची?': {
      'mr': 'तक्रार सबमिट करायची?',
      'hi': 'शिकायत जमा करें?',
      'en': 'Submit this complaint?'
    },
    'तुम्ही दिलेली माहिती तपासून पुढे जायचे आहे का?': {
      'mr': 'तुम्ही दिलेली माहिती तपासून पुढे जायचे आहे का?',
      'hi': 'क्या आप दी गई जानकारी जाँचकर आगे बढ़ना चाहते हैं?',
      'en': 'Would you like to review the information and continue?'
    },
    'पुन्हा तपासा': {
      'mr': 'पुन्हा तपासा',
      'hi': 'फिर से जाँचें',
      'en': 'Review again'
    },
    'पुष्टी करा': {'mr': 'पुष्टी करा', 'hi': 'पुष्टि करें', 'en': 'Confirm'},
    'तक्रार सेव्ह झाली नाही:': {
      'mr': 'तक्रार सेव्ह झाली नाही:',
      'hi': 'शिकायत सहेजी नहीं गई:',
      'en': 'Complaint was not saved:'
    },
    'ऑफलाइन तक्रार जतन': {
      'mr': 'ऑफलाइन तक्रार जतन',
      'hi': 'ऑफ़लाइन शिकायत सहेजें',
      'en': 'Save complaint offline'
    },
    'तक्रार ऑफलाइन जतन झाली!': {
      'mr': 'तक्रार ऑफलाइन जतन झाली!',
      'hi': 'शिकायत ऑफ़लाइन सहेजी गई!',
      'en': 'Complaint saved offline!'
    },
    'इंटरनेट नसले तरी चिंता नाही': {
      'mr': 'इंटरनेट नसले तरी चिंता नाही',
      'hi': 'इंटरनेट न हो तो भी चिंता नहीं',
      'en': 'No internet? No problem'
    },
    'तक्रारीची माहिती तपासा आणि ऑफलाइन जतन प्रक्रिया सुरू करा.': {
      'mr': 'तक्रारीची माहिती तपासा आणि ऑफलाइन जतन प्रक्रिया सुरू करा.',
      'hi': 'शिकायत की जानकारी जाँचें और ऑफ़लाइन सहेजना शुरू करें।',
      'en': 'Review the complaint details and save it offline.'
    },
    'तक्रारीची माहिती': {
      'mr': 'तक्रारीची माहिती',
      'hi': 'शिकायत की जानकारी',
      'en': 'Complaint details'
    },
    'वर्णन': {'mr': 'वर्णन', 'hi': 'विवरण', 'en': 'Description'},
    'डेमो: जतन प्रक्रिया पूर्ण': {
      'mr': 'डेमो: जतन प्रक्रिया पूर्ण',
      'hi': 'डेमो: सहेजने की प्रक्रिया पूरी',
      'en': 'Demo: save completed'
    },
    'जतन करण्यासाठी तयार': {
      'mr': 'जतन करण्यासाठी तयार',
      'hi': 'सहेजने के लिए तैयार',
      'en': 'Ready to save'
    },
    'जतन करत आहे...': {
      'mr': 'जतन करत आहे...',
      'hi': 'सहेजा जा रहा है...',
      'en': 'Saving...'
    },
    'डेमो पूर्ण': {
      'mr': 'डेमो पूर्ण',
      'hi': 'डेमो पूरा',
      'en': 'Demo complete'
    },
    'ऑफलाइन जतन करा': {
      'mr': 'ऑफलाइन जतन करा',
      'hi': 'ऑफ़लाइन सहेजें',
      'en': 'Save offline'
    },
    'मागील स्क्रीनवर जा': {
      'mr': 'मागील स्क्रीनवर जा',
      'hi': 'पिछली स्क्रीन पर जाएँ',
      'en': 'Go to previous screen'
    },
    'समस्या नोंदवण्यासाठी समस्या नोंदवा हा पर्याय वापरा.': {
      'mr': 'गावातील समस्या नोंदवण्यासाठी समस्या नोंदवा हा पर्याय वापरा.',
      'hi': 'गाँव की समस्या दर्ज करने के लिए समस्या दर्ज करें विकल्प चुनें।',
      'en': 'Use Report a problem to report an issue in your village.'
    },
    'सूचना केंद्र': {
      'mr': 'सूचना केंद्र',
      'hi': 'सूचना केंद्र',
      'en': 'Notifications'
    },
    'ग्रामसक्षम सेवांबद्दल महत्त्वाची माहिती': {
      'mr': 'ग्रामसक्षम सेवांबद्दल महत्त्वाची माहिती',
      'hi': 'ग्रामसक्षम सेवाओं की महत्वपूर्ण जानकारी',
      'en': 'Important information about GramSaksham services'
    },
    'अलीकडील सूचना': {
      'mr': 'अलीकडील सूचना',
      'hi': 'हाल की सूचनाएँ',
      'en': 'Recent notifications'
    },
    'ग्रामसक्षममध्ये स्वागत!': {
      'mr': 'ग्रामसक्षममध्ये स्वागत!',
      'hi': 'ग्रामसक्षम में आपका स्वागत है!',
      'en': 'Welcome to GramSaksham!'
    },
    'गावातील समस्या नोंदवण्यासाठी समस्या नोंदवा हा पर्याय वापरा.': {
      'mr': 'गावातील समस्या नोंदवण्यासाठी समस्या नोंदवा हा पर्याय वापरा.',
      'hi': 'गाँव की समस्या दर्ज करने के लिए समस्या दर्ज करें विकल्प चुनें।',
      'en': 'Choose Report a problem to report an issue in your village.'
    },
    'तक्रार नोंदवण्याची सुविधा': {
      'mr': 'तक्रार नोंदवण्याची सुविधा',
      'hi': 'शिकायत दर्ज करने की सुविधा',
      'en': 'Complaint reporting'
    },
    'तुमची तक्रार सबमिट केल्यानंतर तिचा तपशील जतन करून ठेवा.': {
      'mr': 'तुमची तक्रार सबमिट केल्यानंतर तिचा तपशील जतन करून ठेवा.',
      'hi': 'शिकायत जमा करने के बाद उसका विवरण सुरक्षित रखें।',
      'en': 'Keep the details after submitting your complaint.'
    },
    'ग्रामपंचायत सेवा': {
      'mr': 'ग्रामपंचायत सेवा',
      'hi': 'ग्राम पंचायत सेवाएँ',
      'en': 'Village council services'
    },
    'सेवेसंबंधी अद्ययावत माहितीसाठी ग्रामपंचायत कार्यालयाशी संपर्क साधा.': {
      'mr':
          'सेवेसंबंधी अद्ययावत माहितीसाठी ग्रामपंचायत कार्यालयाशी संपर्क साधा.',
      'hi':
          'सेवाओं की नवीनतम जानकारी के लिए ग्राम पंचायत कार्यालय से संपर्क करें।',
      'en':
          'Contact the village council office for updated service information.'
    },
    'माहिती': {'mr': 'माहिती', 'hi': 'जानकारी', 'en': 'Info'},
    'तक्रारींचे अपडेट': {
      'mr': 'तक्रारींचे अपडेट',
      'hi': 'शिकायत अपडेट',
      'en': 'Complaint updates'
    },
    'टीप: या आवृत्तीत नमुना सूचना दाखवल्या आहेत. प्रत्यक्ष तक्रार अपडेट्स आणि मोबाइल push notifications दाखवण्यासाठी notification service/backend जोडणे आवश्यक आहे.':
        {
      'mr':
          'टीप: या आवृत्तीत नमुना सूचना दाखवल्या आहेत. प्रत्यक्ष तक्रार अपडेट्स आणि मोबाइल push notifications दाखवण्यासाठी notification service/backend जोडणे आवश्यक आहे.',
      'hi':
          'नोट: इस संस्करण में नमूना सूचनाएँ दिखाई गई हैं। वास्तविक शिकायत अपडेट और मोबाइल पुश सूचनाओं के लिए notification सेवा/backend जोड़ना होगा।',
      'en':
          'Note: This version shows sample notifications. A notification service/backend is needed for real complaint updates and mobile push notifications.'
    },
    'ग्रामसक्षम सहाय्यक': {
      'mr': 'ग्रामसक्षम सहाय्यक',
      'hi': 'ग्रामसक्षम सहायक',
      'en': 'GramSaksham assistant'
    },
    'गावातील सेवांसाठी प्राथमिक मदत': {
      'mr': 'गावातील सेवांसाठी प्राथमिक मदत',
      'hi': 'गाँव की सेवाओं के लिए प्रारंभिक सहायता',
      'en': 'Basic help for village services'
    },
    'तुमचा प्रश्न लिहा...': {
      'mr': 'तुमचा प्रश्न लिहा...',
      'hi': 'अपना प्रश्न लिखें...',
      'en': 'Type your question...'
    },
    'पाणी आले नाही': {
      'mr': 'पाणी आले नाही',
      'hi': 'पानी नहीं आया',
      'en': 'No water'
    },
    'दस्तऐवज समस्या': {
      'mr': 'दस्तऐवज समस्या',
      'hi': 'दस्तावेज़ की समस्या',
      'en': 'Document problem'
    },
    'रस्त्याची समस्या': {
      'mr': 'रस्त्याची समस्या',
      'hi': 'सड़क की समस्या',
      'en': 'Road problem'
    },
    'गावातील समस्या येथे नोंदवू शकता.': {
      'mr': 'गावातील समस्या येथे नोंदवू शकता.',
      'hi': 'आप यहाँ गाँव की समस्याएँ दर्ज कर सकते हैं।',
      'en': 'You can report village problems here.'
    },
    'Refresh': {'mr': 'रीफ्रेश', 'hi': 'रीफ़्रेश', 'en': 'Refresh'},
    'एकूण': {'mr': 'एकूण', 'hi': 'कुल', 'en': 'Total'},
    'प्रलंबित': {'mr': 'प्रलंबित', 'hi': 'लंबित', 'en': 'Pending'},
    'कार्यवाही सुरू': {
      'mr': 'कार्यवाही सुरू',
      'hi': 'कार्यवाही जारी',
      'en': 'In progress'
    },
    'निराकरण झाले': {
      'mr': 'निराकरण झाले',
      'hi': 'समाधान हुआ',
      'en': 'Resolved'
    },
    'पूर्ण': {'mr': 'पूर्ण', 'hi': 'पूर्ण', 'en': 'Completed'},
    'तक्रारींची यादी': {
      'mr': 'तक्रारींची यादी',
      'hi': 'शिकायतों की सूची',
      'en': 'Complaint list'
    },
    'पुन्हा प्रयत्न करा': {
      'mr': 'पुन्हा प्रयत्न करा',
      'hi': 'फिर से प्रयास करें',
      'en': 'Try again'
    },
    'अजून कोणतीही तक्रार सेव्ह केलेली नाही.': {
      'mr': 'अजून कोणतीही तक्रार सेव्ह केलेली नाही.',
      'hi': 'अभी तक कोई शिकायत सहेजी नहीं गई है।',
      'en': 'No complaints have been saved yet.'
    },
    'या स्थितीतील तक्रार उपलब्ध नाही.': {
      'mr': 'या स्थितीतील तक्रार उपलब्ध नाही.',
      'hi': 'इस स्थिति में कोई शिकायत उपलब्ध नहीं है।',
      'en': 'No complaints with this status.'
    },
    'नमस्कार, नागरिक!': {
      'mr': 'नमस्कार, नागरिक!',
      'hi': 'नमस्ते, नागरिक!',
      'en': 'Hello, citizen!'
    },
    'तुमच्या तक्रारींचा आढावा': {
      'mr': 'तुमच्या तक्रारींचा आढावा',
      'hi': 'आपकी शिकायतों का सारांश',
      'en': 'Your complaint summary'
    },
    'तक्रारींची स्थिती येथे तपासा.': {
      'mr': 'तक्रारींची स्थिती येथे तपासा.',
      'hi': 'शिकायतों की स्थिति यहाँ देखें।',
      'en': 'Check complaint status here.'
    },
    'Location service बंद आहे. कृपया GPS सुरू करा.': {
      'mr': 'Location service बंद आहे. कृपया GPS सुरू करा.',
      'hi': 'लोकेशन सेवा बंद है। कृपया GPS चालू करें।',
      'en': 'Location services are off. Please enable GPS.'
    },
    'GPS permission मिळाली नाही. पुन्हा प्रयत्न करा.': {
      'mr': 'GPS permission मिळाली नाही. पुन्हा प्रयत्न करा.',
      'hi': 'GPS अनुमति नहीं मिली। फिर से प्रयास करें।',
      'en': 'GPS permission was not granted. Please try again.'
    },
    'Location permission कायमची बंद आहे. Device settings मधून permission सुरू करा.':
        {
      'mr':
          'Location permission कायमची बंद आहे. Device settings मधून permission सुरू करा.',
      'hi':
          'लोकेशन अनुमति स्थायी रूप से बंद है। डिवाइस सेटिंग्स में इसे चालू करें।',
      'en':
          'Location permission is permanently denied. Enable it in device settings.'
    },
    'कृपया समस्येचे ठिकाण लिहा.': {
      'mr': 'कृपया समस्येचे ठिकाण लिहा.',
      'hi': 'कृपया समस्या का स्थान लिखें।',
      'en': 'Please enter the problem location.'
    },
    'GPS Location': {
      'mr': 'GPS स्थान',
      'hi': 'GPS स्थान',
      'en': 'GPS Location'
    },
    'तुमचे ठिकाण निश्चित करा': {
      'mr': 'तुमचे ठिकाण निश्चित करा',
      'hi': 'अपना स्थान तय करें',
      'en': 'Confirm your location'
    },
    'तक्रारीचे योग्य ठिकाण नोंदवण्यासाठी GPS location मिळवा.': {
      'mr': 'तक्रारीचे योग्य ठिकाण नोंदवण्यासाठी GPS location मिळवा.',
      'hi': 'शिकायत का सही स्थान दर्ज करने के लिए GPS लोकेशन प्राप्त करें।',
      'en': 'Get your GPS location to record the complaint accurately.'
    },
    'Current GPS Location': {
      'mr': 'सध्याचे GPS स्थान',
      'hi': 'वर्तमान GPS स्थान',
      'en': 'Current GPS location'
    },
    'GPS location शोधत आहे...': {
      'mr': 'GPS location शोधत आहे...',
      'hi': 'GPS लोकेशन खोज रहे हैं...',
      'en': 'Finding GPS location...'
    },
    'GPS location मिळाली!': {
      'mr': 'GPS location मिळाली!',
      'hi': 'GPS लोकेशन मिल गई!',
      'en': 'GPS location found!'
    },
    'Latitude': {'mr': 'अक्षांश', 'hi': 'अक्षांश', 'en': 'Latitude'},
    'Longitude': {'mr': 'रेखांश', 'hi': 'देशांतर', 'en': 'Longitude'},
    'GPS location उपलब्ध नाही.': {
      'mr': 'GPS location उपलब्ध नाही.',
      'hi': 'GPS लोकेशन उपलब्ध नहीं है।',
      'en': 'GPS location is unavailable.'
    },
    'ठिकाणाची माहिती': {
      'mr': 'ठिकाणाची माहिती',
      'hi': 'स्थान की जानकारी',
      'en': 'Location details'
    },
    'GPS मिळाली नाही तर ठिकाण स्वतः लिहू शकता.': {
      'mr': 'GPS मिळाली नाही तर ठिकाण स्वतः लिहू शकता.',
      'hi': 'GPS न मिलने पर स्थान स्वयं लिख सकते हैं।',
      'en': 'If GPS is unavailable, enter the location manually.'
    },
    'तक्रार तपासा': {
      'mr': 'तक्रार तपासा',
      'hi': 'शिकायत जाँचें',
      'en': 'Review complaint'
    },
    'तुमची तक्रार तपासा': {
      'mr': 'तुमची तक्रार तपासा',
      'hi': 'अपनी शिकायत जाँचें',
      'en': 'Review your complaint'
    },
    'पुढे जाण्यापूर्वी तक्रारीतील माहिती बरोबर आहे का ते पाहा.': {
      'mr': 'पुढे जाण्यापूर्वी तक्रारीतील माहिती बरोबर आहे का ते पाहा.',
      'hi': 'आगे बढ़ने से पहले शिकायत की जानकारी सही है या नहीं जाँचें।',
      'en': 'Check that the complaint details are correct before continuing.'
    },
    'निवडलेली भाषा': {
      'mr': 'निवडलेली भाषा',
      'hi': 'चुनी गई भाषा',
      'en': 'Selected language'
    },
    'तुमची तक्रार येथे लिहा...': {
      'mr': 'तुमची तक्रार येथे लिहा...',
      'hi': 'अपनी शिकायत यहाँ लिखें...',
      'en': 'Write your complaint here...'
    },
    'काही शब्द चुकीचे आले असतील तर वरील मजकूर बदलू शकता.': {
      'mr': 'काही शब्द चुकीचे आले असतील तर वरील मजकूर बदलू शकता.',
      'hi': 'कुछ शब्द गलत आए हों तो ऊपर का पाठ बदल सकते हैं।',
      'en': 'Edit the text above if any words were recognized incorrectly.'
    },
    'कृपया तक्रारीचे वर्णन लिहा.': {
      'mr': 'कृपया तक्रारीचे वर्णन लिहा.',
      'hi': 'कृपया शिकायत का विवरण लिखें।',
      'en': 'Please enter a complaint description.'
    },
    'तक्रार Confirm करा': {
      'mr': 'तक्रारीची पुष्टी करा',
      'hi': 'शिकायत की पुष्टि करें',
      'en': 'Confirm complaint'
    },
    'मागे जा': {'mr': 'मागे जा', 'hi': 'वापस जाएँ', 'en': 'Go back'},
    'आवाजातून तक्रार': {
      'mr': 'आवाजातून तक्रार',
      'hi': 'आवाज़ से शिकायत',
      'en': 'Voice complaint'
    },
    'तुमची समस्या बोला': {
      'mr': 'तुमची समस्या बोला',
      'hi': 'अपनी समस्या बोलें',
      'en': 'Speak about your problem'
    },
    'निवडलेली भाषा:': {
      'mr': 'निवडलेली भाषा:',
      'hi': 'चुनी गई भाषा:',
      'en': 'Selected language:'
    },
    'ओळखलेला मजकूर': {
      'mr': 'ओळखलेला मजकूर',
      'hi': 'पहचाना गया पाठ',
      'en': 'Recognized text'
    },
    'उदा. पाणी आज आले नाही.': {
      'mr': 'उदा. पाणी आज आले नाही.',
      'hi': 'उदा. आज पानी नहीं आया।',
      'en': 'Example: The water did not come today.'
    },
    'वर्णनात वापरा': {
      'mr': 'वर्णनात वापरा',
      'hi': 'विवरण में उपयोग करें',
      'en': 'Use in description'
    },
    'माइक बटण दाबून तुमची समस्या सांगा.': {
      'mr': 'माइक बटण दाबून तुमची समस्या सांगा.',
      'hi': 'माइक बटन दबाकर अपनी समस्या बताएँ।',
      'en': 'Press the microphone button and describe your problem.'
    },
    'आवाज मिळाला नाही. पुन्हा प्रयत्न करा.': {
      'mr': 'आवाज मिळाला नाही. पुन्हा प्रयत्न करा.',
      'hi': 'आवाज़ नहीं मिली। फिर से प्रयास करें।',
      'en': 'No speech detected. Please try again.'
    },
    'मजकूर मिळाला. तपासून घ्या.': {
      'mr': 'मजकूर मिळाला. तपासून घ्या.',
      'hi': 'पाठ मिल गया। कृपया जाँचें।',
      'en': 'Text captured. Please review it.'
    },
    'माइक दाबून तुमची समस्या मराठीत सांगा.': {
      'mr': 'माइक दाबून तुमची समस्या मराठीत सांगा.',
      'hi': 'माइक दबाकर अपनी समस्या हिंदी में बताएँ।',
      'en': 'Press the microphone and describe your problem in English.'
    },
    'Speech recognition उपलब्ध नाही. Google speech service तपासा.': {
      'mr': 'Speech recognition उपलब्ध नाही. Google speech service तपासा.',
      'hi': 'स्पीच पहचान उपलब्ध नहीं है। Google speech service जाँचें।',
      'en': 'Speech recognition is unavailable. Check Google speech services.'
    },
    'आता स्पष्टपणे बोला...': {
      'mr': 'आता स्पष्टपणे बोला...',
      'hi': 'अब स्पष्ट बोलें...',
      'en': 'Speak clearly now...'
    },
    'तुमचे बोलणे ऐकत आहे...': {
      'mr': 'तुमचे बोलणे ऐकत आहे...',
      'hi': 'आपकी बात सुन रहे हैं...',
      'en': 'Listening to you...'
    },
    'मजकूर मिळत आहे. बोलणे पूर्ण झाल्यावर तपासा.': {
      'mr': 'मजकूर मिळत आहे. बोलणे पूर्ण झाल्यावर तपासा.',
      'hi': 'पाठ मिल रहा है। बोलना पूरा होने पर जाँचें।',
      'en': 'Capturing text. Review it when you finish speaking.'
    },
    'कृपया आधी तुमची समस्या बोला.': {
      'mr': 'कृपया आधी तुमची समस्या बोला.',
      'hi': 'कृपया पहले अपनी समस्या बोलें।',
      'en': 'Please describe your problem first.'
    },
    'तक्रार यशस्वी': {
      'mr': 'तक्रार यशस्वी',
      'hi': 'शिकायत सफल',
      'en': 'Complaint submitted'
    },
    'तक्रार यशस्वीरीत्या नोंदवली!': {
      'mr': 'तक्रार यशस्वीरीत्या नोंदवली!',
      'hi': 'शिकायत सफलतापूर्वक दर्ज हुई!',
      'en': 'Complaint submitted successfully!'
    },
    'तुमच्या समस्येची माहिती मिळाली आहे. पुढील कार्यवाहीसाठी तक्रारीचा तपशील जतन करा.':
        {
      'mr':
          'तुमच्या समस्येची माहिती मिळाली आहे. पुढील कार्यवाहीसाठी तक्रारीचा तपशील जतन करा.',
      'hi':
          'आपकी समस्या की जानकारी मिल गई है। आगे की कार्रवाई के लिए शिकायत का विवरण सुरक्षित रखें।',
      'en':
          'Your problem has been received. Keep the complaint details for follow-up.'
    },
    'तक्रार क्रमांक': {
      'mr': 'तक्रार क्रमांक',
      'hi': 'शिकायत संख्या',
      'en': 'Complaint number'
    },
    'हा प्रोटोटाइप आहे. तक्रार क्रमांक सध्या डेमोसाठी तयार केला जातो. प्रत्यक्ष नोंदणीसाठी backend जोडणे आवश्यक आहे.':
        {
      'mr':
          'हा प्रोटोटाइप आहे. तक्रार क्रमांक सध्या डेमोसाठी तयार केला जातो. प्रत्यक्ष नोंदणीसाठी backend जोडणे आवश्यक आहे.',
      'hi':
          'यह एक प्रोटोटाइप है। शिकायत संख्या अभी डेमो के लिए बनाई जाती है। वास्तविक पंजीकरण के लिए backend जोड़ना होगा।',
      'en':
          'This is a prototype. Complaint numbers are currently generated for the demo. A backend is required for actual registration.'
    },
    'मुख्य स्क्रीनवर जा': {
      'mr': 'मुख्य स्क्रीनवर जा',
      'hi': 'मुख्य स्क्रीन पर जाएँ',
      'en': 'Go to home screen'
    },
    'तक्रार क्रमांक निवडून कॉपी करता येईल.': {
      'mr': 'तक्रार क्रमांक निवडून कॉपी करता येईल.',
      'hi': 'शिकायत संख्या चुनकर कॉपी कर सकते हैं।',
      'en': 'Select and copy the complaint number.'
    },
    'तक्रार क्रमांक जतन करा': {
      'mr': 'तक्रार क्रमांक जतन करा',
      'hi': 'शिकायत संख्या सुरक्षित रखें',
      'en': 'Save complaint number'
    },
    'माहिती उपलब्ध नाही': {
      'mr': 'माहिती उपलब्ध नाही',
      'hi': 'जानकारी उपलब्ध नहीं है',
      'en': 'Information unavailable'
    },
    'पाणीपुरवठ्याची समस्या असल्यास समस्या नोंदवा हा पर्याय निवडा. ठिकाण आणि समस्या स्पष्ट लिहा. तक्रार क्रमांक जतन करून ठेवा.':
        {
      'mr':
          'पाणीपुरवठ्याची समस्या असल्यास समस्या नोंदवा हा पर्याय निवडा. ठिकाण आणि समस्या स्पष्ट लिहा. तक्रार क्रमांक जतन करून ठेवा.',
      'hi':
          'पानी की समस्या के लिए समस्या दर्ज करें चुनें। स्थान और समस्या स्पष्ट लिखें। शिकायत संख्या सुरक्षित रखें।',
      'en':
          'For water supply problems, choose Report a problem. Describe the location and issue clearly, and keep the complaint number.'
    },
    'दस्तऐवजासाठी ग्रामपंचायत कार्यालयात आवश्यक कागदपत्रे आणि कार्यालयीन वेळ यांची पुष्टी करा. तुमची अडचण असल्यास तक्रार नोंदवा.':
        {
      'mr':
          'दस्तऐवजासाठी ग्रामपंचायत कार्यालयात आवश्यक कागदपत्रे आणि कार्यालयीन वेळ यांची पुष्टी करा. तुमची अडचण असल्यास तक्रार नोंदवा.',
      'hi':
          'दस्तावेज़ों और कार्यालय समय की जानकारी ग्राम पंचायत कार्यालय से लें। समस्या हो तो शिकायत दर्ज करें।',
      'en':
          'Confirm required documents and office hours with the village council. Report a problem if you need help.'
    },
    'रस्त्याच्या समस्येसाठी समस्या नोंदवा हा पर्याय वापरा. रस्त्याचे ठिकाण आणि समस्येचे वर्णन द्या. शक्य असल्यास फोटोही जोडा.':
        {
      'mr':
          'रस्त्याच्या समस्येसाठी समस्या नोंदवा हा पर्याय वापरा. रस्त्याचे ठिकाण आणि समस्येचे वर्णन द्या. शक्य असल्यास फोटोही जोडा.',
      'hi':
          'सड़क की समस्या के लिए समस्या दर्ज करें चुनें। सड़क का स्थान और समस्या का विवरण दें। संभव हो तो फ़ोटो भी जोड़ें।',
      'en':
          'Choose Report a problem for a road issue. Describe the location and issue, and add a photo if possible.'
    },
    'तक्रार नोंदवण्यासाठी Home screen वरील “समस्या नोंदवा” निवडा. प्रकार, ठिकाण आणि समस्येचे वर्णन भरून सबमिट करा.':
        {
      'mr':
          'तक्रार नोंदवण्यासाठी Home screen वरील “समस्या नोंदवा” निवडा. प्रकार, ठिकाण आणि समस्येचे वर्णन भरून सबमिट करा.',
      'hi':
          'शिकायत दर्ज करने के लिए होम स्क्रीन पर “समस्या दर्ज करें” चुनें। प्रकार, स्थान और विवरण भरकर जमा करें।',
      'en':
          'Choose “Report a problem” on the home screen. Enter the type, location, and description, then submit.'
    },
    'नमस्कार! 😊 गावातील कोणत्या सेवेसाठी मदत हवी आहे? पाणीपुरवठा, रस्ते, दस्तऐवज किंवा तक्रारींबद्दल विचारा.':
        {
      'mr':
          'नमस्कार! 😊 गावातील कोणत्या सेवेसाठी मदत हवी आहे? पाणीपुरवठा, रस्ते, दस्तऐवज किंवा तक्रारींबद्दल विचारा.',
      'hi':
          'नमस्ते! 😊 गाँव की किस सेवा में मदद चाहिए? पानी, सड़क, दस्तावेज़ या शिकायत के बारे में पूछें।',
      'en':
          'Hello! 😊 Which village service do you need help with? Ask about water, roads, documents, or complaints.'
    },
    'तुमचा प्रश्न समजला. कृपया समस्या कोणत्या सेवेशी संबंधित आहे ते स्पष्ट लिहा—उदा. पाणीपुरवठा, रस्ते, दस्तऐवज किंवा तक्रार. ही सध्या प्राथमिक सहाय्यक सेवा आहे.':
        {
      'mr':
          'तुमचा प्रश्न समजला. कृपया समस्या कोणत्या सेवेशी संबंधित आहे ते स्पष्ट लिहा—उदा. पाणीपुरवठा, रस्ते, दस्तऐवज किंवा तक्रार. ही सध्या प्राथमिक सहाय्यक सेवा आहे.',
      'hi':
          'आपका प्रश्न समझ आया। कृपया बताएँ कि समस्या किस सेवा से जुड़ी है—जैसे पानी, सड़क, दस्तावेज़ या शिकायत। यह प्रारंभिक सहायक सेवा है।',
      'en':
          'I understand. Please clarify which service your problem concerns, such as water, roads, documents, or complaints. This is a basic assistant service.'
    },
    'विभाग': {'mr': 'विभाग', 'hi': 'विभाग', 'en': 'Department'},
    'पाणी पुरवठा विभाग': {
      'mr': 'पाणी पुरवठा विभाग',
      'hi': 'जल आपूर्ति विभाग',
      'en': 'Water supply department'
    },
    'वीज विभाग': {
      'mr': 'वीज विभाग',
      'hi': 'बिजली विभाग',
      'en': 'Electricity department'
    },
    'बांधकाम / रस्ते विभाग': {
      'mr': 'बांधकाम / रस्ते विभाग',
      'hi': 'निर्माण / सड़क विभाग',
      'en': 'Public works / roads department'
    },
    'स्वच्छता विभाग': {
      'mr': 'स्वच्छता विभाग',
      'hi': 'स्वच्छता विभाग',
      'en': 'Sanitation department'
    },
    'ग्रामपंचायत विभाग': {
      'mr': 'ग्रामपंचायत विभाग',
      'hi': 'ग्राम पंचायत विभाग',
      'en': 'Village council department'
    },
    'शिक्षण विभाग': {
      'mr': 'शिक्षण विभाग',
      'hi': 'शिक्षा विभाग',
      'en': 'Education department'
    },
    'सुरक्षा विभाग': {
      'mr': 'सुरक्षा विभाग',
      'hi': 'सुरक्षा विभाग',
      'en': 'Security department'
    },
    'कृषी विभाग': {
      'mr': 'कृषी विभाग',
      'hi': 'कृषि विभाग',
      'en': 'Agriculture department'
    },
    'आरोग्य विभाग': {
      'mr': 'आरोग्य विभाग',
      'hi': 'स्वास्थ्य विभाग',
      'en': 'Health department'
    },
    'जन्म प्रमाणपत्र': {
      'mr': 'जन्म प्रमाणपत्र',
      'hi': 'जन्म प्रमाण पत्र',
      'en': 'Birth Certificate'
    },
    'जात प्रमाणपत्र': {
      'mr': 'जात प्रमाणपत्र',
      'hi': 'जाति प्रमाण पत्र',
      'en': 'Caste Certificate'
    },
    'उत्पन्न प्रमाणपत्र': {
      'mr': 'उत्पन्न प्रमाणपत्र',
      'hi': 'आय प्रमाण पत्र',
      'en': 'Income Certificate'
    },
    'अधिवास प्रमाणपत्र': {
      'mr': 'अधिवास प्रमाणपत्र',
      'hi': 'निवास प्रमाण पत्र',
      'en': 'Domicile Certificate'
    },
    'रहिवासी प्रमाणपत्र': {
      'mr': 'रहिवासी प्रमाणपत्र',
      'hi': 'निवास प्रमाण पत्र',
      'en': 'Residence Certificate'
    },
    'मृत्यू प्रमाणपत्र': {
      'mr': 'मृत्यू प्रमाणपत्र',
      'hi': 'मृत्यु प्रमाण पत्र',
      'en': 'Death Certificate'
    },
    'विवाह प्रमाणपत्र': {
      'mr': 'विवाह प्रमाणपत्र',
      'hi': 'विवाह प्रमाण पत्र',
      'en': 'Marriage Certificate'
    },
    'रेशन कार्ड': {'mr': 'रेशन कार्ड', 'hi': 'राशन कार्ड', 'en': 'Ration Card'},
    'आधार कार्ड समस्या': {
      'mr': 'आधार कार्ड समस्या',
      'hi': 'आधार कार्ड समस्या',
      'en': 'Aadhaar Card Issue'
    },
    'इतर दस्तऐवज': {
      'mr': 'इतर दस्तऐवज',
      'hi': 'अन्य दस्तावेज़',
      'en': 'Other Documents'
    },
    'सर्व': {'mr': 'सर्व', 'hi': 'सभी', 'en': 'All'},
    'तक्रारी लोड करता आल्या नाहीत.': {
      'mr': 'तक्रारी लोड करता आल्या नाहीत.',
      'hi': 'शिकायतें लोड नहीं हो सकीं।',
      'en': 'Could not load complaints.'
    },
    'नमस्कार! मी ग्रामसक्षम AI सहाय्यक आहे. पाणीपुरवठा, रस्ते, दस्तऐवज किंवा ग्रामपंचायत सेवांबद्दल विचारा.':
        {
      'mr':
          'नमस्कार! मी ग्रामसक्षम AI सहाय्यक आहे. पाणीपुरवठा, रस्ते, दस्तऐवज किंवा ग्रामपंचायत सेवांबद्दल विचारा.',
      'hi':
          'नमस्ते! मैं ग्रामसक्षम AI सहायक हूँ। पानी, सड़क, दस्तावेज़ या ग्राम पंचायत सेवाओं के बारे में पूछें।',
      'en':
          'Hello! I am the GramSaksham AI assistant. Ask about water, roads, documents, or village council services.'
    },
    'माइक सुरू होत आहे...': {
      'mr': 'माइक सुरू होत आहे...',
      'hi': 'माइक शुरू हो रहा है...',
      'en': 'Starting microphone...'
    },
    'निवडलेल्या भाषेचा speech locale उपलब्ध नाही.': {
      'mr': 'निवडलेल्या भाषेचा speech locale उपलब्ध नाही.',
      'hi': 'चुनी गई भाषा का speech locale उपलब्ध नहीं है।',
      'en': 'A speech locale for the selected language is unavailable.'
    },
    'माइक सुरू झाला नाही. Permission आणि speech service तपासा.': {
      'mr': 'माइक सुरू झाला नाही. Permission आणि speech service तपासा.',
      'hi': 'माइक शुरू नहीं हुआ। अनुमति और speech service जाँचें।',
      'en':
          'The microphone did not start. Check permission and speech services.'
    },
    'मजकूर मिळाला नाही. पुन्हा प्रयत्न करा.': {
      'mr': 'मजकूर मिळाला नाही. पुन्हा प्रयत्न करा.',
      'hi': 'पाठ नहीं मिला। फिर से प्रयास करें।',
      'en': 'No text captured. Please try again.'
    },
    'Speech could not start': {
      'mr': 'Speech सुरू करता आले नाही',
      'hi': 'Speech शुरू नहीं हो सका',
      'en': 'Speech could not start'
    },
    'Microphone could not start': {
      'mr': 'माइक सुरू झाला नाही',
      'hi': 'माइक शुरू नहीं हुआ',
      'en': 'Microphone could not start'
    },
    'Speech service unavailable': {
      'mr':
          'Speech service उपलब्ध नाही. Emulator मधील Google speech service तपासा.',
      'hi':
          'Speech service उपलब्ध नहीं है। Emulator में Google speech service जाँचें।',
      'en':
          'Speech service unavailable. Check Google speech services in the emulator.'
    },
    'Speech error': {
      'mr': 'Speech error',
      'hi': 'वाणी पहचान त्रुटि',
      'en': 'Speech error'
    },
    'Report': {'mr': 'अहवाल', 'hi': 'रिपोर्ट', 'en': 'Report'},
    'Citizen Feedback': {
      'mr': 'नागरिक अभिप्राय',
      'hi': 'नागरिक प्रतिक्रिया',
      'en': 'Citizen Feedback'
    },
    'Your Voice Matters!': {
      'mr': 'तुमचा आवाज महत्त्वाचा आहे!',
      'hi': 'आपकी आवाज़ महत्वपूर्ण है!',
      'en': 'Your Voice Matters!'
    },
    'Help us improve village services by sharing your experience.': {
      'mr': 'तुमचा अनुभव सांगून गावातील सेवा सुधारण्यास मदत करा.',
      'hi': 'अपना अनुभव साझा करके गाँव की सेवाओं को बेहतर बनाने में मदद करें।',
      'en': 'Help us improve village services by sharing your experience.'
    },
    'Complaint ID': {
      'mr': 'तक्रार क्रमांक',
      'hi': 'शिकायत संख्या',
      'en': 'Complaint ID'
    },
    'Service Category': {
      'mr': 'सेवेचा प्रकार',
      'hi': 'सेवा की श्रेणी',
      'en': 'Service Category'
    },
    'How would you rate our service?': {
      'mr': 'आमच्या सेवेचे मूल्यांकन कसे कराल?',
      'hi': 'आप हमारी सेवा को कितनी रेटिंग देंगे?',
      'en': 'How would you rate our service?'
    },
    'Select your rating': {
      'mr': 'रेटिंग निवडा',
      'hi': 'अपनी रेटिंग चुनें',
      'en': 'Select your rating'
    },
    'How was your experience?': {
      'mr': 'तुमचा अनुभव कसा होता?',
      'hi': 'आपका अनुभव कैसा रहा?',
      'en': 'How was your experience?'
    },
    'Very Satisfied': {
      'mr': 'अत्यंत समाधानी',
      'hi': 'बहुत संतुष्ट',
      'en': 'Very Satisfied'
    },
    'Satisfied': {'mr': 'समाधानी', 'hi': 'संतुष्ट', 'en': 'Satisfied'},
    'Neutral': {'mr': 'तटस्थ', 'hi': 'सामान्य', 'en': 'Neutral'},
    'Dissatisfied': {'mr': 'असमाधानी', 'hi': 'असंतुष्ट', 'en': 'Dissatisfied'},
    'Additional Feedback (Optional)': {
      'mr': 'अतिरिक्त अभिप्राय (ऐच्छिक)',
      'hi': 'अतिरिक्त प्रतिक्रिया (वैकल्पिक)',
      'en': 'Additional Feedback (Optional)'
    },
    'Share your suggestions...': {
      'mr': 'तुमच्या सूचना लिहा...',
      'hi': 'अपने सुझाव लिखें...',
      'en': 'Share your suggestions...'
    },
    'Submit Feedback': {
      'mr': 'अभिप्राय पाठवा',
      'hi': 'प्रतिक्रिया भेजें',
      'en': 'Submit Feedback'
    },
    'Please select a star rating.': {
      'mr': 'कृपया स्टार रेटिंग निवडा.',
      'hi': 'कृपया स्टार रेटिंग चुनें।',
      'en': 'Please select a star rating.'
    },
    'Thank You!': {'mr': 'धन्यवाद!', 'hi': 'धन्यवाद!', 'en': 'Thank You!'},
    'Done': {'mr': 'पूर्ण', 'hi': 'हो गया', 'en': 'Done'},
    'Demo mode: feedback is not saved to a database.': {
      'mr': 'डेमो मोड: अभिप्राय डेटाबेसमध्ये जतन होत नाही.',
      'hi': 'डेमो मोड: प्रतिक्रिया डेटाबेस में सहेजी नहीं जाती।',
      'en': 'Demo mode: feedback is not saved to a database.'
    },
    'Action / Repair': {
      'mr': 'कार्यवाही / दुरुस्ती',
      'hi': 'कार्रवाई / मरम्मत',
      'en': 'Action / Repair'
    },
    'Action & Repair Management': {
      'mr': 'कार्यवाही आणि दुरुस्ती व्यवस्थापन',
      'hi': 'कार्रवाई और मरम्मत प्रबंधन',
      'en': 'Action & Repair Management'
    },
    'Record the work performed and update the complaint status.': {
      'mr': 'केलेल्या कामाची नोंद करा आणि तक्रारीची स्थिती अद्ययावत करा.',
      'hi': 'किए गए काम को दर्ज करें और शिकायत की स्थिति अपडेट करें।',
      'en': 'Record the work performed and update the complaint status.'
    },
    'Complaint Category': {
      'mr': 'तक्रारीचा प्रकार',
      'hi': 'शिकायत की श्रेणी',
      'en': 'Complaint Category'
    },
    'Village / Location': {
      'mr': 'गाव / ठिकाण',
      'hi': 'गाँव / स्थान',
      'en': 'Village / Location'
    },
    'Update Work Details': {
      'mr': 'कामाचा तपशील अद्ययावत करा',
      'hi': 'कार्य विवरण अपडेट करें',
      'en': 'Update Work Details'
    },
    'Type of Action': {
      'mr': 'कार्यवाहीचा प्रकार',
      'hi': 'कार्रवाई का प्रकार',
      'en': 'Type of Action'
    },
    'Repair Work': {
      'mr': 'दुरुस्तीचे काम',
      'hi': 'मरम्मत कार्य',
      'en': 'Repair Work'
    },
    'Inspection': {'mr': 'तपासणी', 'hi': 'निरीक्षण', 'en': 'Inspection'},
    'Maintenance': {'mr': 'देखभाल', 'hi': 'रखरखाव', 'en': 'Maintenance'},
    'Replacement': {'mr': 'बदलणे', 'hi': 'बदलना', 'en': 'Replacement'},
    'Other': {'mr': 'इतर', 'hi': 'अन्य', 'en': 'Other'},
    'Action Taken': {
      'mr': 'केलेली कार्यवाही',
      'hi': 'की गई कार्रवाई',
      'en': 'Action Taken'
    },
    'Describe the work completed or started...': {
      'mr': 'पूर्ण केलेल्या किंवा सुरू केलेल्या कामाचे वर्णन करा...',
      'hi': 'पूरा किए या शुरू किए गए काम का विवरण दें...',
      'en': 'Describe the work completed or started...'
    },
    'Please enter the action taken': {
      'mr': 'कृपया केलेली कार्यवाही लिहा',
      'hi': 'कृपया की गई कार्रवाई दर्ज करें',
      'en': 'Please enter the action taken'
    },
    'Responsible Officer': {
      'mr': 'जबाबदार अधिकारी',
      'hi': 'जिम्मेदार अधिकारी',
      'en': 'Responsible Officer'
    },
    'Enter officer name': {
      'mr': 'अधिकाऱ्याचे नाव लिहा',
      'hi': 'अधिकारी का नाम दर्ज करें',
      'en': 'Enter officer name'
    },
    'Current Work Status': {
      'mr': 'कामाची सध्याची स्थिती',
      'hi': 'कार्य की वर्तमान स्थिति',
      'en': 'Current Work Status'
    },
    'Completed': {'mr': 'पूर्ण', 'hi': 'पूर्ण', 'en': 'Completed'},
    'On Hold': {'mr': 'थांबवले', 'hi': 'रोक पर', 'en': 'On Hold'},
    'Additional Remarks (Optional)': {
      'mr': 'अतिरिक्त नोंदी (ऐच्छिक)',
      'hi': 'अतिरिक्त टिप्पणी (वैकल्पिक)',
      'en': 'Additional Remarks (Optional)'
    },
    'Add any extra information...': {
      'mr': 'अतिरिक्त माहिती लिहा...',
      'hi': 'अतिरिक्त जानकारी लिखें...',
      'en': 'Add any extra information...'
    },
    'Save Action Details': {
      'mr': 'कार्यवाहीचा तपशील जतन करा',
      'hi': 'कार्रवाई का विवरण सहेजें',
      'en': 'Save Action Details'
    },
    'Action details recorded for this demo.': {
      'mr': 'डेमोसाठी कार्यवाहीचा तपशील नोंदवला.',
      'hi': 'डेमो के लिए कार्रवाई का विवरण दर्ज किया गया।',
      'en': 'Action details recorded for this demo.'
    },
    'Demo mode: details are not saved to a database.': {
      'mr': 'डेमो मोड: तपशील डेटाबेसमध्ये जतन होत नाहीत.',
      'hi': 'डेमो मोड: विवरण डेटाबेस में सहेजे नहीं जाते।',
      'en': 'Demo mode: details are not saved to a database.'
    },
    'Assign Department': {
      'mr': 'विभाग नियुक्त करा',
      'hi': 'विभाग सौंपें',
      'en': 'Assign Department'
    },
    'Complaint Assignment': {
      'mr': 'तक्रार नियुक्ती',
      'hi': 'शिकायत आवंटन',
      'en': 'Complaint Assignment'
    },
    'Review the complaint and route it to the appropriate department.': {
      'mr': 'तक्रार तपासून योग्य विभागाकडे पाठवा.',
      'hi': 'शिकायत की समीक्षा करके सही विभाग को भेजें।',
      'en': 'Review the complaint and route it to the appropriate department.'
    },
    'Category': {'mr': 'प्रकार', 'hi': 'श्रेणी', 'en': 'Category'},
    'Location': {'mr': 'ठिकाण', 'hi': 'स्थान', 'en': 'Location'},
    'Description': {'mr': 'वर्णन', 'hi': 'विवरण', 'en': 'Description'},
    'Select Department': {
      'mr': 'विभाग निवडा',
      'hi': 'विभाग चुनें',
      'en': 'Select Department'
    },
    'Select a department': {
      'mr': 'विभाग निवडा',
      'hi': 'विभाग चुनें',
      'en': 'Select a department'
    },
    'Assigned Officer Name': {
      'mr': 'नियुक्त अधिकाऱ्याचे नाव',
      'hi': 'नियुक्त अधिकारी का नाम',
      'en': 'Assigned Officer Name'
    },
    'Complaint Priority': {
      'mr': 'तक्रारीची प्राथमिकता',
      'hi': 'शिकायत की प्राथमिकता',
      'en': 'Complaint Priority'
    },
    'Low': {'mr': 'कमी', 'hi': 'कम', 'en': 'Low'},
    'Medium': {'mr': 'मध्यम', 'hi': 'मध्यम', 'en': 'Medium'},
    'High': {'mr': 'उच्च', 'hi': 'उच्च', 'en': 'High'},
    'Urgent': {'mr': 'तातडीचे', 'hi': 'अत्यावश्यक', 'en': 'Urgent'},
    'Select priority': {
      'mr': 'प्राथमिकता निवडा',
      'hi': 'प्राथमिकता चुनें',
      'en': 'Select priority'
    },
    'Remarks (optional)': {
      'mr': 'नोंदी (ऐच्छिक)',
      'hi': 'टिप्पणी (वैकल्पिक)',
      'en': 'Remarks (optional)'
    },
    'Add assignment instructions': {
      'mr': 'नियुक्तीच्या सूचना लिहा',
      'hi': 'आवंटन संबंधी निर्देश लिखें',
      'en': 'Add assignment instructions'
    },
    'Assign Complaint': {
      'mr': 'तक्रार नियुक्त करा',
      'hi': 'शिकायत सौंपें',
      'en': 'Assign Complaint'
    },
    'Please select department and priority.': {
      'mr': 'कृपया विभाग आणि प्राथमिकता निवडा.',
      'hi': 'कृपया विभाग और प्राथमिकता चुनें।',
      'en': 'Please select department and priority.'
    },
    'Assignment Saved': {
      'mr': 'नियुक्ती जतन झाली',
      'hi': 'आवंटन सहेजा गया',
      'en': 'Assignment Saved'
    },
    'Verification Recorded': {
      'mr': 'पडताळणी नोंदवली',
      'hi': 'सत्यापन दर्ज किया गया',
      'en': 'Verification Recorded'
    },
    'Complaint Verification': {
      'mr': 'तक्रार पडताळणी',
      'hi': 'शिकायत सत्यापन',
      'en': 'Complaint Verification'
    },
    'Verify Completed Work': {
      'mr': 'पूर्ण झालेल्या कामाची पडताळणी करा',
      'hi': 'पूरा हुआ काम सत्यापित करें',
      'en': 'Verify Completed Work'
    },
    'Review the reported work and record the verification result.': {
      'mr': 'नोंदवलेल्या कामाची तपासणी करून पडताळणीचा निकाल नोंदवा.',
      'hi': 'रिपोर्ट किए गए काम की जाँच करके सत्यापन का परिणाम दर्ज करें।',
      'en': 'Review the reported work and record the verification result.'
    },
    'Verification Checklist': {
      'mr': 'पडताळणी तपासणीसूची',
      'hi': 'सत्यापन जाँच सूची',
      'en': 'Verification Checklist'
    },
    'Action details reviewed': {
      'mr': 'कार्यवाहीचा तपशील तपासला',
      'hi': 'कार्रवाई का विवरण जाँचा',
      'en': 'Action details reviewed'
    },
    'Complaint location checked': {
      'mr': 'तक्रारीचे ठिकाण तपासले',
      'hi': 'शिकायत का स्थान जाँचा',
      'en': 'Complaint location checked'
    },
    'Resolution quality assessed': {
      'mr': 'निराकरणाची गुणवत्ता तपासली',
      'hi': 'समाधान की गुणवत्ता जाँची',
      'en': 'Resolution quality assessed'
    },
    'Verification Result': {
      'mr': 'पडताळणीचा निकाल',
      'hi': 'सत्यापन का परिणाम',
      'en': 'Verification Result'
    },
    'Verified': {'mr': 'पडताळले', 'hi': 'सत्यापित', 'en': 'Verified'},
    'Rejected': {'mr': 'नाकारले', 'hi': 'अस्वीकृत', 'en': 'Rejected'},
    'Needs Rework': {
      'mr': 'पुन्हा काम आवश्यक',
      'hi': 'दोबारा काम आवश्यक',
      'en': 'Needs Rework'
    },
    'Work is completed satisfactorily': {
      'mr': 'काम समाधानकारक पूर्ण झाले आहे',
      'hi': 'काम संतोषजनक रूप से पूरा हुआ है',
      'en': 'Work is completed satisfactorily'
    },
    'Work does not meet requirements': {
      'mr': 'काम आवश्यक निकष पूर्ण करत नाही',
      'hi': 'काम आवश्यकताओं पर खरा नहीं उतरता',
      'en': 'Work does not meet requirements'
    },
    'Additional work is required': {
      'mr': 'अतिरिक्त काम आवश्यक आहे',
      'hi': 'अतिरिक्त काम आवश्यक है',
      'en': 'Additional work is required'
    },
    'Verification Remarks': {
      'mr': 'पडताळणी नोंदी',
      'hi': 'सत्यापन टिप्पणी',
      'en': 'Verification Remarks'
    },
    'Enter observations or feedback...': {
      'mr': 'निरीक्षण किंवा अभिप्राय लिहा...',
      'hi': 'अवलोकन या प्रतिक्रिया लिखें...',
      'en': 'Enter observations or feedback...'
    },
    'Submit Verification': {
      'mr': 'पडताळणी पाठवा',
      'hi': 'सत्यापन जमा करें',
      'en': 'Submit Verification'
    },
    'Demo mode: verification is not stored permanently.': {
      'mr': 'डेमो मोड: पडताळणी कायमस्वरूपी जतन होत नाही.',
      'hi': 'डेमो मोड: सत्यापन स्थायी रूप से सहेजा नहीं जाता।',
      'en': 'Demo mode: verification is not stored permanently.'
    },
    'Officer Dashboard': {
      'mr': 'अधिकारी डॅशबोर्ड',
      'hi': 'अधिकारी डैशबोर्ड',
      'en': 'Officer Dashboard'
    },
    'GramSaksham • Smart Village': {
      'mr': 'ग्रामसक्षम • स्मार्ट व्हिलेज',
      'hi': 'ग्रामसक्षम • स्मार्ट गाँव',
      'en': 'GramSaksham • Smart Village'
    },
    'No new notifications.': {
      'mr': 'नवीन सूचना नाहीत.',
      'hi': 'कोई नई सूचनाएँ नहीं हैं।',
      'en': 'No new notifications.'
    },
    'Complaint Overview': {
      'mr': 'तक्रारींचा आढावा',
      'hi': 'शिकायतों का सारांश',
      'en': 'Complaint Overview'
    },
    'Total Complaints': {
      'mr': 'एकूण तक्रारी',
      'hi': 'कुल शिकायतें',
      'en': 'Total Complaints'
    },
    'Citizen Complaints': {
      'mr': 'नागरिकांच्या तक्रारी',
      'hi': 'नागरिकों की शिकायतें',
      'en': 'Citizen Complaints'
    },
    'records': {'mr': 'नोंदी', 'hi': 'रिकॉर्ड', 'en': 'records'},
    'Demo data is displayed. Connect a backend to manage real village complaints.':
        {
      'mr':
          'डेमो माहिती दाखवली आहे. प्रत्यक्ष गावातील तक्रारी व्यवस्थापित करण्यासाठी backend जोडा.',
      'hi':
          'डेमो डेटा दिखाया गया है। वास्तविक गाँव की शिकायतों के प्रबंधन के लिए backend जोड़ें।',
      'en':
          'Demo data is displayed. Connect a backend to manage real village complaints.'
    },
    'नमस्कार, अधिकारी!': {
      'mr': 'नमस्कार, अधिकारी!',
      'hi': 'नमस्ते, अधिकारी!',
      'en': 'Hello, officer!'
    },
    'Manage village complaints and track their progress.': {
      'mr': 'गावातील तक्रारी व्यवस्थापित करा आणि त्यांची प्रगती पाहा.',
      'hi': 'गाँव की शिकायतों का प्रबंधन करें और उनकी प्रगति देखें।',
      'en': 'Manage village complaints and track their progress.'
    },
    'Priority': {'mr': 'प्राथमिकता', 'hi': 'प्राथमिकता', 'en': 'Priority'},
    'All': {'mr': 'सर्व', 'hi': 'सभी', 'en': 'All'},
    'General': {'mr': 'सामान्य', 'hi': 'सामान्य', 'en': 'General'},
    'Location:': {'mr': 'ठिकाण:', 'hi': 'स्थान:', 'en': 'Location:'},
    'Priority:': {'mr': 'प्राथमिकता:', 'hi': 'प्राथमिकता:', 'en': 'Priority:'},
    'No complaints found': {
      'mr': 'तक्रारी आढळल्या नाहीत',
      'hi': 'कोई शिकायत नहीं मिली',
      'en': 'No complaints found'
    },
    'Try selecting a different filter.': {
      'mr': 'वेगळा फिल्टर निवडून पाहा.',
      'hi': 'कोई दूसरा फ़िल्टर चुनकर देखें।',
      'en': 'Try selecting a different filter.'
    },
    'out of 5 stars': {
      'mr': 'पैकी ५ स्टार',
      'hi': 'में से ५ स्टार',
      'en': 'out of 5 stars'
    },
    'Village image not found.\nCheck the assets/images folder.': {
      'mr': 'गावाचे चित्र सापडले नाही.\nassets/images फोल्डर तपासा.',
      'hi': 'गाँव की तस्वीर नहीं मिली।\nassets/images फ़ोल्डर जाँचें।',
      'en': 'Village image not found.\nCheck the assets/images folder.'
    },
    'Please select a verification result.': {
      'mr': 'कृपया पडताळणीचा निकाल निवडा.',
      'hi': 'कृपया सत्यापन का परिणाम चुनें।',
      'en': 'Please select a verification result.'
    },
    'OK': {'mr': 'ठीक आहे', 'hi': 'ठीक है', 'en': 'OK'},
    'Water Supply Department': {
      'mr': 'पाणी पुरवठा विभाग',
      'hi': 'जल आपूर्ति विभाग',
      'en': 'Water Supply Department'
    },
    'Electricity Department': {
      'mr': 'वीज विभाग',
      'hi': 'बिजली विभाग',
      'en': 'Electricity Department'
    },
    'Roads and Public Works': {
      'mr': 'बांधकाम / रस्ते विभाग',
      'hi': 'निर्माण / सड़क विभाग',
      'en': 'Roads and Public Works'
    },
    'Sanitation Department': {
      'mr': 'स्वच्छता विभाग',
      'hi': 'स्वच्छता विभाग',
      'en': 'Sanitation Department'
    },
    'Health Department': {
      'mr': 'आरोग्य विभाग',
      'hi': 'स्वास्थ्य विभाग',
      'en': 'Health Department'
    },
    'Gram Panchayat': {
      'mr': 'ग्रामपंचायत',
      'hi': 'ग्राम पंचायत',
      'en': 'Gram Panchayat'
    },
    'Water Supply': {
      'mr': 'पाणीपुरवठा',
      'hi': 'जल आपूर्ति',
      'en': 'Water Supply'
    },
    'Road': {'mr': 'रस्ता', 'hi': 'सड़क', 'en': 'Road'},
    'Street Light': {
      'mr': 'पथदिवा',
      'hi': 'स्ट्रीट लाइट',
      'en': 'Street Light'
    },
    'Sanitation': {'mr': 'स्वच्छता', 'hi': 'स्वच्छता', 'en': 'Sanitation'},
    'Village Location': {
      'mr': 'गावाचे ठिकाण',
      'hi': 'गाँव का स्थान',
      'en': 'Village Location'
    },
    'AI तक्रार विश्लेषण': {
      'mr': 'AI तक्रार विश्लेषण',
      'hi': 'AI शिकायत विश्लेषण',
      'en': 'AI complaint analysis'
    },
    'विश्लेषण पूर्ण!': {
      'mr': 'विश्लेषण पूर्ण!',
      'hi': 'विश्लेषण पूरा!',
      'en': 'Analysis complete!'
    },
    'AI तक्रार तपासत आहे...': {
      'mr': 'AI तक्रार तपासत आहे...',
      'hi': 'AI शिकायत की जाँच कर रहा है...',
      'en': 'AI is reviewing the complaint...'
    },
    'तक्रार पुढील टप्प्यासाठी तयार आहे.': {
      'mr': 'तक्रार पुढील टप्प्यासाठी तयार आहे.',
      'hi': 'शिकायत अगले चरण के लिए तैयार है।',
      'en': 'The complaint is ready for the next step.'
    },
    'कृपया थोडा वेळ थांबा.': {
      'mr': 'कृपया थोडा वेळ थांबा.',
      'hi': 'कृपया थोड़ी देर प्रतीक्षा करें।',
      'en': 'Please wait a moment.'
    },
    'तक्रारीची माहिती तपासत आहोत': {
      'mr': 'तक्रारीची माहिती तपासत आहोत',
      'hi': 'शिकायत की जानकारी जाँच रहे हैं',
      'en': 'Checking complaint details'
    },
    'समस्येचा प्रकार ओळखत आहोत': {
      'mr': 'समस्येचा प्रकार ओळखत आहोत',
      'hi': 'समस्या का प्रकार पहचान रहे हैं',
      'en': 'Identifying problem type'
    },
    'विभाग निश्चित करत आहोत': {
      'mr': 'विभाग निश्चित करत आहोत',
      'hi': 'विभाग तय कर रहे हैं',
      'en': 'Identifying department'
    },
    'तक्रार नोंदणीसाठी तयार करत आहोत': {
      'mr': 'तक्रार नोंदणीसाठी तयार करत आहोत',
      'hi': 'शिकायत पंजीकरण के लिए तैयार कर रहे हैं',
      'en': 'Preparing complaint for registration'
    },
    'पुढील स्क्रीन उघडत आहे...': {
      'mr': 'पुढील स्क्रीन उघडत आहे...',
      'hi': 'अगली स्क्रीन खुल रही है...',
      'en': 'Opening the next screen...'
    },
    'तक्रार ऑटो सिंक': {
      'mr': 'तक्रार ऑटो सिंक',
      'hi': 'शिकायत ऑटो सिंक',
      'en': 'Complaint auto sync'
    },
    'सिंक प्रक्रिया पूर्ण!': {
      'mr': 'सिंक प्रक्रिया पूर्ण!',
      'hi': 'सिंक प्रक्रिया पूरी!',
      'en': 'Sync complete!'
    },
    'तक्रार सिंक होत आहे...': {
      'mr': 'तक्रार सिंक होत आहे...',
      'hi': 'शिकायत सिंक हो रही है...',
      'en': 'Syncing complaint...'
    },
    'ऑटो सिंक व्यवस्थापन': {
      'mr': 'ऑटो सिंक व्यवस्थापन',
      'hi': 'ऑटो सिंक प्रबंधन',
      'en': 'Auto sync management'
    },
    'आता AI विश्लेषणाच्या पुढील टप्प्यावर जा.': {
      'mr': 'आता AI विश्लेषणाच्या पुढील टप्प्यावर जा.',
      'hi': 'अब AI विश्लेषण के अगले चरण पर जाएँ।',
      'en': 'Continue to the next AI analysis step.'
    },
    'इंटरनेट उपलब्ध असल्याचे डेमो निवडा आणि तक्रार सिंक प्रक्रिया सुरू करा.': {
      'mr':
          'इंटरनेट उपलब्ध असल्याचे डेमो निवडा आणि तक्रार सिंक प्रक्रिया सुरू करा.',
      'hi': 'इंटरनेट उपलब्ध होने का डेमो चुनें और शिकायत सिंक शुरू करें।',
      'en': 'Simulate internet availability and start complaint sync.'
    },
    'सिंक स्थिती': {
      'mr': 'सिंक स्थिती',
      'hi': 'सिंक स्थिति',
      'en': 'Sync status'
    },
    'डेमो इंटरनेट उपलब्ध': {
      'mr': 'डेमो इंटरनेट उपलब्ध',
      'hi': 'डेमो इंटरनेट उपलब्ध',
      'en': 'Demo internet available'
    },
    'इंटरनेट उपलब्ध असल्याचे डेमो': {
      'mr': 'इंटरनेट उपलब्ध असल्याचे डेमो',
      'hi': 'इंटरनेट उपलब्ध होने का डेमो',
      'en': 'Simulate internet available'
    },
    'इंटरनेट उपलब्ध नाही असे डेमो': {
      'mr': 'इंटरनेट उपलब्ध नाही असे डेमो',
      'hi': 'इंटरनेट उपलब्ध न होने का डेमो',
      'en': 'Simulate internet unavailable'
    },
    'प्राप्त': {'mr': 'प्राप्त', 'hi': 'प्राप्त', 'en': 'Received'},
    'इंटरनेट': {'mr': 'इंटरनेट', 'hi': 'इंटरनेट', 'en': 'Internet'},
    'उपलब्ध': {'mr': 'उपलब्ध', 'hi': 'उपलब्ध', 'en': 'Available'},
    'उपलब्ध नाही': {
      'mr': 'उपलब्ध नाही',
      'hi': 'उपलब्ध नहीं',
      'en': 'Unavailable'
    },
    'प्रक्रिया सुरू': {
      'mr': 'प्रक्रिया सुरू',
      'hi': 'प्रक्रिया जारी',
      'en': 'In progress'
    },
    'प्रतीक्षेत': {'mr': 'प्रतीक्षेत', 'hi': 'प्रतीक्षा में', 'en': 'Waiting'},
    'तक्रारीचा सारांश': {
      'mr': 'तक्रारीचा सारांश',
      'hi': 'शिकायत का सारांश',
      'en': 'Complaint summary'
    },
    'प्रकार': {'mr': 'प्रकार', 'hi': 'प्रकार', 'en': 'Type'},
    'सिंक पूर्ण': {
      'mr': 'सिंक पूर्ण',
      'hi': 'सिंक पूरा',
      'en': 'Sync complete'
    },
    'सिंक होत आहे...': {
      'mr': 'सिंक होत आहे...',
      'hi': 'सिंक हो रहा है...',
      'en': 'Syncing...'
    },
    'आता सिंक करा': {
      'mr': 'आता सिंक करा',
      'hi': 'अभी सिंक करें',
      'en': 'Sync now'
    },
    'पुढे जा — AI विश्लेषण': {
      'mr': 'पुढे जा — AI विश्लेषण',
      'hi': 'आगे बढ़ें — AI विश्लेषण',
      'en': 'Continue — AI analysis'
    },
    'इंटरनेट उपलब्ध झाल्यावर पुन्हा प्रयत्न करा.': {
      'mr': 'इंटरनेट उपलब्ध झाल्यावर पुन्हा प्रयत्न करा.',
      'hi': 'इंटरनेट उपलब्ध होने पर फिर से प्रयास करें।',
      'en': 'Please try again when internet is available.'
    },
    'तुमची तक्रार सबमिट केल्यानंतर स्थिती पाहण्यासाठी माझ्या तक्रारी उघडा.': {
      'mr':
          'तुमची तक्रार सबमिट केल्यानंतर स्थिती पाहण्यासाठी माझ्या तक्रारी उघडा.',
      'hi':
          'शिकायत जमा करने के बाद उसकी स्थिति देखने के लिए मेरी शिकायतें खोलें।',
      'en':
          'Open My Complaints to check the status after you submit a complaint.'
    },
    'भाषा जतन करता आली नाही.': {
      'mr': 'भाषा जतन करता आली नाही.',
      'hi': 'भाषा सहेजी नहीं जा सकी।',
      'en': 'Could not save the selected language.'
    },
    'निवडलेल्या भाषेची speech सुविधा उपलब्ध नाही.': {
      'mr': 'निवडलेल्या भाषेची speech सुविधा उपलब्ध नाही.',
      'hi': 'चुनी गई भाषा की speech सुविधा उपलब्ध नहीं है।',
      'en': 'Speech recognition is unavailable for the selected language.'
    },
    'आवाजानंतर तक्रार': {
      'mr': 'आवाजानंतर तक्रार',
      'hi': 'आवाज़ से शिकायत',
      'en': 'Voice complaint'
    },
    'वापरलेले वाक्य': {
      'mr': 'वापरलेले वाक्य',
      'hi': 'इस वाक्य का उपयोग करें',
      'en': 'Use this text'
    },
  };
}
