import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'Dashboard',
          style: TextStyle(color: AppColors.foreground, fontSize: 18),
        ),
      ),
    );
  }
}
