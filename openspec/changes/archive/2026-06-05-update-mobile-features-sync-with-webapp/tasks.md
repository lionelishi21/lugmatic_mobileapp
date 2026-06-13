## 1. State Cleansing and Role Switcher
- [ ] 1.1 Add `clear()` method to `DashboardProvider` in `lib/data/providers/dashboard_provider.dart`
- [ ] 1.2 Add `clear()` method to `TrackProvider` in `lib/data/providers/track_provider.dart`
- [ ] 1.3 Clear dashboard and track providers when switching role modes in `lib/shared/widgets/role_switcher_button.dart`
- [ ] 1.4 Clear dashboard and track providers when switching to fan mode in `lib/features/artist/dashboard/artist_dashboard_screen.dart`
- [ ] 1.5 Clear dashboard and track providers when switching to fan mode in `lib/features/contributor/dashboard/contributor_dashboard_screen.dart`

## 2. Mixer Enhancements
- [ ] 2.1 Update `MixerPage` tempo options selection to adjust `_player.setSpeed(ratio)` in `lib/features/mixer/presentation/pages/mixer_page.dart`
- [ ] 2.2 Add interactive sliders for Bass Boost and Echo in `lib/features/mixer/presentation/pages/mixer_page.dart`
- [ ] 2.3 Add beat-reactive visualizer glow, LIVE badge, and visualizer bar scaling to DJ stage in `lib/features/mixer/presentation/pages/mixer_page.dart`

## 3. Brand-Gradient Note Fallback
- [ ] 3.1 Create reusable `BrandGradientFallback` widget in `lib/shared/widgets/brand_gradient_fallback.dart`
- [ ] 3.2 Update `ArtistDetailPage` in `lib/features/home/presentation/pages/artist_detail_page.dart` to use `BrandGradientFallback` when artist image is missing or empty
- [ ] 3.3 Update `HomePage` in `lib/features/home/presentation/pages/home_page.dart` to use `BrandGradientFallback` for artist image fallbacks

## 4. Clash limits update
- [ ] 4.1 Update text label in `ArtistClashesScreen` from "Record 6-sec clip" to "Record 60-sec clip" in `lib/features/artist/clashes/artist_clashes_screen.dart`
- [ ] 4.2 Fix stale code comments in `VideoRecordingPage` to state 60 seconds instead of 6 seconds in `lib/features/video/presentation/pages/video_recording_page.dart`
