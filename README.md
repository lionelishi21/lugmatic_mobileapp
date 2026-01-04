Flutter App Task Sheet: Product Snapshot

Project Goal: To build a world-class music streaming and fan engagement app with a highly modern, fluid, and interactive user interface using Flutter.

Design Philosophy: Every interaction should be intuitive, delightful, and visually stunning. We will prioritize smooth animations, gesture-driven navigation, and a clean, bespoke design system.
Phase 0: Design & Prototyping (The Foundation)

Goal: Define the app's visual identity and user experience before writing a single line of code.

    [ ] UX/UI Research & Discovery

        [ ] Analyze top-tier apps (e.g., Apple Music, Spotify, TikTok, Twitch) for UI patterns and interaction models.

        [ ] Define the target user persona for the Jamaican market.

        [ ] Create user flow diagrams for key journeys (onboarding, first stream, sending a gift, joining a live session).

    [ ] Design System Creation (Figma/Sketch)

        [ ] Define color palette (light & dark modes).

        [ ] Establish typography scale and font choices (e.g., Inter, Satoshi).

        [ ] Design a core icon set (custom or a premium set).

        [ ] Create a component library (buttons, cards, inputs, navigation bars).

    [ ] High-Fidelity Mockups

        [ ] Design all primary screens based on the user flows.

        [ ] Pay special attention to the "Now Playing" and "Live Session" screens, as these are central to the interactive experience.

        [ ] Design the visual representation of gifts, badges, and ranks.

    [ ] Interaction Prototyping

        [ ] Create animated prototypes for key interactions (e.g., screen transitions, the gift-sending flow, audio player controls).

        [ ] Use a tool like Rive, Lottie, or Figma's Protopie integration to design complex animations for gift overlays.

Phase 1: Core Foundation (Flutter & Backend)

Goal: Set up the project architecture and build the essential, non-interactive parts of the app.
Backend Tasks

    [ ] Set up server, database (Postgres), and cache (Redis).

    [ ] Implement authentication service (Cognito/Auth0) with RBAC (listener, artist, admin).

    [ ] Build initial API endpoints for user registration, login, and profile management.

    [ ] Build API endpoints for basic catalog browsing (GET /tracks, /artists, /albums).

    [ ] Set up object storage (S3/GCS) and a basic media ingestion pipeline (upload -> store).

Flutter Tasks

    [ ] Project Setup

        [ ] Initialize Flutter project with a scalable folder structure (e.g., feature-first).

        [ ] Set up state management solution (Riverpod is recommended for modern Flutter).

        [ ] Configure routing (GoRouter is recommended for deep linking).

        [ ] Implement the design system: theme data, text styles, and custom UI components.

    [ ] Authentication Screens

        [ ] Build Welcome, Login, and Registration screens.

        [ ] Integrate with the authentication API endpoints.

        [ ] Implement token storage and refresh logic securely.

    [ ] Core UI Shell

        [ ] Build the main navigation structure (e.g., Bottom Navigation Bar).

        [ ] Create placeholder screens for Home, Search, Library, etc.

    [ ] Home & Browse

        [ ] Build the Home screen UI.

        [ ] Fetch and display catalog data from the backend (new releases, trending, etc.).

        [ ] Implement basic Artist and Album detail screens (read-only).

        [ ] Implement Search UI and connect to search API.

    [ ] Music Playback (Foundation)

        [ ] Integrate an audio player package (just_audio recommended for advanced features).

        [ ] Implement basic playback controls (play, pause, next, previous).

        [ ] Set up background audio playback and notification controls.

Phase 2: Gifting & The Core Loop

