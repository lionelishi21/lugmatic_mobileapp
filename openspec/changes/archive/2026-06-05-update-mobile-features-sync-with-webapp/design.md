## Context
The Lugmatic music streaming platform relies on a synchronized feature set across the Next.js web application and the Flutter mobile application. Recent updates to the webapp need to be backported to the mobile codebase.

## Goals
- Clear stale data caches (specifically artist dashboard and track providers) when switching user roles.
- Synchronize Mixer options (tempo speed control, audio FX sliders, visualizer aesthetics) with the webapp's new Dub Soundclash Synthesizer design.
- Create a beautiful green-to-black gradient music note SVG-equivalent fallback widget for missing images.
- Rectify outdated "6-sec" labels in clash UI to state "60-sec" to reflect the actual recording duration limit.

## Decisions
- **State Cleansing**: Implement `clear()` methods inside `TrackProvider` and `DashboardProvider` which set data fields back to initial/null values and invoke `notifyListeners()`. These will be called in `RoleSwitcherButton`, `ArtistDashboardScreen`, and `ContributorDashboardScreen` when a role switch is triggered.
- **Mixer Player Speed**: Map the selected tempo option to standard speed ratios:
  - Slow: `0.85`
  - Normal: `1.0`
  - Fast: `1.1`
  - Turbo: `1.2`
  These values will directly set `_player.setSpeed(ratio)`.
- **Audio FX UI**: Implement sliders for Bass Boost and Echo. Because complex Web Audio API DSP nodes are platform-dependent in Flutter (requiring native platform channels or Android-only API wrappers), we will build the sliders in the UI and use their values to animate visual elements (like visualizer bar scaling and glowing colors) to give user-feedback, while speed and volume remain fully dynamic.
- **Brand-Gradient note fallback**: Build a `BrandGradientFallback` stateless widget containing a `Container` with a `LinearGradient` of colors `[Color(0xFF4A8E27), Color(0xFF0A0B0A)]` at 150 degrees, displaying a custom SVG music note centered.
- **Clash recording limit label**: Update the outdated label `Record 6-sec clip` in `ArtistClashesScreen` to `Record 60-sec clip`.

## Risks / Trade-offs
- *Risk*: Flutter secure storage tokens could be cleared if we invoke a generic `clear()`.
- *Mitigation*: We are only clearing the application-level data providers (`TrackProvider` and `DashboardProvider`), leaving token storage completely untouched.
