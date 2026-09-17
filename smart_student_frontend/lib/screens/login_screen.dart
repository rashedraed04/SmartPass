import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../providers/settings_provider.dart';
import 'main_screen.dart';
import 'admin_home_screen.dart';
import 'package:smart_student_frontend/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تنبيه'),
          content: const Text('يرجى إدخال بريدك الإلكتروني أولاً'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // TODO: Implement password reset when backend endpoint is ready
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // TODO: Implement Google sign-in via backend OAuth endpoint
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تسجيل الدخول بحساب Google قيد التطوير'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('fill_all_fields'.tr())));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ── Step 1: REST API login (JWT) ──
      final result = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final String token = result['token'] ?? '';
      final String role = result['role'] ?? 'user';
      final bool isAdmin = role == 'admin';

      // ── Step 2: Smart routing ──
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin
                ? const AdminHomeScreen()
                : MainScreen(
                    email: _emailController.text.trim(),
                    token: token,
                  ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = context.locale.languageCode == 'ar';
    String t(String key) => key.tr();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar (Theme Toggle + Language Switcher) ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Theme Toggle Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                            color: primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            value: isDark,
                            onChanged: (_) => settings.toggleTheme(),
                            activeColor: primary,
                            activeTrackColor: primary.withValues(alpha: 0.4),
                            inactiveThumbColor: primary,
                            inactiveTrackColor: primary.withValues(alpha: 0.25),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),

                    // Language Toggle Pill
                    GestureDetector(
                      onTap: () async {
                        final newLocale = isAr
                            ? const Locale('en')
                            : const Locale('ar');
                        await context.setLocale(newLocale);
                        await settings.setLocale(newLocale);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language, color: primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              isAr ? 'English' : 'عربي',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // ── University App Logo ─────────────────────────────
                      Center(
                        child: Image.asset(
                          isDark
                              ? 'assets/images/app_logo_dark.png'
                              : 'assets/images/app_logo_light.png',
                          height: 85,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Title ──────────────────────────────────────────
                      Text(
                        t('login_student'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : primary,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('welcome_student'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // ── Form Card ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF002400)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? primary.withValues(alpha: 0.25)
                                : primary.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email field
                            Text(
                              t('email'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'example@university.edu',
                              suffixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isDark: isDark,
                              primary: primary,
                            ),
                            const SizedBox(height: 20),

                            // Password row header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t('password'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _resetPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    t('forgot_password'),
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF00E676)
                                          : primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hint: '••••••••',
                              obscure: _obscurePassword,
                              suffixIcon: Icons.lock_outline,
                              isDark: isDark,
                              primary: primary,
                              prefixWidget: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: primary,
                                  size: 22,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Text(
                                        t('login_button'),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            // Divider + alt login options
                            ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? primary.withValues(alpha: 0.2)
                                          : const Color(0xFFDCE8DC),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      t('or_login_via'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF8BA68D)
                                            : const Color(0xFF6B8E6D),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? primary.withValues(alpha: 0.2)
                                          : const Color(0xFFDCE8DC),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF001600)
                                            : const Color(0xFFF4F8F4),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primary.withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_rounded,
                                            color: primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            t('university_cloud'),
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _isLoading ? null : _signInWithGoogle,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF001600)
                                              : const Color(0xFFF4F8F4),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: primary.withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_isLoading)
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: primary,
                                                ),
                                              )
                                            else ...[
                                              Icon(
                                                Icons.g_mobiledata,
                                                color: primary,
                                                size: 26,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                t('google'),
                                                style: TextStyle(
                                                  color: primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── University Footer ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'SMART STUDENT HELPER • UNIVERSITY PORTAL\n•  •  •',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark
                        ? const Color(0xFF4B6B4D)
                        : const Color(0xFF8BA68D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    Widget? prefixWidget,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    required Color primary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001600) : const Color(0xFFF4F8F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF0E3812) : const Color(0xFFDCE8DC),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF002800),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF527555) : const Color(0xFF8BA68D),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: prefixWidget,
          suffixIcon: suffixIcon != null
              ? Icon(
                  suffixIcon,
                  color: primary.withValues(alpha: 0.65),
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
