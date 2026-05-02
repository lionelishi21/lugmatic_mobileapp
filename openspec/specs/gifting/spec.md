# gifting Specification

## Purpose
TBD - created by archiving change add-messaging-and-fix-gifting. Update Purpose after archive.
## Requirements
### Requirement: Send Gifts
The system SHALL allow users to send virtual gifts to artists using their coin balance.

#### Scenario: Send gift successfully
- **WHEN** user selects a gift and has sufficient coins
- **THEN** coins are deducted and gift is sent to the artist

#### Scenario: Insufficient coins
- **WHEN** user selects a gift but has insufficient coins
- **THEN** system prompts user to visit the store to buy more coins

### Requirement: Display Gift Costs
The system SHALL display the correct coin cost for each gift as defined by the backend.

#### Scenario: Correct cost display
- **WHEN** browsing the gift shop
- **THEN** each gift shows its absolute coin cost (e.g., "50 coins")

