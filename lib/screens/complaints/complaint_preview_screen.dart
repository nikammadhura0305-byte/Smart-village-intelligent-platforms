import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';

import '../../app_ui.dart';
import '../../language/app_language.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/complaint_storage.dart';
import '../../widgets/gramsaksham_mark.dart';
import 'offline_storage_screen.dart';

class ComplaintPreviewScreen extends StatelessWidget {
  final String category;
  final String location;
  final String description;
  final XFile? attachment;
  final bool isVideo;
  final String? liveGpsCoordinates;

  const ComplaintPreviewScreen({
    super.key,
    required this.category,
    required this.location,
    required this.description,
    this.attachment,
    this.isVideo = false,
    this.liveGpsCoordinates,
  });

  static const Color primaryGreen = Color(0xFF218653);
  static const Color darkGreen = Color(0xFF075B35);
  static const Color navy = Color(0xFF234332);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF3F7F4),
        appBar: AppBar(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _text(
              mr: 'तक्रारीचा आढावा',
              hi: 'शिकायत की समीक्षा',
              en: 'Review complaint',
            ),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFFEAF3EC)),
            ),
            const ColoredBox(color: Color(0xD9FFFFFF)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: GramSakshamMark(size: 64)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Color(0xFFE1F4E8),
                              child: Icon(
                                Icons.fact_check_rounded,
                                size: 38,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              _text(
                                mr: 'तक्रार तपासून घ्या',
                                hi: 'शिकायत की समीक्षा करें',
                                en: 'Review your complaint',
                              ),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _text(
                                mr: 'सबमिट करण्यापूर्वी माहिती तपासा.',
                                hi: 'सबमिट करने से पहले जानकारी जाँचें।',
                                en: 'Check the details before submitting.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDetail(
                            icon: Icons.category_rounded,
                            title: _text(
                              mr: 'तक्रारीचा प्रकार',
                              hi: 'शिकायत की श्रेणी',
                              en: 'Complaint category',
                            ),
                            value: category,
                            translateValue: false,
                          ),
                          const Divider(height: 28),
                          _buildDetail(
                            icon: Icons.location_on_rounded,
                            title: _text(
                              mr: 'तक्रारीचे गाव',
                              hi: 'शिकायत का गाँव',
                              en: 'Complaint village',
                            ),
                            value: location.trim().isEmpty
                                ? _text(
                                    mr: 'ठिकाण दिलेले नाही',
                                    hi: 'स्थान नहीं दिया गया',
                                    en: 'Location not provided',
                                  )
                                : location,
                            translateValue: false,
                          ),
                          if (liveGpsCoordinates != null) ...[
                            const Divider(height: 28),
                            _buildDetail(
                              icon: Icons.my_location_rounded,
                              title: _text(
                                mr: 'प्रत्यक्ष GPS निर्देशांक',
                                hi: 'वास्तविक GPS निर्देशांक',
                                en: 'Actual device GPS coordinates',
                              ),
                              value: liveGpsCoordinates!,
                              translateValue: false,
                            ),
                          ],
                          const Divider(height: 28),
                          _buildDetail(
                            icon: Icons.description_rounded,
                            title: _text(
                              mr: 'तक्रारीचे वर्णन',
                              hi: 'शिकायत का विवरण',
                              en: 'Complaint description',
                            ),
                            value: description.trim().isEmpty
                                ? _text(
                                    mr: 'वर्णन दिलेले नाही',
                                    hi: 'विवरण नहीं दिया गया',
                                    en: 'No description provided',
                                  )
                                : description,
                            translateValue: false,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _text(
                              mr: 'फोटो / व्हिडिओ',
                              hi: 'फ़ोटो / वीडियो',
                              en: 'Photo / video',
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildAttachment(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.edit_rounded),
                            label: Text(
                              _text(mr: 'बदल करा', hi: 'बदलें', en: 'Edit'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryGreen,
                              side: const BorderSide(color: primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmSubmission(context),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              _text(
                                  mr: 'सबमिट', hi: 'सबमिट करें', en: 'Submit'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _text(
                          mr: 'माहिती योग्य असल्याची खात्री करा.',
                          hi: 'जानकारी सही होने की पुष्टि करें।',
                          en: 'Make sure the information is correct.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSubmission(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.fact_check_rounded,
          color: primaryGreen,
          size: 42,
        ),
        title: Text(
          _text(
            mr: 'तक्रार सबमिट करायची?',
            hi: 'क्या शिकायत सबमिट करें?',
            en: 'Submit this complaint?',
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          _text(
            mr: 'तुम्ही दिलेली माहिती तपासून पुढे जायचे आहे का?',
            hi: 'क्या आप दी गई जानकारी की जाँच करके आगे बढ़ना चाहते हैं?',
            en: 'Would you like to review the details and continue?',
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              _text(
                  mr: 'पुन्हा तपासा', hi: 'फिर से जाँचें', en: 'Review again'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              _text(mr: 'पुष्टी करा', hi: 'पुष्टि करें', en: 'Confirm'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ComplaintStorage.saveComplaint(
        category: category,
        location: location,
        description: description,
      );

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OfflineStorageScreen(
            category: category,
            location: location,
            description: description,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('Complaint could not be saved: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              mr: 'तक्रार जतन करता आली नाही. पुन्हा प्रयत्न करा.',
              hi: 'शिकायत सेव नहीं हो सकी। फिर से प्रयास करें।',
              en: 'The complaint could not be saved. Please try again.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetail({
    required IconData icon,
    required String title,
    required String value,
    bool translateValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen, size: 23),
        ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                translate: translateValue,
                style: const TextStyle(
                  color: Color(0xFF26352B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachment() {
    if (attachment == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F4),
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.perm_media_outlined, size: 35, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _text(
                mr: 'कोणताही फोटो किंवा व्हिडिओ जोडलेला नाही.',
                hi: 'कोई फ़ोटो या वीडियो संलग्न नहीं है।',
                en: 'No photo or video attached.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (isVideo) {
      return _VideoAttachmentPreview(
        attachment: attachment!,
        text: _text,
      );
    }

    return FutureBuilder(
      future: attachment!.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _text(
                mr: 'फोटो दाखवता आला नाही.',
                hi: 'फ़ोटो नहीं दिखाया जा सका।',
                en: 'The photo could not be displayed.',
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _text(
                  mr: 'फोटो दाखवता आला नाही.',
                  hi: 'फ़ोटो नहीं दिखाया जा सका।',
                  en: 'The photo could not be displayed.',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _text({
    required String mr,
    required String hi,
    required String en,
  }) =>
      AppLanguage.instance.text(mr: mr, hi: hi, en: en);
}

class _VideoAttachmentPreview extends StatefulWidget {
  const _VideoAttachmentPreview({
    required this.attachment,
    required this.text,
  });

  final XFile attachment;
  final String Function({
    required String mr,
    required String hi,
    required String en,
  }) text;

  @override
  State<_VideoAttachmentPreview> createState() =>
      _VideoAttachmentPreviewState();
}

class _VideoAttachmentPreviewState extends State<_VideoAttachmentPreview> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(_videoUri());
  late final Future<void> _initialization =
      _controller.initialize().timeout(const Duration(seconds: 20));
  bool _playbackFailed = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_controllerChanged);
  }

  void _controllerChanged() {
    final isPlaying = _controller.value.isPlaying;
    if (mounted && isPlaying != _isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }
  }

  Uri _videoUri() {
    final path = widget.attachment.path;
    if (kIsWeb) return Uri.parse(path);
    final uri = Uri.tryParse(path);
    return uri != null && uri.hasScheme ? uri : Uri.file(path);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      if (_controller.value.isPlaying) {
        await _controller.pause();
      } else {
        await _controller.play();
      }
    } catch (error, stackTrace) {
      debugPrint('Could not play complaint video: $error\n$stackTrace');
      if (mounted) setState(() => _playbackFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError || _playbackFailed) {
            return Column(
              children: [
                Text(
                  widget.text(
                    mr: 'व्हिडिओचे पूर्वावलोकन करता आले नाही.',
                    hi: 'वीडियो का पूर्वावलोकन नहीं हो सका।',
                    en: 'The video preview could not be opened.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(widget.attachment.name),
              ],
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  widget.text(
                    mr: 'व्हिडिओ लोड होत आहे...',
                    hi: 'वीडियो लोड हो रहा है...',
                    en: 'Loading video preview...',
                  ),
                ),
              ],
            );
          }

          final aspectRatio = _controller.value.aspectRatio;
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                  child: VideoPlayer(_controller),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: widget.text(
                      mr: _isPlaying ? 'व्हिडिओ थांबवा' : 'व्हिडिओ चालवा',
                      hi: _isPlaying ? 'वीडियो रोकें' : 'वीडियो चलाएँ',
                      en: _isPlaying ? 'Pause video' : 'Play video',
                    ),
                    onPressed: _togglePlayback,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
