# Android Emulator Smoke Test Report (2026-04-03)

## Environment

- Flutter: `3.41.2`
- Device: `emulator-5554 (sdk gphone64 arm64)`
- Command:
  - `flutter run -d emulator-5554 --debug --target lib/main.dart --no-resident`

## Result

- Build: PASS (`build/app/outputs/flutter-apk/app-debug.apk`)
- Install: PASS
- App launch: PASS
- Initial render engine: PASS (Impeller/OpenGLES log 확인)

## Log Summary

- `Built build/app/outputs/flutter-apk/app-debug.apk`
- `Installing ... app-debug.apk...`
- `Using the Impeller rendering backend (OpenGLES).`
- `Syncing files to device ...`

## Evidence

- Screenshot: `docs/marketing/screenshots/raw/android-home-2026-04-03.png`

## Notes

- Android 실행 가능성은 확인되었고, 결제/권한/푸시는 Play 내부 테스트 트랙에서 별도 시나리오 검증이 필요.
