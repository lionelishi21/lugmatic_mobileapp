import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Privacy Policy', 
            style: TextStyle(color: NeumorphicTheme.textPrimary, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: NeumorphicTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Last Updated: April 2026'),
              const SizedBox(height: 24),
              _buildContentText(
                'At Lugmatic, we take your privacy seriously. This Privacy Policy explains how we collect, use, and protect your personal information when you use our music streaming and live broadcasting services.',
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('1. Information We Collect'),
              _buildContentText(
                '• Account Information: Name, email, and artist profile details.\n'
                '• Usage Data: Songs you listen to, artists you follow, and live streams you join.\n'
                '• Financial Information: Payment processing is handled securely by Stripe; we do not store your full credit card details.',
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('2. How We Use Your Information'),
              _buildContentText(
                '• To provide and maintain our services.\n'
                '• To personalize your music discovery experience.\n'
                '• To notify you about live streams from your favorite artists (via FCM).\n'
                '• To process virtual gift transactions.',
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('3. Live Streaming & Recording'),
              _buildContentText(
                'Live streams on Lugmatic are public events. As an artist, your broadcasts are recorded for later viewing (VOD). By broadcasting, you consent to this recording and distribution within the platform.',
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('4. Data Security'),
              _buildContentText(
                'We use industry-standard encryption (HTTPS) to protect your data in transit. Your authentication tokens are stored securely on your device using encrypted storage.',
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('5. Your Rights'),
              _buildContentText(
                'You can request a copy of your data or ask for the deletion of your account at any time through the support section or by contacting us at support@lugmaticmusic.com.',
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  '© 2026 Lugmatic Music. All rights reserved.',
                  style: TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: NeumorphicTheme.primaryAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContentText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: NeumorphicTheme.textSecondary,
        fontSize: 15,
        height: 1.6,
      ),
    );
  }
}
