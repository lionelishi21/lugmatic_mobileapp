import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MessageThreadScreen extends StatelessWidget {
  final String conversationId;
  final String otherName;

  const MessageThreadScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(otherName),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Message thread — coming soon',
            style: TextStyle(color: AppColors.mutedForeground)),
      ),
    );
  }
}
