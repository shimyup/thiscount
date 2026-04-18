# Release Notes — Build 70 (1.0.0+70)

Date: 2026-04-18

---

## Korean (한국어)

**베타 테스터 개선**

- 프리미엄 구독을 실제 결제 없이 체험할 수 있도록 베타 무료 모드가 적용되었습니다
  (TestFlight / 내부 테스트 빌드 한정, 정식 출시 빌드에서는 정상 결제로 전환)
- 관리자 패널이 지정된 테스터 이메일(shimyup@gmail.com)로 로그인 시 바로 열립니다
  (정식 출시 빌드에서는 자동 차단되어 보안 문제 없음)

**백그라운드 개선**

- 빌드 파이프라인에 베타 전용 플래그 주입 로직 추가 (BETA_FREE_PREMIUM / BETA_ADMIN_EMAIL)
- 릴리스 빌드에서도 환경변수 기반으로 베타 기능을 안전하게 활성화/비활성화할 수 있음

---

## English

**Tester Experience**

- Beta-free premium mode enabled — testers can experience Premium features
  without going through App Store / Play billing (limited to TestFlight /
  internal test builds; production builds revert to paid flow)
- Admin panel now accessible in release builds when signed in with the
  designated tester email (shimyup@gmail.com). Automatically locked out in
  production builds for security

**Under the Hood**

- Build pipeline now injects beta-only flags (BETA_FREE_PREMIUM / BETA_ADMIN_EMAIL)
- Beta features can be toggled on/off safely via environment variables in
  release builds without code changes

---

## Japanese (日本語)

**ベータテスター向け改善**

- プレミアムを実際の決済なしで体験できる「ベータ無料モード」を有効化
  （TestFlight／内部テスト版のみ。正式版では通常の決済に戻ります）
- 指定されたテスター用メール（shimyup@gmail.com）でログインすると、
  リリースビルドでも管理者パネルに直接アクセスできます
  （正式版では自動的にロックされるためセキュリティ上の問題なし）

**内部改善**

- ビルドパイプラインにベータ専用フラグ注入ロジックを追加
  （BETA_FREE_PREMIUM／BETA_ADMIN_EMAIL）
- リリースビルドでも環境変数ベースでベータ機能を安全に ON/OFF 切替可能

---

## Chinese (中文)

**测试者体验改进**

- 启用"测试免费高级版"模式 — 测试者可免支付直接体验 Premium 功能
  （仅限 TestFlight／内部测试版本，正式发布版仍走正常付费流程）
- 指定测试邮箱（shimyup@gmail.com）登录时，正式发布版也可直接进入管理员面板
  （正式发布版会自动锁定，不影响安全）

**底层优化**

- 构建流水线新增测试专属标志注入逻辑（BETA_FREE_PREMIUM / BETA_ADMIN_EMAIL）
- 发布构建也可通过环境变量安全地开关测试功能，无需改动代码

---

## Changes in this Build

### Code
- `lib/core/config/app_keys.dart`: new `BetaConstants.adminEmail` + `isAdmin()` helper
  (dart-define driven, gates to false when unset)
- `lib/features/admin/admin_screen.dart`: admin panel access expanded with
  `(kDebugMode && testBrandEmail) || BetaConstants.isAdmin()`
- `lib/features/premium/premium_screen.dart`: brand-card "isAdminBrand" +
  "isTestBrandAccount" checks expanded with same rule
- `lib/features/settings/settings_screen.dart`: settings → admin panel
  section visible under same condition
- `lib/core/services/purchase_service.dart`: `applyTestEmailOverride()` now
  auto-grants brand tier for BETA_ADMIN_EMAIL in release builds too

### Build pipeline
- `scripts/build_ios_release.sh`: injects `BETA_ADMIN_EMAIL` dart-define
  when env var is set
- `scripts/build_android_release.sh`: same
- `.env.local`: added `BETA_ADMIN_EMAIL=shimyup@gmail.com`

### Version
- `pubspec.yaml`: 1.0.0+69 → 1.0.0+70

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB, direct install QA): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- BETA_FREE_PREMIUM flag: injected and logged during both iOS & Android builds
- BETA_ADMIN_EMAIL flag: injected and logged during both iOS & Android builds

## 정식 출시 전 점검 사항

1. `.env.local` 에서 `BETA_FREE_PREMIUM=true` 줄 삭제 (또는 `false`로 변경)
2. `.env.local` 에서 `BETA_ADMIN_EMAIL=...` 줄 삭제
3. 재빌드 → 결제 흐름과 관리자 패널이 자동으로 정상(잠금) 상태로 전환됨을 확인
