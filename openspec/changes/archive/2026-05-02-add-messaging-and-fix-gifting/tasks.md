## 1. Gifting Fixes
- [ ] 1.1 Fix `GiftModel` coin cost calculation in `lib/data/models/gift_model.dart`.
- [ ] 1.2 Verify `GiftBottomSheet` displays correct costs.

## 2. Messaging Infrastructure
- [ ] 2.1 Create `lib/data/models/conversation_model.dart`.
- [ ] 2.2 Create `lib/data/models/message_model.dart`.
- [ ] 2.3 Create `lib/data/services/message_service.dart` with endpoints for listing, starting, and sending messages.
- [ ] 2.4 Create `lib/data/providers/message_provider.dart` for state management and socket integration.

## 3. Messaging UI
- [ ] 3.1 Create `lib/features/messages/presentation/pages/messages_page.dart` (Conversations List).
- [ ] 3.2 Create `lib/features/messages/presentation/pages/chat_page.dart` (Chat Detail).
- [ ] 3.3 Add message icon/link to `HomePage` or Profile.

## 4. Integration
- [ ] 4.1 Register `MessageService` and `MessageProvider` in `main.dart`.
- [ ] 4.2 Update `AppRouter` with `/messages` and `/chat` routes.
- [ ] 4.3 Update `ArtistDetailPage` to navigate to `ChatPage` and remove premium check.
