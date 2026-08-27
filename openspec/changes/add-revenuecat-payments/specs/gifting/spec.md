## MODIFIED Requirements
### Requirement: Send Gifts
The system SHALL allow users to send virtual gifts to artists using their coin balance.

#### Scenario: Send gift successfully
- **WHEN** user selects a gift and has sufficient coins
- **THEN** coins are deducted and gift is sent to the artist

#### Scenario: Insufficient coins
- **WHEN** user selects a gift but has insufficient coins
- **THEN** system prompts user to visit the store to buy more coins via in-app purchases (RevenueCat)

## ADDED Requirements
### Requirement: Purchase Coins
The system SHALL allow users to purchase consumable coins using native in-app purchases.

#### Scenario: Purchase coins
- **WHEN** user initiates a coin purchase
- **THEN** the purchase is processed via RevenueCat and the coin balance is updated
