## ADDED Requirements
### Requirement: Subscribe to Plans
The system SHALL allow users to subscribe to premium plans via native in-app purchases.

#### Scenario: Fetch available plans
- **WHEN** user visits the subscription screen
- **THEN** the system fetches active offerings from RevenueCat

#### Scenario: Purchase subscription
- **WHEN** user selects a plan and completes the purchase
- **THEN** the subscription is processed via RevenueCat and premium features are unlocked
