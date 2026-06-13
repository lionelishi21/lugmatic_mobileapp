## Why
Independent artists struggle to grow their fanbase because running external marketing campaigns (Google Ads, Meta Ads) is too complex and time-consuming. Since Lugmatic Music is the "Airbnb of Music", it should provide a built-in marketing engine that empowers artists to run automated ad campaigns directly from the platform to promote their music globally or locally.

## What Changes
- Adds a new "Promote" module in the unified Artist Studio (accessible seamlessly across both the Web and Mobile App via the `lugmatic_flutter` codebase).
- Integrates Google Ads API in the Node.js backend to provision and manage automated campaigns.
- Allows artists to select a song, album, or profile, set a budget (via Stripe or Lugmatic Coins), and choose target demographics/regions.
- Automatically generates ad assets using the song's cover art and a 15-second audio snippet.
- Adds an Analytics Dashboard to track ad spend, reach, and conversion to new streams/followers on Lugmatic.

## Impact
- Affected specs: artist-promotions
- Affected code: `AdminService.ts`, `AiService.ts`, Stripe integrations, and a new Flutter UI module (`PromoteTab`).
