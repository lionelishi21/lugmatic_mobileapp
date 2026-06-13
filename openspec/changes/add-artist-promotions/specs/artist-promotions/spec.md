## ADDED Requirements
### Requirement: Automated Ad Campaigns
The system SHALL allow artists to create and manage automated promotional ad campaigns directly from the Artist Dashboard (accessible across both the Web and Mobile App).

#### Scenario: Launching a new promotion
- **WHEN** an artist selects a song, sets a budget, and chooses target regions
- **THEN** the system provisions a Google Ads campaign using the song's assets and deducts the budget from the artist's wallet or via Stripe

### Requirement: Promotional Analytics Tracking
The system SHALL track and display the performance metrics of active campaigns in real-time.

#### Scenario: Viewing campaign performance
- **WHEN** an artist visits the Promotion Analytics dashboard
- **THEN** the system displays total ad spend, impressions, click-through rates, and resulting Lugmatic streams/followers
