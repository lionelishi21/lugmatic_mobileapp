import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ArtistTracksScreen extends StatelessWidget {
  const ArtistTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'Tracks',
          style: TextStyle(color: AppColors.foreground, fontSize: 18),
        ),
      ),
    );
  }
}
