# Thiscount Store Launch Checklist

## 0) Current Automated Status (Completed)
- `./scripts/release_preflight.sh` PASS
- `flutter analyze` PASS
- `flutter test` PASS
- `./scripts/build_android_release.sh` PASS
  - Output: `build/app/outputs/flutter-apk/app-release.apk`
- `./scripts/build_ios_release.sh` PASS (no codesign)
  - Output: `build/ios/iphoneos/Runner.app`
- Security audit PASS with warning
  - Local secret files present in repo directory (untracked):
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

## 1) App Store Connect (iOS)

### Ready now
- App name: `Thiscount`
- Subtitle (updated for current app): `근처 혜택을 줍는 쿠폰 지갑`
- Description / Keywords draft: `docs/release/app-store-connect-paste-ready.md`
- Privacy Policy page: `docs/privacy.html`

### Manual actions required in App Store Connect
- Fill metadata (name/subtitle/description/keywords/category)
- Upload screenshots:
  - 6.7": `1290 x 2796`
  - 6.5": `1284 x 2778`
  - iPad set if iPad distribution enabled
- Add Support URL (web-hosted page)
- Add Privacy Policy URL (web-hosted page)
- Add Marketing URL (web-hosted page)
- Set age rating questionnaire
- Add App Review notes:
  - core pickup path
  - purchase/restore test steps
  - brand/premium test path
- Set price and territories

## 2) Google Play Console (Android)

### Ready now
- Short/long description draft: `docs/release/app-store-connect-paste-ready.md`
- Privacy Policy page: `docs/privacy.html`
- Android release APK built

### Manual actions required in Play Console
- Fill store listing:
  - App name / short description / full description
- Upload screenshots (phone min 2)
- Upload feature graphic: `1024 x 500` (required)
- Fill Data safety form
- Fill Content rating (IARC)
- Select target age
- Declare ads usage
- Select countries/rollout strategy

## 3) Marketing Text Pack (Ready Draft)
- One-liner, value props: `docs/release/app-store-connect-paste-ready.md`
- KO/EN store copy + screenshot captions: `docs/release/app-store-connect-paste-ready.md`
- Campaign timeline: `docs/marketing/campaign-calendar.md`
- App Store Connect paste-ready final: `docs/release/app-store-connect-paste-ready.md`
- App Review Notes draft: `docs/release/app-store-review-notes.md`
- Play Data Safety checkbox final: `docs/release/play-data-safety-checkboxes.md`
- Real-device purchase QA checklist: `docs/release/real-device-purchase-qa-checklist.md`
- Real-device purchase QA report (1st): `docs/release/real-device-purchase-qa-report-2026-04-02.md`

## 4) Visual Asset Checklist (To produce)
- iOS 6.7 screenshots: 5-10 shots
- iOS 6.5 screenshots: 5-10 shots
- Android screenshots: 2-8 shots
- Play feature graphic: 1024x500
- Optional preview video: 15-30 sec

## 5) Legal/Policy Checklist
- Privacy Policy URL: required
- Terms of Service URL: recommended
- EULA: recommended (especially with subscriptions)
- Open-source license notice: recommended

## 6) Release Gating (Go/No-Go)
- Purchase flow check on real sandbox account:
  - Premium subscribe
  - Brand subscribe
  - Gift purchase
  - Brand extra 1000 purchase
  - Restore purchase
- Subscription product status in RevenueCat:
  - latest iOS product ids mapped
  - default offering contains all required packages
- Crash-free smoke test on:
  - iOS (latest + one previous)
  - Android (latest + one previous)
- Final copy/legal URL double-check in both consoles
