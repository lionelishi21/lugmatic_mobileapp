import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ArtistAccountScreen extends StatelessWidget {
  const ArtistAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'Account',
          style: TextStyle(color: AppColors.foreground, fontSize: 18),
        ),
      ),
    );
  }
}
