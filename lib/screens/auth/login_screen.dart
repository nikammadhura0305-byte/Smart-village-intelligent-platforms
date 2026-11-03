import '../../app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../language/app_language.dart';
import '../../widgets/gramsaksham_mark.dart';

import 'register_screen.dart';
import '../home/citizen_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final mobileController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  static const Color green = Color(0xFF087A3E);
  static const Color darkGreen = Color(0xFF07552F);

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Registration madhil saved details
      final savedMobile = prefs.getString('user_mobile');
      final savedPassword = prefs.getString('user_password');

      final enteredMobile = mobileController.text.trim();
      final enteredPassword = passwordController.text;
      debugPrint('Saved mobile exists: ${savedMobile != null}');
      debugPrint('Saved password exists: ${savedPassword != null}');
      debugPrint('Entered mobile matches: ${enteredMobile == savedMobile}');
      debugPrint(
          'Entered password matches: ${enteredPassword == savedPassword}');

      if (savedMobile == null || savedPassword == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please register first!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mobile number ani password donhi check hotil
      if (enteredMobile != savedMobile || enteredPassword != savedPassword) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'चुकीचा मोबाइल नंबर किंवा पासवर्ड!',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CitizenHomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Color(0xFFE8F2E8),
              );
            },
          ),
          Container(
            color: Colors.white.withAlpha(65),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 380,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0EBE2)),
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withValues(alpha: 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GramSakshamMark(size: 66),
                          const SizedBox(height: 12),
                          const Text(
                            'ग्रामसक्षम',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'आपले स्वागत आहे',
                            style: TextStyle(
                              fontSize: 15,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Mobile number
                          TextFormField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText:
                                  AppLanguage.instance.translate('मोबाईल नंबर'),
                              counterText: '',
                              prefixIcon: const Icon(
                                Icons.phone_android,
                                color: green,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F7F2),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(r'^[0-9]{10}$')
                                      .hasMatch(value.trim())) {
                                return AppLanguage.instance.translate(
                                  '10 अंकी मोबाइल नंबर टाका',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText:
                                  AppLanguage.instance.translate('पासवर्ड'),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: green,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F7F2),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLanguage.instance.translate(
                                  'पासवर्ड टाका',
                                );
                              }
                              return null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password reset feature coming soon.',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'पासवर्ड विसरलात?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: green,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Register navigation
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(fontSize: 13),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(
                                        selectedLanguage: 'मराठी',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
