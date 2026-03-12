import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      await authService.verifyEmail(_codeController.text.trim());
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessAndGoBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessAndGoBack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully! You can now log in.'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    Navigator.pop(context); // Go back to Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: "Verify Email",
                subtitle: "We've sent a verification code to ${widget.email}. Please enter it below to continue.",
              ),
              const SizedBox(height: 48),
              CustomTextField(
                label: "Verification Code",
                hint: "Enter the code from your email",
                controller: _codeController,
                prefixIcon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 32),
              AuthButton(
                text: "Verify Now",
                onPressed: _verify,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text(
                    "Didn't receive code? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      // Optionally implement resend logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email resent!')),
                      );
                    },
                    child: const Text(
                      "Resend",
                      style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
