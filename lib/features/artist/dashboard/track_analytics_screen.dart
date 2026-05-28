import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TrackAnalyticsScreen extends StatelessWidget {
  final dynamic track;
  const TrackAnalyticsScreen({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(track?.name ?? 'Analytics', style: const TextStyle(color: AppColors.foreground)),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      body: const Center(
        child: Text('Track analytics — coming soon', style: TextStyle(color: AppColors.mutedForeground)),
      ),
    );
  }
}
