import '../../app_ui.dart';

import '../complaints/report_problem_screen.dart';
import '../complaints/my_complaints_screen.dart';
import 'ai_sahayak_screen.dart';
import 'notifications_screen.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  static const Color green = Color(0xFF078746);
  static const Color navy = Color(0xFF174D35);

  void _openComplaints(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyComplaintsScreen(),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openAiAssistant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiSahayakScreen(),
      ),
    );
  }

  void _openReportProblem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportProblemScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFF3F7F4),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _villageHeader(context),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            10,
                            12,
                            12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'नमस्कार!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: navy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'गावातील सेवा आणि सुविधांसाठी पर्याय निवडा.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Four compact buttons in one row.
                              Row(
                                children: [
                                  Expanded(
                                    child: _featureCard(
                                      title: 'समस्या नोंदवा',
                                      subtitle: 'Report',
                                      icon: Icons.edit_document,
                                      colors: const [
                                        Color(0xFF13B94E),
                                        Color(0xFF008B50),
                                      ],
                                      onTap: () => _openReportProblem(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _featureCard(
                                      title: 'माझ्या तक्रारी',
                                      subtitle: 'Complaints',
                                      icon: Icons.description_outlined,
                                      colors: const [
                                        Color(0xFF168FF0),
                                        Color(0xFF0759D7),
                                      ],
                                      onTap: () => _openComplaints(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _featureCard(
                                      title: 'सूचना',
                                      subtitle: 'Notifications',
                                      icon: Icons.notifications_none_rounded,
                                      colors: const [
                                        Color(0xFFFFB321),
                                        Color(0xFFF47B08),
                                      ],
                                      onTap: () => _openNotifications(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _featureCard(
                                      title: 'AI सहाय्यक',
                                      subtitle: 'AI Assistant',
                                      icon: Icons.psychology_alt_rounded,
                                      colors: const [
                                        Color(0xFFAA49E8),
                                        Color(0xFF7028C6),
                                      ],
                                      onTap: () => _openAiAssistant(context),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Welcome information card.
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.90,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFDDE9E0),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.location_city_rounded,
                                      color: green,
                                      size: 32,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ग्रामसक्षम',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: navy,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'गावातील समस्या नोंदवा आणि '
                                            'उपलब्ध सेवांसाठी मदत मिळवा.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bottomNav(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _villageHeader(BuildContext context) {
    return SizedBox(
      height: 76,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 0),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/village_background.jpeg',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.10),
                errorBuilder: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  color: Colors.white,
                  child: const Icon(
                    Icons.eco_rounded,
                    color: green,
                    size: 26,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'सूचना',
              onPressed: () => _openNotifications(context),
              icon: const Icon(
                Icons.notifications_outlined,
                color: navy,
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 7,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 21,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
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

  Widget _bottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_rounded,
            'Home',
            true,
            () {},
          ),
          _navItem(
            Icons.assignment_outlined,
            'Complaints',
            false,
            () => _openComplaints(context),
          ),
          _navItem(
            Icons.notifications_none_rounded,
            'Notifications',
            false,
            () => _openNotifications(context),
          ),
          _navItem(
            Icons.person_outline_rounded,
            'Profile',
            false,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('प्रोफाइल स्क्रीन अजून तयार नाही.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? green : Colors.blueGrey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? green : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
