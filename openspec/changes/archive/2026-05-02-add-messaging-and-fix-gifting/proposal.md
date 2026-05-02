## Why
Fans are currently unable to message artists from the mobile app, and gifting is broken due to incorrect coin cost calculations. Messaging is a core engagement feature already present on the web platform but missing in mobile.

## What Changes
- **MODIFIED**: `GiftModel` to correctly calculate and display coin costs.
- **ADDED**: `Messaging` capability including:
    - Conversation and Message data models.
    - `MessageService` for API interaction.
    - `MessageProvider` for state management.
    - `MessagesPage` for listing conversations.
    - `ChatPage` for 1-on-1 messaging with artists.
    - Integration into `ArtistDetailPage` and global routing.
- **REMOVED**: Premium feature block for messaging on artist profiles to match web behavior.

## Impact
- Affected specs: `gifting`, `messaging`
- Affected code: `ArtistDetailPage`, `AppRouter`, `GiftModel`
