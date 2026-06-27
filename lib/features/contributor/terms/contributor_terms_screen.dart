import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/contributor_provider.dart';

class ContributorTermsScreen extends StatefulWidget {
  const ContributorTermsScreen({super.key});

  @override
  State<ContributorTermsScreen> createState() => _ContributorTermsScreenState();
}

class _ContributorTermsScreenState extends State<ContributorTermsScreen> {
  bool _isSubmitting = false;

  Future<void> _acceptTerms() async {
    setState(() => _isSubmitting = true);
    try {
      final provider = context.read<ContributorProvider>();
      final success = await provider.acceptContributorTerms('1.0');
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contributor agreement accepted successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to accept agreement'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contributor Agreement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<ContributorProvider>(
        builder: (context, provider, _) {
          final accepted = provider.stats?['acceptedTerms'] == true;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(accepted),
                const SizedBox(height: 24),
                const Text(
                  'AGREEMENT TERMS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Lugmatic Music Contributor Agreement',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Version 1.0 - Effective May 2026',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'This Contributor Agreement ("Agreement") governs the terms under which you contribute content, songwriting, mastering, production, or other musical works (collectively, "Contributions") to collaborative tracks distributed on the Lugmatic Music platform.',
                            style: TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '1. Ownership and Splits',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'By contributing to a track, you agree to the split percentages registered on the split sheets. These percentages dictate the distribution of coins and dynamic earnings generated from stream play counts and gifts.',
                            style: TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '2. Licensing of Contributions',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You grant Lugmatic Music a non-exclusive, worldwide, royalty-free license to host, stream, distribute, modify (for transcoding/mastering), and promote your Contributions on the platform.',
                            style: TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '3. Revenue Share & Coin Conversions',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Revenue generated from play counts and virtual gifts will be credited to your balance in the form of Lugmatic Coins. Payouts can be requested once your balance exceeds the threshold limits set in the platform.',
                            style: TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '4. Warranties',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You warrant that your Contributions are original works, that you possess all necessary copyrights, and that they do not infringe upon any third-party intellectual property or copyright standards.',
                            style: TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!accepted) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _acceptTerms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'ACCEPT AGREEMENT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(bool accepted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: accepted ? AppColors.primary.withValues(alpha: 0.08) : AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accepted ? AppColors.primary.withValues(alpha: 0.3) : AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            accepted ? Icons.verified_user : Icons.gavel_rounded,
            color: accepted ? AppColors.primary : AppColors.secondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepted ? 'Agreement Signed' : 'Signature Required',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  accepted
                      ? 'You are active and authorized to receive split earnings.'
                      : 'Please read and accept the terms to unlock split earnings.',
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
