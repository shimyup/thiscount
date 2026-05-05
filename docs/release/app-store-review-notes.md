# App Store Review Notes (Draft)

Use the text below in **App Review Information > Notes**.

## 1) App Overview
Letter Go is a social letter app where users send letters globally and view delivery journeys on the map.

## 2) Login / Account for Review
- No pre-created account is required.
- Reviewer can create a new account directly in-app.
- Sign-up uses email + username + password.
- OTP flow is currently in-app for review/dev build path:
  - The verification code is displayed on the OTP screen for test convenience.
  - External mailbox access is not required for reviewer testing.

## 3) How to Reach Subscription Screen
- Path A: `Profile` tab -> `구독 플랜`
- Path B: `Settings` -> `구독` -> premium screen
- In some first-run cases, premium welcome can also appear after the first successful letter send.

## 4) In-App Purchases to Test (iOS, Bundle ID `io.thiscount`)
- Premium Monthly: `thiscount_premium_monthly_ios` (Auto-Renewable)
- Brand Monthly: `thiscount_brand_monthly_ios` (Auto-Renewable)
- Gift 1 Month: `thiscount_gift_1month_ios` (Non-Consumable)
- Brand Extra 1000: `thiscount_brand_extra_1000_ios` (Consumable)

Expected behavior:
- Premium/Brand purchase opens native Apple purchase sheet.
- Restore purchase may show Apple ID sign-in prompt (expected iOS behavior).
- Gift purchase shows success dialog and generated gift code after successful purchase.

## 5) Permissions
- Location permission is optional for account creation.
- Notifications permission is optional and used for nearby letter / arrival alerts.
- Photos permission is requested only when user attaches an image to a letter/profile.

## 6) Additional Technical Notes
- The app uses RevenueCat for subscription handling.
- If product metadata fails to load due to transient store/network conditions, the app shows a retry message instead of crashing.

## 7) Contact for Review Team
- Support: `ceo@airony.xyz`
