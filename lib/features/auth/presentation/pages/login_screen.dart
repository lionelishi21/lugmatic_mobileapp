import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../utils/auth_validator.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_login_button.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../ui/widgets/custom_preloader.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login successful!'),
          backgroundColor: NeumorphicTheme.primaryAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: NeumorphicTheme.backgroundColor,
      body: Stack(
        children: [
          // Neumorphic background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeumorphicTheme.backgroundColor,
                  NeumorphicTheme.surfaceColor,
                  NeumorphicTheme.backgroundColor,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      _buildLogo(),
                      const SizedBox(height: 32),
                      const AuthHeader(
                        title: AppStrings.welcomeBack,
                        subtitle: AppStrings.loginSubtitle,
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: NeumorphicContainer(
                          isConcave: true,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(16),
                          child: TextFormField(
                            controller: _emailController,
                            validator: AuthValidator.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: NeumorphicTheme.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: NeumorphicTheme.neumorphicInputDecoration(
                              label: AppStrings.email,
                              hint: "Enter your email",
                              prefixIcon: Icons.email_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: NeumorphicContainer(
                          isConcave: true,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(16),
                          child: TextFormField(
                            controller: _passwordController,
                            validator: AuthValidator.validatePassword,
                            obscureText: true,
                            style: const TextStyle(
                              color: NeumorphicTheme.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: NeumorphicTheme.neumorphicInputDecoration(
                              label: AppStrings.password,
                              hint: "Enter your password",
                              prefixIcon: Icons.lock_outline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(
                              color: NeumorphicTheme.primaryAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign In Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    NeumorphicTheme.accentGradientStart,
                                    NeumorphicTheme.accentGradientEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: NeumorphicTheme.accentGradientStart
                                        .withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: authProvider.isLoading ? null : _signIn,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Center(
                                    child: Text(
                                      AppStrings.signIn,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      const SizedBox(height: 28),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    NeumorphicTheme.textTertiary
                                        .withOpacity(0.25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              AppStrings.orContinueWith,
                              style: TextStyle(
                                color: NeumorphicTheme.textSecondary
                                    .withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    NeumorphicTheme.textTertiary
                                        .withOpacity(0.25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Social Login Buttons
                      SocialLoginButton(
                        text: AppStrings.googleSignIn,
                        iconPath: "assets/images/google_icon.png",
                        onPressed: _signInWithGoogle,
                      ),
                      const SizedBox(height: 16),
                      SocialLoginButton(
                        text: AppStrings.appleSignIn,
                        iconPath: "assets/images/apple_icon.png",
                        onPressed: _signInWithApple,
                      ),
                      const SizedBox(height: 32),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.dontHaveAccount,
                            style: TextStyle(
                              color: NeumorphicTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              AppStrings.signUpHere,
                              style: TextStyle(
                                color: NeumorphicTheme.primaryAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (authProvider.isLoading)
            const CustomPreloader(text: 'Tuning in...'),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeumorphicTheme.accentGradientStart,
              NeumorphicTheme.accentGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: NeumorphicTheme.accentGradientStart.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 70,
            height: 70,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.music_note_rounded,
                size: 56,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) return; // User cancelled

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get Google credentials')),
          );
        }
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginWithGoogle(idToken: idToken);

      if (mounted) {
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $e')),
        );
      }
    }
  }

  void _signInWithApple() {
    // TODO: Implement Apple Sign In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In coming soon')),
    );
  }
}
