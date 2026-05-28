import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ArtistMessagesScreen extends StatelessWidget {
  const ArtistMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'Messages',
          style: TextStyle(color: AppColors.foreground, fontSize: 18),
        ),
      ),
    );
  }
}
