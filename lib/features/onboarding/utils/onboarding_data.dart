import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../data/models/onboarding_item.dart';

class OnboardingData {
  static List<OnboardingItem> get items => [
    OnboardingItem(
      eyebrow: AppStrings.streamMusicEyebrow,
      title: AppStrings.streamMusicTitle,
      description: AppStrings.streamMusicDescription,
      icon: Icons.music_note_rounded,
    ),
    OnboardingItem(
      eyebrow: AppStrings.viewArtistsEyebrow,
      title: AppStrings.viewArtistsTitle,
      description: AppStrings.viewArtistsDescription,
      icon: Icons.live_tv_rounded,
    ),
    OnboardingItem(
      eyebrow: AppStrings.giftArtistsEyebrow,
      title: AppStrings.giftArtistsTitle,
      description: AppStrings.giftArtistsDescription,
      icon: Icons.card_giftcard_rounded,
    ),
  ];
}