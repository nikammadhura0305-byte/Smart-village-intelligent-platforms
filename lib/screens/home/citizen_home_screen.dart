import '../../app_ui.dart';
import '../../language/app_language.dart';

import '../complaints/report_problem_screen.dart';
import '../complaints/my_complaints_screen.dart';
import 'ai_sahayak_screen.dart';
import 'notifications_screen.dart' as app_notifications;
import '../../widgets/gramsaksham_mark.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  static const Color darkGreen = Color(0xFF075D35);

  void _openScreen(
    BuildContext context,
    Widget screen,
    String screenName,
  ) {
    debugPrint('$screenName BUTTON CLICKED');

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => _buildHome(context),
    );
  }

  Widget _buildHome(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFFF4F8F4)),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width >= 1000 ? 48 : 16,
                      12,
                      MediaQuery.sizeOf(context).width >= 1000 ? 48 : 16,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLanguage.instance.translate('नमस्कार!'),
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          AppLanguage.instance.translate(
                            'गावातील सेवा आणि सुविधांसाठी पर्याय निवडा.',
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const columnGap = 9.0;
                              const rowGap = 12.0;
                              final widthLimitedSide =
                                  (constraints.maxWidth - columnGap) / 2;
                              final heightLimitedSide =
                                  (constraints.maxHeight - rowGap) / 2;
                              final cardSide =
                                  widthLimitedSide < heightLimitedSide
                                      ? widthLimitedSide
                                      : heightLimitedSide;

                              return Center(
                                child: SizedBox(
                                  width: cardSide * 2 + columnGap,
                                  height: cardSide * 2 + rowGap,
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: columnGap,
                                    mainAxisSpacing: rowGap,
                                    childAspectRatio: 1,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      _serviceButton(
                                        title: 'समस्या नोंदवा',
                                        icon: Icons.edit_document,
                                        color: const Color(0xFF168A5B),
                                        onTap: () => _openScreen(
                                          context,
                                          const ReportProblemScreen(),
                                          'REPORT PROBLEM',
                                        ),
                                      ),
                                      _serviceButton(
                                        title: 'माझ्या तक्रारी',
                                        icon: Icons.description_outlined,
                                        color: const Color(0xFF3298C8),
                                        onTap: () => _openScreen(
                                          context,
                                          const MyComplaintsScreen(),
                                          'MY COMPLAINTS',
                                        ),
                                      ),
                                      _serviceButton(
                                        title: 'सूचना',
                                        icon: Icons.notifications_none_rounded,
                                        color: const Color(0xFFD96C8A),
                                        onTap: () => _openScreen(
                                          context,
                                          const app_notifications
                                              .NotificationsScreen(),
                                          'NOTIFICATIONS',
                                        ),
                                      ),
                                      _serviceButton(
                                        title: 'AI सहाय्यक',
                                        icon: Icons.psychology_alt_rounded,
                                        color: const Color(0xFFD99A32),
                                        onTap: () => _openScreen(
                                          context,
                                          const AiSahayakScreen(),
                                          'AI ASSISTANT',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bottomNavigation(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 14, 0),
        child: Row(
          children: [
            const GramSakshamMark(size: 46),
            const SizedBox(width: 11),
            const Text(
              'ग्रामसक्षम',
              style: TextStyle(
                color: darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: AppLanguage.instance.translate('Notifications'),
              onPressed: () => _openScreen(
                context,
                const app_notifications.NotificationsScreen(),
                'HEADER NOTIFICATIONS',
              ),
              icon: const Icon(
                Icons.notifications_outlined,
                color: darkGreen,
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 34),
                const SizedBox(height: 10),
                Text(
                  AppLanguage.instance.translate(title),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(22),
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
            () => _openScreen(
              context,
              const MyComplaintsScreen(),
              'BOTTOM COMPLAINTS',
            ),
          ),
          _navItem(
            Icons.notifications_none_rounded,
            'Notifications',
            false,
            () => _openScreen(
              context,
              const app_notifications.NotificationsScreen(),
              'BOTTOM NOTIFICATIONS',
            ),
          ),
          _navItem(
            Icons.person_outline_rounded,
            'Profile',
            false,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLanguage.instance.translate(
                      'Profile लवकरच उपलब्ध होईल.',
                    ),
                  ),
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
              color: selected ? const Color(0xFF078746) : Colors.blueGrey,
            ),
            const SizedBox(height: 3),
            Text(
              AppLanguage.instance.translate(label),
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF078746) : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