Goal: Bring the "killer twist" to life with a seamless and exciting gifting experience.
Backend Tasks

    [ ] Model and implement database schemas for GiftType, GiftEvent, Wallet, Leaderboard.

    [ ] Build API endpoints for fetching the gift catalog.

    [ ] Implement WebSocket server for real-time event broadcasting (e.g., when a gift is sent).

    [ ] Build secure API endpoints for sending gifts (this will debit the user's wallet).

    [ ] Develop logic for calculating rankPoints and updating leaderboards.

Flutter Tasks

    [ ] Wallet & Coin Purchase

        [ ] Build the "Wallet" screen UI.

        [ ] Integrate In-App Purchase packages (in_app_purchase).

        [ ] Implement flows for buying coin packs (iOS/Android) and validating receipts with the backend.

    [ ] "Now Playing" Screen - Interactive Overhaul

        [ ] Rebuild the player controls with custom, fluid animations.

        [ ] Implement a custom animated waveform scrubber.

        [ ] Design and build the Gift Bottom Sheet with a beautiful grid of available gifts.

        [ ] Implement the Send Gift flow, providing immediate visual feedback.

        [ ] Use an OverlayPortal to display stunning, non-blocking Gift Animations on top of the UI when a gift is received.

        [ ] Connect to the WebSocket to listen for and display gifts from other users in real-time.

    [ ] Leaderboards

        [ ] Build the UI for displaying Top Gifter leaderboards (Global and Per-Artist).

        [ ] Implement tabs or filters for weekly/monthly/all-time views.

    [ ] User Ranks & Perks

        [ ] Display user badges and ranks on their profile.

        [ ] Implement UI indicators for perks (e.g., highlighted comments, VIP chat access).

Phase 3 & 4: Artist Tools & Live Sessions

Goal: Empower artists with tools to manage their content and engage with fans in real-time.
Backend Tasks

    [ ] Build full artist-facing catalog management APIs (upload, transcode, metadata, splits).

    [ ] Set up live streaming service (AWS IVS / Mux).

    [ ] Generate RTMP ingest keys for artists.

    [ ] Add live-specific events to the WebSocket (chat messages, live gifts, pinned comments).

Flutter Tasks

    [ ] Live Session UI

        [ ] Integrate the live video player SDK.

        [ ] Build the live session interface: video view, chat overlay, and a streamlined gift tray.

        [ ] Connect to the WebSocket for real-time chat and gift events.

        [ ] Animate new chat messages and gift notifications smoothly.

        [ ] Display pinned comments prominently.

    [ ] Artist "Mobile-Lite" Dashboard

        [ ] Build a simple, view-only dashboard in the Flutter app for artists to check their earnings and analytics on the go.

        [ ] Add a feature for artists to schedule and "Go Live" directly from the app.

Phase 5 & 6: Subscriptions & Polish

Goal: Add recurring revenue streams and polish the app to perfection.
Backend Tasks

    [ ] Implement subscription plan logic and IAP receipt validation for recurring payments.

    [ ] Build endpoints to manage subscription status.

    [ ] Implement DRM license proxy for offline downloads.

    [ ] Finalize the full transcoding pipeline (audio normalization, multiple bitrates).

Flutter Tasks

    [ ] Subscription Flow

        [ ] Build UI for showcasing subscription plans (Free, Fan, SuperFan).

        [ ] Integrate IAP for handling subscriptions.

        [ ] Implement logic to unlock features based on the user's subscription tier.

    [ ] Offline Mode & DRM

        [ ] Integrate native DRM APIs (via platform channels or packages).

        [ ] Build UI for managing downloads.

        [ ] Implement the offline playback experience.

    [ ] Timed Lyrics

        [ ] Build the karaoke-style synced lyrics UI on the "Now Playing" screen.

        [ ] Fetch and parse LRC files.

    [ ] Final Polish

        [ ] Add subtle haptic feedback to key interactions.

        [ ] Conduct a full

## Folder Structure

```text
lib/
├── main.dart                 # Entry point (like index.js in React)
│
├── core/                     # App-wide constants, helpers, themes
│   ├── constants.dart
│   ├── theme.dart
│   └── utils.dart
│
├── data/                     # Data layer (like services + repositories)
│   ├── models/               # Data models (Song, Album, Playlist, User)
│   ├── services/             # API calls, Firebase, local storage, etc.
│   └── repositories/         # Wraps services, central data access
│
├── redux/                    # Redux-style state management
│   ├── actions/              # Actions (like Redux actions)
│   │   ├── player_actions.dart
│   │   ├── auth_actions.dart
│   │   └── playlist_actions.dart
│   ├── reducers/             # Reducers (like Redux reducers)
│   │   ├── app_reducer.dart
│   │   ├── player_reducer.dart
│   │   └── auth_reducer.dart
│   ├── middleware/           # Middleware for async stuff (network calls)
│   │   ├── player_middleware.dart
│   │   └── auth_middleware.dart
│   └── app_state.dart        # Root AppState (like Redux store shape)
│
├── ui/                       # Views (like React components)
│   ├── screens/              # Big pages (Home, Player, Search, Profile)
│   │   ├── home_screen.dart
│   │   ├── player_screen.dart
│   │   ├── search_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/              # Reusable widgets (buttons, cards, etc.)
│   │   ├── song_tile.dart
│   │   ├── album_card.dart
│   │   └── playback_controls.dart
│   └── dialogs/              # Popups, modals
│
├── navigation/               # App routing
│   └── app_router.dart
│
└── store.dart                # Redux Store setup (like configureStore.js)
```