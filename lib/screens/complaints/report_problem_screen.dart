import '../../app_ui.dart';
import '../../language/app_language.dart';
import 'package:image_picker/image_picker.dart';

import 'voice_recording_screen.dart';
import 'location_map_screen.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  static const Color green = Color(0xFF078746);
  static const Color darkGreen = Color(0xFF075B35);
  static const Color navy = Color(0xFF174D35);
  static const Color pageBackground = Color(0xFFF4F8F5);

  final formKey = GlobalKey<FormState>();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final picker = ImagePicker();

  String? selectedCategory;
  String? selectedDocument;
  String selectedLanguage = AppLanguage.instance.language;

  XFile? selectedMedia;
  bool isVideo = false;

  // Image paths tumchya assets/images/complaints folder nusar aahet.
  // Tuple: title, image path, fallback icon, color.
  final List<(String, String, IconData, Color)> categories = [
    (
      'पाणी समस्या',
      'assets/images/complaints/water.png',
      Icons.water_drop_rounded,
      Color(0xFF2584E8)
    ),
    (
      'वीज समस्या',
      'assets/images/complaints/electricity.png',
      Icons.bolt_rounded,
      Color(0xFFFFA126)
    ),
    (
      'रस्ता समस्या',
      'assets/images/complaints/road.png',
      Icons.add_road_rounded,
      Color(0xFF9A6A45)
    ),
    (
      'स्वच्छता',
      'assets/images/complaints/cleanliness.png',
      Icons.cleaning_services_rounded,
      Color(0xFF159D86)
    ),
    (
      'दस्तऐवज',
      'assets/images/complaints/document.png',
      Icons.description_rounded,
      Color(0xFF8057D8)
    ),
    (
      'अभ्यासिका',
      'assets/images/complaints/education.png',
      Icons.menu_book_rounded,
      Color(0xFFE44F91)
    ),
    (
      'CCTV / सुरक्षा',
      'assets/images/complaints/security.png',
      Icons.security_rounded,
      Color(0xFF52657D)
    ),
    (
      'शेती',
      'assets/images/complaints/farming.png',
      Icons.agriculture_rounded,
      Color(0xFF558B35)
    ),
    (
      'वैद्यकीय सेवा',
      'assets/images/complaints/health_care.png',
      Icons.medical_services_rounded,
      Color(0xFFE34E55)
    ),
    (
      'इतर समस्या',
      'assets/images/complaints/other.png',
      Icons.more_horiz_rounded,
      Color(0xFF008F83)
    ),
  ];

  final List<(String, String, IconData, Color)> documents = [
    (
      'Birth Certificate',
      'जन्म प्रमाणपत्र',
      Icons.child_care_rounded,
      Color(0xFF3985F7)
    ),
    (
      'Caste Certificate',
      'जात प्रमाणपत्र',
      Icons.groups_rounded,
      Color(0xFF8855D9)
    ),
    (
      'Income Certificate',
      'उत्पन्न प्रमाणपत्र',
      Icons.account_balance_wallet_rounded,
      Color(0xFF169B70)
    ),
    (
      'Domicile Certificate',
      'अधिवास प्रमाणपत्र',
      Icons.home_work_rounded,
      Color(0xFFEB8B24)
    ),
    (
      'Residence Certificate',
      'रहिवासी प्रमाणपत्र',
      Icons.location_city_rounded,
      Color(0xFF159BA8)
    ),
    (
      'Death Certificate',
      'मृत्यू प्रमाणपत्र',
      Icons.article_rounded,
      Color(0xFF667085)
    ),
    (
      'Marriage Certificate',
      'विवाह प्रमाणपत्र',
      Icons.favorite_rounded,
      Color(0xFFE45181)
    ),
    ('Ration Card', 'रेशन कार्ड', Icons.credit_card_rounded, Color(0xFFAD7A20)),
    (
      'Aadhaar Card Issue',
      'आधार कार्ड समस्या',
      Icons.badge_rounded,
      Color(0xFF3156A5)
    ),
    (
      'Other Documents',
      'इतर दस्तऐवज',
      Icons.folder_open_rounded,
      Color(0xFF00897B)
    ),
  ];

  final Map<String, String> departmentMapping = {
    'पाणी समस्या': 'पाणी पुरवठा विभाग',
    'वीज समस्या': 'वीज विभाग',
    'रस्ता समस्या': 'बांधकाम / रस्ते विभाग',
    'स्वच्छता': 'स्वच्छता विभाग',
    'दस्तऐवज': 'ग्रामपंचायत विभाग',
    'अभ्यासिका': 'शिक्षण विभाग',
    'CCTV / सुरक्षा': 'सुरक्षा विभाग',
    'शेती': 'कृषी विभाग',
    'वैद्यकीय सेवा': 'आरोग्य विभाग',
    'इतर समस्या': 'ग्रामपंचायत विभाग',
  };

  @override
  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
      ),
    );
  }

  Future<void> showDocumentOptions() async {
    final searchController = TextEditingController();
    String? temporarySelection;

    for (final item in documents) {
      if (item.$2 == selectedDocument) {
        temporarySelection = item.$1;
        break;
      }
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();

            final filtered = documents.where((item) {
              return item.$1.toLowerCase().contains(query) ||
                  item.$2.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: pageBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkGreen, green],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.description_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'दस्तऐवज सेवा',
                          style: TextStyle(
                            fontSize: 21,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'तुमचा आवश्यक दस्तऐवज निवडा',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            AppLanguage.instance.translate('दस्तऐवज शोधा...'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('दस्तऐवज सापडला नाही.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isSelected = temporarySelection == item.$1;

                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isSelected
                                          ? item.$4
                                          : const Color(0xFFE0E8E2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        item.$4.withValues(alpha: 0.12),
                                    child: Icon(
                                      item.$3,
                                      color: item.$4,
                                    ),
                                  ),
                                  title: Text(
                                    item.$2,
                                    style: const TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(item.$1),
                                  trailing: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color:
                                        isSelected ? item.$4 : Colors.black38,
                                  ),
                                  onTap: () {
                                    setSheetState(() {
                                      temporarySelection = item.$1;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: temporarySelection == null
                            ? null
                            : () => Navigator.pop(
                                  sheetContext,
                                  temporarySelection,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('निवड निश्चित करा'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (!mounted || result == null) return;

    final match = documents.where((item) => item.$1 == result);
    if (match.isEmpty) return;

    setState(() {
      selectedCategory = 'दस्तऐवज';
      selectedDocument = match.first.$2;
    });
  }

  Future<void> pickMedia(bool video) async {
    try {
      final file = video
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);

      if (file != null && mounted) {
        setState(() {
          selectedMedia = file;
          isVideo = video;
        });
      }
    } catch (error) {
      showMessage('फोटो किंवा व्हिडिओ निवडता आला नाही.');
    }
  }

  Future<void> openVoiceRecording() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => VoiceRecordingScreen(
          language: selectedLanguage,
          onVoiceResult: (_) {},
        ),
      ),
    );

    if (!mounted || result == null || result.trim().isEmpty) {
      return;
    }

    setState(() {
      final oldText = descriptionController.text.trim();
      descriptionController.text =
          oldText.isEmpty ? result.trim() : '$oldText ${result.trim()}';

      descriptionController.selection = TextSelection.collapsed(
        offset: descriptionController.text.length,
      );
    });
  }

  void submitComplaint() {
    if (selectedCategory == null) {
      showMessage('कृपया समस्येचा प्रकार निवडा.');
      return;
    }

    if (selectedCategory == 'दस्तऐवज' && selectedDocument == null) {
      showMessage('कृपया दस्तऐवजाचा प्रकार निवडा.');
      showDocumentOptions();
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final department =
        departmentMapping[selectedCategory!] ?? 'ग्रामपंचायत विभाग';

    final localizedCategory = AppLanguage.instance.translate(
      selectedCategory!,
    );
    final localizedDocument = selectedDocument == null
        ? null
        : AppLanguage.instance.translate(selectedDocument!);
    final finalCategory = localizedDocument == null
        ? localizedCategory
        : '$localizedCategory - $localizedDocument';
    final localizedDepartment = AppLanguage.instance.translate(department);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LocationMapScreen(
          category:
              '$finalCategory (${AppLanguage.instance.translate('विभाग')}: $localizedDepartment)',
          location: locationController.text.trim(),
          description: descriptionController.text.trim(),
          attachment: selectedMedia,
          isVideo: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'समस्या नोंदवा',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: pageBackground),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.91),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 750;
                final categoryColumns = constraints.maxWidth >= 1000
                    ? 5
                    : wide
                        ? 4
                        : 2;

                return Form(
                  key: formKey,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 28 : 16,
                      vertical: 18,
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [darkGreen, Color(0xFF19A866)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.campaign_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'तुमची समस्या सांगा',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'लिहा, बोलून सांगा किंवा फोटो जोडा.',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        '१. तक्रारीची भाषा',
                        Icons.language_rounded,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedLanguage,
                        decoration: _decoration(
                          'भाषा निवडा',
                          Icons.translate_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Marathi',
                            child: Text('मराठी'),
                          ),
                          DropdownMenuItem(
                            value: 'Hindi',
                            child: Text('हिंदी'),
                          ),
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              selectedLanguage = value;
                            });
                            try {
                              await AppLanguage.instance.setLanguage(value);
                            } catch (error) {
                              debugPrint(
                                'Could not save app language: $error',
                              );
                              showMessage(
                                AppLanguage.instance.translate(
                                  'भाषा जतन करता आली नाही.',
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        '२. समस्येचा प्रकार निवडा',
                        Icons.grid_view_rounded,
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: categoryColumns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.02,
                        ),
                        itemBuilder: (context, index) {
                          final item = categories[index];
                          final selected = selectedCategory == item.$1;

                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (item.$1 == 'दस्तऐवज') {
                                  showDocumentOptions();
                                } else {
                                  setState(() {
                                    selectedCategory = item.$1;
                                    selectedDocument = null;
                                  });
                                }
                              },
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? item.$4.withValues(alpha: 0.10)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? item.$4
                                        : const Color(0xFFE0EAE3),
                                    width: selected ? 2 : 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x08000000),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (item.$2.isNotEmpty)
                                            Image.asset(
                                              item.$2,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return _categoryImageFallback(
                                                  item.$3,
                                                  item.$4,
                                                );
                                              },
                                            )
                                          else
                                            _categoryImageFallback(
                                              item.$3,
                                              item.$4,
                                            ),
                                          if (selected)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: DecoratedBox(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle_rounded,
                                                  color: item.$4,
                                                  size: 23,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 7,
                                      ),
                                      child: Text(
                                        item.$1,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.15,
                                          fontWeight: FontWeight.w700,
                                          color: navy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (selectedDocument != null) ...[
                        const SizedBox(height: 12),
                        ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: const Icon(
                            Icons.verified_rounded,
                            color: green,
                          ),
                          title: const Text('निवडलेला दस्तऐवज'),
                          subtitle: Text(selectedDocument!),
                          trailing: IconButton(
                            onPressed: showDocumentOptions,
                            icon: const Icon(Icons.edit_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _sectionTitle(
                        '३. समस्येचे ठिकाण',
                        Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: locationController,
                        textInputAction: TextInputAction.next,
                        decoration: _decoration(
                          'गाव / परिसर / ठिकाण लिहा',
                          Icons.location_on_outlined,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? AppLanguage.instance.translate(
                                    'समस्येचे ठिकाण लिहा.',
                                  )
                                : null,
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        '४. समस्येचे वर्णन',
                        Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _decoration(
                          'उदा. आमच्या गावात तीन दिवसांपासून पाणी आले नाही.',
                          Icons.notes_rounded,
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 10
                                ? AppLanguage.instance.translate(
                                    'किमान १० अक्षरांत समस्या लिहा.',
                                  )
                                : null,
                      ),
                      OutlinedButton.icon(
                        onPressed: openVoiceRecording,
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('बोलून तक्रार सांगा'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: green,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        '५. फोटो / व्हिडिओ जोडा',
                        Icons.perm_media_rounded,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickMedia(false),
                              icon: const Icon(Icons.add_a_photo_rounded),
                              label: const Text('फोटो निवडा'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: green,
                                minimumSize: const Size(0, 46),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickMedia(true),
                              icon: const Icon(Icons.video_library_rounded),
                              label: const Text('व्हिडिओ निवडा'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: green,
                                minimumSize: const Size(0, 46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedMedia != null) ...[
                        const SizedBox(height: 10),
                        Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(
                              isVideo
                                  ? Icons.video_file_rounded
                                  : Icons.image_rounded,
                              color: green,
                            ),
                            title: Text(
                              selectedMedia!.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  selectedMedia = null;
                                  isVideo = false;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: submitComplaint,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(
                            'पुढे जा — तक्रार तपासा',
                            style: TextStyle(
                              fontSize: 15,
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
                      const SizedBox(height: 14),
                      const Center(
                        child: Text(
                          'GramSaksham • तुमचा आवाज, तुमचा अधिकार',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: green, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryImageFallback(IconData icon, Color color) {
    return ColoredBox(
      color: color.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 54,
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: AppLanguage.instance.translate(hint),
      prefixIcon: Icon(icon, color: green),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
    );
  }
}
