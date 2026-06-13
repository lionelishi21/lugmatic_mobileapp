# clash-recording Specification

## Purpose
Specifies video recording guidelines, durations, and constraints for user and artist clashes.

## ADDED Requirements
### Requirement: 60-Second Video Limit
The system SHALL lock clash video recordings to 60 seconds.

#### Scenario: Launch record clash video
- **WHEN** user initiates recording in clash mode
- **THEN** camera limits the recording duration to 60 seconds, and shows labels/HUD matching this constraint
