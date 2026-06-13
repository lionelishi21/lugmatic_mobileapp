# role-switching Specification

## Purpose
Specifies role-switching behaviors and cache/state management to ensure fresh, secure data is loaded upon switching views.

## ADDED Requirements
### Requirement: Clear State on Role Switch
The system SHALL clear the cached dashboard analytics and track catalogs when switching roles between Fan, Artist, or Contributor.

#### Scenario: Swapping from Artist to Fan Mode
- **WHEN** the user switches role from Artist to Fan
- **THEN** the DashboardProvider and TrackProvider states are cleared, preventing data from leaking into other sessions.
