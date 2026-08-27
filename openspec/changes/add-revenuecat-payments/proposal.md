## Why
We need to migrate all native payment features (Stripe/PayPal) for subscriptions and coin purchases to RevenueCat to simplify cross-platform payment handling, ensure compliance with App Store / Google Play guidelines, and centralize receipt validation.

## What Changes
- Replace native Stripe/PayPal payment intent logic with RevenueCat SDK calls.
- Integrate `purchases_flutter` for subscriptions and consumable coin purchases.
- Update `SubscriptionService` to fetch offerings from RevenueCat.
- Update `GiftService` to make consumable purchases through RevenueCat.

## Impact
- Affected specs: `gifting`, `subscriptions`
- Affected code: `SubscriptionService`, `GiftService`, and potentially UI screens triggering purchases.
