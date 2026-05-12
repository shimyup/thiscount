# Thiscount Member Flow UX Review

Date: 2026-05-10
Build: 1.0.0+273
Scope: latest local Thiscount app, member viewpoint walkthrough, launch-readiness check

## Fixed in this pass

### 1. Onboarding respects user intent more accurately
- Location step `Skip` now routes through the same warning flow as the main skip action.
- Daily reminder pre-prompt no longer requests notification permission when the user chooses "later".
- Missing country-to-Korean mappings were added for the remaining popular countries.

Files:
- `lib/features/onboarding/onboarding_screen.dart`

### 2. Benefit inbox search is easier for real members
- Search now matches sender name and coupon/redemption guidance in addition to message body and country.
- This reduces failure when users search by brand, shop, or usage note.

Files:
- `lib/features/inbox/screens/inbox_screen.dart`

### 3. Daily reminder toggle now matches actual permission state
- Profile notification toggle only turns on after permission is granted.
- If permission is denied, the UI no longer implies the reminder is active.

Files:
- `lib/features/profile/profile_screen.dart`

### 4. Progression wording is more consistent with the current product
- Remaining "counter" tier labels were updated to the reward-hunt narrative.

Files:
- `lib/features/progression/user_progress.dart`
- `test/user_progress_test.dart`

## Remaining launch priorities

### P0. First-screen visual verification on real device
- Browser-launched web build opened with a black first frame at `http://127.0.0.1:4180/`.
- Flutter debug logs showed startup completed, so this needs device-level confirmation before release.
- Recommendation: run a real iPhone/Android first-launch smoke pass and capture the first three screens.

### P1. Free user navigation still leads attention to a locked center CTA
- The center nav slot is visually dominant but opens an upsell for free users.
- Recommendation: keep the locked CTA, but strengthen map pickup as the primary first-session action with clearer copy or a first-use hint.

File:
- `lib/widgets/main_scaffold.dart`

### P1. Onboarding still has a high information density
- Country selection, location permission, intro slides, and premium entry are all packed into one flow.
- Recommendation: keep each page focused on one decision and shorten supporting text where possible.

File:
- `lib/features/onboarding/onboarding_screen.dart`

### P1. Reward-wallet empty and error states should be reviewed as copy work
- Members need clearer reassurance when there is nothing nearby yet, pickup fails, or a coupon is already used/expired.
- Recommendation: align these states around next action, not just status.

Suggested focus areas:
- `lib/features/inbox/screens/inbox_screen.dart`
- `lib/features/inbox/widgets/letter_read_screen.dart`
- `lib/features/map/screens/world_map_screen.dart`

## Verification run

- `flutter analyze lib/features/onboarding/onboarding_screen.dart lib/features/profile/profile_screen.dart lib/features/inbox/screens/inbox_screen.dart`
- `flutter test`
- `flutter run -d chrome --web-port 4180`

## Notes

- Pre-existing local changes in `ios/.symlinks` and `ios/Pods` were not touched.
