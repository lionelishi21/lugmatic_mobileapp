## ADDED Requirements

### Requirement: Direct Messaging
The system SHALL allow users to initiate and engage in 1-on-1 messaging with artists.

#### Scenario: Start conversation from artist profile
- **WHEN** user taps "Message" on an artist profile
- **THEN** system opens a chat session with that artist

#### Scenario: Real-time message delivery
- **WHEN** a message is sent or received
- **THEN** it is displayed instantly in the chat interface without a manual refresh

### Requirement: Conversation Management
The system SHALL allow users to view and manage their existing conversations.

#### Scenario: View conversation list
- **WHEN** user navigates to the messages section
- **THEN** system displays a list of all active conversations with the latest message and unread indicators
