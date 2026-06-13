# Project Context

## Purpose
Lugmatic Music is the "Airbnb of Music", a platform designed to connect independent artists directly with their fans and empower them with built-in tools for growth, monetization, and engagement. Our goal is to make artists fully independent while giving fans an interactive and rewarding music experience.

## Tech Stack
- Frontend: Flutter (Mobile App - iOS/Android), React (Web)
- Backend: Node.js, Express, TypeScript
- Database & Auth: Firebase / Cloud Firestore
- Ad Integration: Google Ads API, Stripe (for payments)

## Project Conventions

### Code Style
- Dart: Follow standard Flutter lint rules.
- Node.js/TS: ESLint and Prettier.

### Architecture Patterns
- Flutter: Provider for state management, clean architecture principles.
- Backend: Service-oriented architecture with modular routes and controllers.

### Testing Strategy
- Unit tests for core business logic and critical services.
- Widget tests for primary UI components in Flutter.

### Git Workflow
- Feature branching strategy (e.g., `feature/artist-promotions`).
- Pull requests required for merging into `main`.

## Domain Context
- **Artists:** Creators who upload music, receive gifts (coins), and promote their tracks.
- **Fans:** Consumers who listen to music, buy coins, and send gifts to artists during clashes or on tracks.
- **Coins/Gifts:** The internal virtual currency used for tipping artists.
- **Artist Promotions:** A built-in marketing engine that allows artists to spend their budget to run automated ad campaigns (e.g., Google Ads) directly from the Lugmatic platform.

## Important Constraints
- Coin purchases are handled externally or via web to comply with App Store guidelines, but internal spending (gifting, promoting) can be done within the app using the coin balance.

## External Dependencies
- Firebase (Auth, Firestore, Crashlytics, Storage)
- Google Ads API (for the Artist Promotions module)
- Stripe API (for direct top-ups or campaign payments)
