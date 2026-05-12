# App Store Review Notes (Build 281)

Use the text below in **App Review Information > Notes**.

## 1) App Overview
Thiscount is a location-based coupon wallet. Users discover nearby discount offers on a live map, pick them up when they are within range, and redeem them in-store with a code or QR.

## 2) Login / Account for Review
- No pre-created account is required.
- Reviewer can create a new account directly in-app.
- Sign-up uses email + OTP + username + password.
- Email OTP is delivered to the user's inbox. No separate demo account is required.

## 3) Core Test Path
1. Launch app and complete onboarding.
2. Allow or deny location permission.
3. Sign up with email, OTP, username, and password.
4. On the map, tap any coupon pin that is within pickup range.
5. Open the Inbox/Collection tab and open a picked coupon.
6. Verify the redemption code or QR is shown on the detail screen.

## 4) How to Reach Subscription Screen
- Path A: `Profile` -> `Premium`
- Path B: `Settings` -> `구독`
- In some first-run cases, a Premium welcome screen may appear after the first successful pickup/send flow.

## 5) In-App Purchases to Test
- Premium Monthly: `thiscount_premium_monthly_ios`
- Brand Monthly: `thiscount_brand_monthly_ios`
- Gift 1 Month: `thiscount_gift_1month_ios`
- Brand Extra 1000: `thiscount_brand_extra_1000_ios`

Expected behavior:
- Premium/Brand purchase opens the native Apple purchase sheet.
- Restore purchase may show Apple ID sign-in prompt. This is expected iOS behavior.
- Gift purchase shows a success dialog and generated gift code after successful purchase.
- Brand Extra 1000 is available only when Brand is active.

## 6) Permissions
- Location permission is optional for account creation, but required to pick up nearby coupons on the map.
- If location permission is denied, the app shows a top banner with a deep link to Settings.
- Notifications permission is optional and used for nearby reward / arrival alerts.
- Photos permission is requested only when the user attaches an image to a promo/campaign post or profile.

## 7) Additional Technical Notes
- The app uses RevenueCat for subscription handling.
- If App Store product metadata fails to load because of transient store/network conditions, the app shows a retry message instead of crashing.
- New users receive a 3-day Premium trial via in-app local entitlement. There is no automatic charge after the trial ends unless the user explicitly purchases a plan.

## 8) Contact for Review Team
- Support: `support@thiscount.io`
