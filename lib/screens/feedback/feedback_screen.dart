import '../../app_ui.dart';
import '../../language/app_language.dart';

class FeedbackScreen extends StatefulWidget {
  final String complaintId;
  final String category;

  const FeedbackScreen({
    super.key,
    this.complaintId = 'GS-2026-001',
    this.category = 'Water Supply',
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const Color primary = Color(0xFF176B55);

  int _rating = 0;
  String _experience = 'Satisfied';
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.instance.translate('Please select a star rating.'),
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Thank You!'),
        content: Text(
          'Your feedback has been recorded in this demo.\n\n'
          'Complaint: ${widget.complaintId}\n'
          'Rating: $_rating/5\n'
          'Experience: $_experience',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Citizen Feedback'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primary, Color(0xFF27876C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.volunteer_activism_outlined,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your Voice Matters!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Help us improve village services '
                          'by sharing your experience.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE5F3EC),
                        child: Icon(
                          Icons.confirmation_number_outlined,
                          color: primary,
                        ),
                      ),
                      title: const Text(
                        'Complaint ID',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      subtitle: Text(
                        widget.complaintId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.verified_outlined,
                        color: primary,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE5F3EC),
                        child: Icon(
                          Icons.category_outlined,
                          color: primary,
                        ),
                      ),
                      title: const Text(
                        'Service Category',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      subtitle: Text(widget.category),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'How would you rate our service?',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 10,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final selected = index < _rating;
                              return IconButton(
                                onPressed: () {
                                  setState(() => _rating = index + 1);
                                },
                                icon: Icon(
                                  selected ? Icons.star : Icons.star_border,
                                  color: const Color(0xFFFFB300),
                                  size: 38,
                                ),
                              );
                            }),
                          ),
                          Text(
                            _rating == 0
                                ? 'Select your rating'
                                : '$_rating ${AppLanguage.instance.translate('out of 5 stars')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    ('Very Satisfied', Icons.sentiment_very_satisfied),
                    ('Satisfied', Icons.sentiment_satisfied),
                    ('Neutral', Icons.sentiment_neutral),
                    ('Dissatisfied', Icons.sentiment_dissatisfied),
                  ].map(
                    (item) => Card(
                      elevation: 0,
                      child: RadioListTile<String>(
                        value: item.$1,
                        groupValue: _experience,
                        activeColor: primary,
                        title: Text(item.$1),
                        secondary: Icon(item.$2, color: primary),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _experience = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: AppLanguage.instance.translate(
                        'Additional Feedback (Optional)',
                      ),
                      hintText: AppLanguage.instance.translate(
                        'Share your suggestions...',
                      ),
                      prefixIcon: Icon(Icons.rate_review_outlined),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _submitFeedback,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Demo mode: feedback is not saved to a database.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
