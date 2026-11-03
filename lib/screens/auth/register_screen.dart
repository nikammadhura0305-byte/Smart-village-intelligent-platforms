import '../../app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../language/app_language.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedLanguage;

  const RegisterScreen({
    super.key,
    this.selectedLanguage = 'मराठी',
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final villageController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  static const Color green = Color(0xFF087A3E);
  static const Color darkGreen = Color(0xFF07552F);

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    villageController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'user_name',
        nameController.text.trim(),
      );
      await prefs.setString(
        'user_mobile',
        mobileController.text.trim(),
      );
      await prefs.setString(
        'user_village',
        villageController.text.trim(),
      );
      await prefs.setString(
        'user_password',
        passwordController.text,
      );

      await prefs.setBool('is_registered', true);
      await prefs.setBool('is_logged_in', false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Please try again.'),
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
          // Village background
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Color(0xFFE8F2E8),
              );
            },
          ),

          // Light overlay
          Container(
            color: Colors.white.withAlpha(65),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(242),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Registration icon
                          Center(
                            child: Container(
                              height: 76,
                              width: 76,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F3E9),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: green,
                                size: 42,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'नवीन खाते तयार करा',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'ग्रामसक्षममध्ये आपले स्वागत आहे',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildLabel('पूर्ण नाव'),
                          _buildField(
                            controller: nameController,
                            hint: 'तुमचे पूर्ण नाव टाका',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLanguage.instance.translate(
                                  'कृपया तुमचे नाव टाका',
                                );
                              }
                              return null;
                            },
                          ),

                          _buildLabel('मोबाईल नंबर'),
                          _buildField(
                            controller: mobileController,
                            hint: '10 अंकी मोबाईल नंबर',
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(r'^[6-9][0-9]{9}$')
                                      .hasMatch(value.trim())) {
                                return AppLanguage.instance.translate(
                                  'योग्य 10 अंकी मोबाईल नंबर टाका',
                                );
                              }
                              return null;
                            },
                          ),

                          _buildLabel('गावाचे नाव'),
                          _buildField(
                            controller: villageController,
                            hint: 'तुमच्या गावाचे नाव टाका',
                            icon: Icons.location_on_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLanguage.instance.translate(
                                  'कृपया गावाचे नाव टाका',
                                );
                              }
                              return null;
                            },
                          ),

                          _buildLabel('पासवर्ड तयार करा'),
                          _buildField(
                            controller: passwordController,
                            hint: 'किमान 6 अक्षरे',
                            icon: Icons.lock_outline,
                            obscureText: hidePassword,
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
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return AppLanguage.instance.translate(
                                  'पासवर्ड किमान 6 अक्षरांचा असावा',
                                );
                              }
                              return null;
                            },
                          ),

                          _buildLabel('पासवर्ड पुन्हा टाका'),
                          _buildField(
                            controller: confirmPasswordController,
                            hint: 'पासवर्ड पुन्हा टाका',
                            icon: Icons.verified_user_outlined,
                            obscureText: hideConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hideConfirmPassword = !hideConfirmPassword;
                                });
                              },
                              icon: Icon(
                                hideConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLanguage.instance.translate(
                                  'पासवर्ड पुन्हा टाका',
                                );
                              }

                              if (value != passwordController.text) {
                                return AppLanguage.instance.translate(
                                  'दोन्ही पासवर्ड जुळत नाहीत',
                                );
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 26),

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Register करा',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  'आधीच खाते आहे?',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'ग्रामसक्षम • स्मार्ट व्हिलेज सेवा',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        top: 14,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF263B30),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        hintText: AppLanguage.instance.translate(hint),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF39805A),
        ),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF2F7F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFDCE7DE),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFDCE7DE),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFF39805A),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
