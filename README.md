# LetterGo

Flutter mobile app for global letter exchange, map-based delivery tracking, and profile/tower progression.

## Local setup

1. Copy `.env.example` to `.env.local`.
2. Fill required keys:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_API_KEY`
   - `FIREBASE_STORAGE_BUCKET`
3. Optional:
   - `STADIA_MAPS_API_KEY` (enables unified map labels in selected app language)

## Run / build scripts

- Android debug run:
  - `./scripts/run_android_debug.sh`
  - or `./scripts/run_android_debug.sh <device_id>`
- Android release build:
  - `./scripts/build_android_release.sh`

Both scripts load `.env.local` and inject `--dart-define` values automatically.

## Branch safety

- Check current branch before staging/commit:
  - `./scripts/ensure_feature_branch.sh`
- Recommended: work on `codex/*` or `feature/*` branches, not `main`.

## Security check

- Run: `./scripts/security_audit.sh`
- This checks:
  - secret-like files tracked by git (fails CI)
  - local sensitive files left inside repo directory (warning)

### Firebase secret files (outside repo)

- Store secrets to external vault path:
  - `./scripts/manage_firebase_secrets.sh store`
- Restore secrets back to project when needed:
  - `./scripts/manage_firebase_secrets.sh restore`
- Check current status:
  - `./scripts/manage_firebase_secrets.sh status`

Default vault path:
- `../.secrets/lettergo`

Sensitive files managed:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Local cleanup

- Clean build artifacts/caches:
  - `./scripts/clean_local_artifacts.sh`

## CI

GitHub Actions workflow: `.github/workflows/flutter_ci.yml`

Pipeline steps:
1. `flutter pub get`
2. `./scripts/security_audit.sh`
3. `flutter test`
4. `flutter analyze --no-fatal-infos --no-fatal-warnings`
5. `flutter build apk --debug`

## Marketing Docs

- `docs/marketing/positioning.md`
- `docs/marketing/value-props.md`
- `docs/marketing/campaign-calendar.md`
- `docs/marketing/aso-copy-ko-en.md`

## Release Docs

- `docs/release/store-launch-checklist.md`
- `docs/release/pre-release-readiness-2026-04-01.md`
- `docs/release/app-store-review-notes.md`
- `docs/release/play-data-safety-draft.md`
- `docs/support.html`
- `docs/terms.html`
- `docs/privacy.html`
