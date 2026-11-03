import '../../app_ui.dart';
import '../../language/app_language.dart';
import '../../services/complaint_storage.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  static const Color green = Color(0xFF218653);
  static const Color darkGreen = Color(0xFF145C3A);

  String _filter = 'सर्व';
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final data = await ComplaintStorage.getComplaints();

      if (!mounted) return;

      setState(() {
        _complaints =
            data.map((item) => Map<String, dynamic>.from(item)).toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'तक्रारी लोड करता आल्या नाहीत.';
      });
    }
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'Pending':
      case 'प्रलंबित':
        return 'प्रलंबित';
      case 'In Progress':
      case 'कार्यवाही सुरू':
        return 'कार्यवाही सुरू';
      case 'Resolved':
      case 'निराकरण झाले':
        return 'निराकरण झाले';
      default:
        return status.isEmpty ? 'प्रलंबित' : status;
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final months = switch (AppLanguage.instance.locale.languageCode) {
      'hi' => const [
          'जनवरी',
          'फ़रवरी',
          'मार्च',
          'अप्रैल',
          'मई',
          'जून',
          'जुलाई',
          'अगस्त',
          'सितंबर',
          'अक्टूबर',
          'नवंबर',
          'दिसंबर',
        ],
      'en' => const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ],
      _ => const [
          'जानेवारी',
          'फेब्रुवारी',
          'मार्च',
          'एप्रिल',
          'मे',
          'जून',
          'जुलै',
          'ऑगस्ट',
          'सप्टेंबर',
          'ऑक्टोबर',
          'नोव्हेंबर',
          'डिसेंबर',
        ],
    };

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String status) {
    switch (_displayStatus(status)) {
      case 'निराकरण झाले':
        return green;
      case 'कार्यवाही सुरू':
        return const Color(0xFF2376C9);
      default:
        return Colors.orange.shade800;
    }
  }

  IconData _statusIcon(String status) {
    switch (_displayStatus(status)) {
      case 'निराकरण झाले':
        return Icons.check_circle_rounded;
      case 'कार्यवाही सुरू':
        return Icons.engineering_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_filter == 'सर्व') return _complaints;

    return _complaints.where((item) {
      final status = _displayStatus(
        item['status']?.toString() ?? 'Pending',
      );
      return status == _filter;
    }).toList();
  }

  int _countStatus(String status) {
    return _complaints.where((item) {
      return _displayStatus(
            item['status']?.toString() ?? 'Pending',
          ) ==
          status;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredComplaints;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'माझ्या तक्रारी',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: AppLanguage.instance.translate('Refresh'),
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadComplaints,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _headerCard(),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, box) {
                            final cardWidth = (box.maxWidth - 20) / 3;

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _summaryCard(
                                  width: cardWidth,
                                  title: 'एकूण',
                                  count: '${_complaints.length}',
                                  icon: Icons.receipt_long_rounded,
                                  color: green,
                                ),
                                _summaryCard(
                                  width: cardWidth,
                                  title: 'प्रलंबित',
                                  count: '${_countStatus('प्रलंबित')}',
                                  icon: Icons.pending_actions_rounded,
                                  color: Colors.orange.shade800,
                                ),
                                _summaryCard(
                                  width: cardWidth,
                                  title: 'पूर्ण',
                                  count: '${_countStatus('निराकरण झाले')}',
                                  icon: Icons.task_alt_rounded,
                                  color: Colors.blue.shade700,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'तक्रारींची यादी',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('सर्व'),
                              const SizedBox(width: 8),
                              _filterChip('प्रलंबित'),
                              const SizedBox(width: 8),
                              _filterChip('कार्यवाही सुरू'),
                              const SizedBox(width: 8),
                              _filterChip('निराकरण झाले'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          _messageCard(
                            icon: Icons.error_outline_rounded,
                            message: _error!,
                            buttonText: 'पुन्हा प्रयत्न करा',
                            onPressed: _loadComplaints,
                          )
                        else if (filtered.isEmpty)
                          _messageCard(
                            icon: Icons.inbox_rounded,
                            message: _filter == 'सर्व'
                                ? 'अजून कोणतीही तक्रार सेव्ह केलेली नाही.'
                                : 'या स्थितीतील तक्रार उपलब्ध नाही.',
                          )
                        else
                          ...filtered.map(_complaintCard),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF218653), Color(0xFF145C3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'नमस्कार, नागरिक!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'तुमच्या तक्रारींचा आढावा',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'तक्रारींची स्थिती येथे तपासा.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.assignment_rounded,
            size: 55,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = label),
      selectedColor: green,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : darkGreen,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? green : const Color(0xFFDDE9E0),
      ),
      showCheckmark: false,
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDDE9E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _complaintCard(Map<String, dynamic> item) {
    final status = _displayStatus(
      item['status']?.toString() ?? 'Pending',
    );
    final color = _statusColor(status);
    final id = item['id']?.toString() ?? '';
    final category = item['category']?.toString() ?? '';
    final location = item['location']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final date = _formatDate(item['date']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFDDE9E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: green,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.isEmpty ? 'तक्रार' : category,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ID: $id',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            translate: false,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF26352B),
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.location_on_outlined, location),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_month_rounded, date),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(status), size: 17, color: color),
                const SizedBox(width: 7),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'माहिती उपलब्ध नाही' : value,
            translate: value.isEmpty,
            softWrap: true,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE9E0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.black38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ],
      ),
    );
  }
}
