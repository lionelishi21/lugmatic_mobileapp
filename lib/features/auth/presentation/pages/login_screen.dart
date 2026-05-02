import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../utils/auth_validator.dart';
import '../widgets/social_login_button.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../../ui/widgets/custom_preloader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Login failed'),
        backgroundColor: AppColors.destructive,
      ));
      auth.clearError();
    }
  }

  Future<void> _signInWithGoogle() async {
    // TODO: Fix GoogleSignIn constructor issue
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Google sign-in is temporarily disabled in this build.'),
      backgroundColor: AppColors.secondary,
    ));
    /*
    final authProvider = context.read<AuthProvider>();
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google sign-in failed: no ID token'),
          backgroundColor: AppColors.destructive,
        ));
        return;
      }

      final ok = await authProvider.loginWithGoogle(idToken: idToken);
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
          backgroundColor: AppColors.destructive,
        ));
        authProvider.clearError();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Google sign-in failed: ${e.toString()}'),
        backgroundColor: AppColors.destructive,
      ));
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: BoxDecoration(gradient: AppColors.screenGradient),
          ),

          // ── Purple radial glows (mirrors web auth page) ──────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppColors.secondary.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondary.withOpacity(0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondaryDim.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back chevron
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surface10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.border, width: 1),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.foreground,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Glass card ────────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.glassBg,
                                  borderRadius:
                                      BorderRadius.circular(40),
                                  border: Border.all(
                                      color: AppColors.border,
                                      width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.4),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Logo
                                    Center(
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Image.asset(
                                          'assets/images/app_logo_transparent.png',
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (ctx, e, st) => Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: AppColors.muted,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      16),
                                            ),
                                            child: const Icon(
                                              Icons.music_note_rounded,
                                              color: AppColors.primary,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Title — Bebas Neue display font style
                                    const Text(
                                      'Welcome Back',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.foreground,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Log in to your account to continue',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Email
                                    _buildLabel('Email Address'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      validator:
                                          AuthValidator.validateEmail,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      style: const TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 15),
                                      decoration: _fieldDecoration(
                                        hint: 'name@example.com',
                                        prefixIcon:
                                            Icons.mail_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Password header row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildLabel('Password'),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ForgotPasswordScreen())),
                                          child: const Text(
                                            AppStrings.forgotPassword,
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      validator:
                                          AuthValidator.validatePassword,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 15),
                                      decoration: _fieldDecoration(
                                        hint: '••••••••',
                                        prefixIcon:
                                            Icons.lock_outline_rounded,
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons
                                                    .visibility_outlined,
                                            color:
                                                AppColors.mutedForeground,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Login button
                                    _PrimaryButton(
                                      onTap: auth.isLoading ? null : _signIn,
                                      loading: auth.isLoading,
                                      label: 'Log In',
                                    ),
                                    const SizedBox(height: 28),

                                    // Divider
                                    _buildDivider(),
                                    const SizedBox(height: 20),

                                    // Social
                                    SocialLoginButton(
                                      text: AppStrings.googleSignIn,
                                      iconPath:
                                          'assets/images/google_icon.png',
                                      onPressed: auth.isLoading
                                          ? null
                                          : _signInWithGoogle,
                                    ),
                                    const SizedBox(height: 10),
                                    SocialLoginButton(
                                      text: AppStrings.appleSignIn,
                                      iconPath:
                                          'assets/images/apple_icon.png',
                                      onPressed: () =>
                                          _showComingSoon('Apple'),
                                    ),

                                    const SizedBox(height: 28),
                                    const Divider(
                                        color: AppColors.border,
                                        height: 1),
                                    const SizedBox(height: 20),

                                    // Sign up link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          AppStrings.dontHaveAccount,
                                          style: TextStyle(
                                              color:
                                                  AppColors.mutedForeground,
                                              fontSize: 13),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SignUpScreen())),
                                          child: const Text(
                                            ' Sign up for free',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (auth.isLoading)
            const CustomPreloader(text: 'Tuning in...'),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.foreground,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: AppColors.mutedForeground, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.mutedForeground, size: 18)
          : null,
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffixIcon)
          : null,
      filled: true,
      fillColor: AppColors.input,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: AppColors.destructive, width: 1.5),
      ),
    );
  }

  void _showComingSoon(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$platform login is coming soon!'),
      backgroundColor: AppColors.secondary,
    ));
  }

  Widget _buildDivider() => Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColors.border.withOpacity(0.5),
                  height: 1)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              AppStrings.orContinueWith,
              style: TextStyle(
                  color: AppColors.mutedForeground, fontSize: 11),
            ),
          ),
          Expanded(
              child: Divider(
                  color: AppColors.border.withOpacity(0.5),
                  height: 1)),
        ],
      );

}

// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton(
      {required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.background,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.background, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}
