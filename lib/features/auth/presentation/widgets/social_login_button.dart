import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Social login button matching lugmatic-music web style:
/// dark input-filled surface, white/muted text, subtle border.
class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const SocialLoginButton({
    Key? key,
    required this.text,
    required this.iconPath,
    required this.onPressed,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.input,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 20,
              height: 20,
              errorBuilder: (ctx, err, st) {
                IconData icon = Icons.login;
                if (text.toLowerCase().contains('google')) {
                  icon = Icons.g_mobiledata_rounded;
                } else if (text.toLowerCase().contains('apple')) {
                  icon = Icons.apple_rounded;
                }
                return Icon(icon,
                    color: AppColors.foreground, size: 20);
              },
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
