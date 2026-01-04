import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_assets.dart';
import '../data/models/onboarding_item.dart';

class OnboardingData {
  static List<OnboardingItem> get items => [
    OnboardingItem(
      title: AppStrings.streamMusicTitle,
      description: AppStrings.streamMusicDescription,
      backgroundImage: AppAssets.musicBackground1,
      icon: Icons.music_note,
    ),
    OnboardingItem(
      title: AppStrings.viewArtistsTitle,
      description: AppStrings.viewArtistsDescription,
      backgroundImage: AppAssets.musicBackground2,
      icon: Icons.live_tv,
    ),
    OnboardingItem(
      title: AppStrings.giftArtistsTitle,
      description: AppStrings.giftArtistsDescription,
      backgroundImage: AppAssets.musicBackground3,
      icon: Icons.card_giftcard,
    ),
  ];
}