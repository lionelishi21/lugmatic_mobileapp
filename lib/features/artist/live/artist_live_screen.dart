import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ArtistLiveScreen extends StatelessWidget {
  const ArtistLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'Go Live',
          style: TextStyle(color: AppColors.foreground, fontSize: 18),
        ),
      ),
    );
  }
}
