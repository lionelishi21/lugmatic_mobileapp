## Why
The Lugmatic webapp has recently introduced several UI/UX and feature enhancements (TikTok-style role switcher, upgraded interactive AI Mixer, custom brand-gradient fallbacks for missing images, and a 60-second limit for video clash recording). To ensure feature parity and consistent user experience across platforms, the mobile Flutter application needs to sync these capabilities.

## What Changes
- **Role Switcher State Cleanses**: Implement clear/reset states in `TrackProvider` and `DashboardProvider`. Clear these providers when role switching is triggered.
- **AI Mixer Sync**: Integrate tempo selector options in mobile `MixerPage` linked to `AudioPlayer.setSpeed()`, implement sliders for Bass Boost and Echo, and add a beat-reactive visualizer glow with a "LIVE" badge to match the webapp's new visual design.
- **Brand-Gradient Note Fallback**: Create a reusable `BrandGradientFallback` widget in Flutter that matches the oklch/gradient styling of the webapp fallback, and apply it as the fallback/error builder for missing artist/album images.
- **60s Recording Limit Sync**: Statically set all user-facing descriptions/button text for clashes from "6-sec clip" to "60-sec clip" to match the actual 60-second limit in the recording view.

## Impact
- Affected specs: `role-switching` [NEW], `mixer-enhancements` [NEW], `brand-gradient` [NEW], `clash-recording` [NEW]
- Affected code:
  - `lib/data/providers/dashboard_provider.dart`
  - `lib/data/providers/track_provider.dart`
  - `lib/shared/widgets/role_switcher_button.dart`
  - `lib/features/artist/dashboard/artist_dashboard_screen.dart`
  - `lib/features/contributor/dashboard/contributor_dashboard_screen.dart`
  - `lib/features/mixer/presentation/pages/mixer_page.dart`
  - `lib/features/home/presentation/pages/artist_detail_page.dart`
  - `lib/features/home/presentation/pages/home_page.dart`
  - `lib/features/artist/clashes/artist_clashes_screen.dart`
  - `lib/features/video/presentation/pages/video_recording_page.dart`
