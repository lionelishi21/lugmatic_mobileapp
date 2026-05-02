import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../../data/providers/auth_provider.dart';
import 'email_verification_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../utils/auth_validator.dart';
import '../widgets/social_login_button.dart';
import '../../../../ui/widgets/custom_preloader.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                    email: _emailCtrl.text.trim(),
                  )),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.destructive,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(gradient: AppColors.screenGradient),
          ),
          // Purple glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.1,
                  colors: [
                    AppColors.secondary.withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondaryDim.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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

                        // Glass card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.glassBg,
                                borderRadius:
                                    BorderRadius.circular(40),
                                border: Border.all(
                                    color: AppColors.border, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
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
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      height: 60,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, e, st) =>
                                          Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.muted,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  const Text(
                                    AppStrings.createAccount,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    AppStrings.signupSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Name row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildField(
                                          label: 'First Name',
                                          hint: 'First name',
                                          controller: _firstNameCtrl,
                                          validator:
                                              AuthValidator.validateName,
                                          icon:
                                              Icons.person_outline_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildField(
                                          label: 'Last Name',
                                          hint: 'Last name',
                                          controller: _lastNameCtrl,
                                          validator:
                                              AuthValidator.validateName,
                                          icon:
                                              Icons.person_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  _buildField(
                                    label: 'Email Address',
                                    hint: 'name@example.com',
                                    controller: _emailCtrl,
                                    validator:
                                        AuthValidator.validateEmail,
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildField(
                                    label: AppStrings.password,
                                    hint: '••••••••',
                                    controller: _passwordCtrl,
                                    validator:
                                        AuthValidator.validatePassword,
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePassword,
                                    onToggleObscure: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                  const SizedBox(height: 16),

                                  _buildField(
                                    label: AppStrings.confirmPassword,
                                    hint: '••••••••',
                                    controller: _confirmCtrl,
                                    validator: (val) =>
                                        AuthValidator
                                            .validateConfirmPassword(
                                                val, _passwordCtrl.text),
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscureConfirm,
                                    onToggleObscure: () => setState(() =>
                                        _obscureConfirm =
                                            !_obscureConfirm),
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign up button
                                  GestureDetector(
                                    onTap: _isLoading ? null : _signUp,
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.35),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color:
                                                      AppColors.background,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                children: const [
                                                  Text(
                                                    AppStrings.signUp,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .background,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons
                                                        .arrow_forward_rounded,
                                                    color: AppColors
                                                        .background,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Divider
                                  _buildDivider(),
                                  const SizedBox(height: 20),

                                  SocialLoginButton(
                                    text: AppStrings.googleSignIn,
                                    iconPath:
                                        'assets/images/google_icon.png',
                                    onPressed: () =>
                                        _showComingSoon('Google'),
                                  ),
                                  const SizedBox(height: 10),
                                  SocialLoginButton(
                                    text: AppStrings.appleSignIn,
                                    iconPath:
                                        'assets/images/apple_icon.png',
                                    onPressed: () =>
                                        _showComingSoon('Apple'),
                                  ),

                                  const SizedBox(height: 24),
                                  const Divider(
                                      color: AppColors.border, height: 1),
                                  const SizedBox(height: 20),

                                  // Sign in link
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        AppStrings.alreadyHaveAccount,
                                        style: TextStyle(
                                            color:
                                                AppColors.mutedForeground,
                                            fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            Navigator.pop(context),
                                        child: const Text(
                                          ' Sign in here',
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
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const CustomPreloader(text: 'Setting the stage...'),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    IconData? icon,
    TextInputType? keyboardType,
    bool? obscure,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscure ?? false,
          style: const TextStyle(
              color: AppColors.foreground, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.mutedForeground, fontSize: 13),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.mutedForeground, size: 17)
                : null,
            suffixIcon: onToggleObscure != null
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(
                        (obscure ?? false)
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.mutedForeground,
                        size: 17,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.input,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.destructive)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.destructive, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColors.border.withOpacity(0.5), height: 1)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(AppStrings.orContinueWith,
                style: TextStyle(
                    color: AppColors.mutedForeground, fontSize: 11)),
          ),
          Expanded(
              child: Divider(
                  color: AppColors.border.withOpacity(0.5), height: 1)),
        ],
      );

  void _showComingSoon(String provider) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$provider sign-up coming soon')));
}
