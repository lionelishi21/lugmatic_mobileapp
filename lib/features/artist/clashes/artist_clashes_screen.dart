import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ArtistClashesScreen extends StatelessWidget {
  const ArtistClashesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'Clashes',
          style: TextStyle(color: AppColors.foreground, fontSize: 18),
        ),
      ),
    );
  }
}
