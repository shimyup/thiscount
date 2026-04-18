# Release Notes — Build 71 (1.0.0+71)

Date: 2026-04-18

---

## Korean (한국어)

**보안 개선 (배포 전 감사 대응)**

- 베타 빌드에서 부여된 무료 Premium 상태가 정식 빌드로 전환된 후에도
  남아 결제 없이 Premium을 계속 이용할 수 있었던 취약점을 수정했습니다
- 베타 혜택은 이제 `ps_beta_granted` 마커로 추적되며, 정식 빌드에서는
  자동으로 청소되어 RevenueCat 결제 검증이 유일한 권위를 갖게 됩니다

**기능 변화 없음**

- 테스터 입장에서는 Build 70과 동일하게 동작합니다
  (Premium 무료 체험 / 관리자 계정 모두 그대로)

---

## English

**Security Hardening (Pre-deployment Audit Fix)**

- Fixed a vulnerability where Premium entitlement granted via
  BETA_FREE_PREMIUM would persist in secure storage and survive the
  transition to a production build, effectively giving testers free
  Premium forever without any purchase record
- Beta grants are now marked with `ps_beta_granted` and automatically
  cleared on non-beta builds, making RevenueCat the single source of
  truth for entitlement

**No Behavior Change for Testers**

- Identical to Build 70 in day-to-day use — free Premium trial and
  admin account access both remain available

---

## Japanese (日本語)

**セキュリティ強化（リリース前監査対応）**

- BETA_FREE_PREMIUM で付与されたプレミアム状態が正式版ビルドへ
  移行後も残り、課金なしでプレミアムを使い続けられる脆弱性を修正
- ベータ特典は `ps_beta_granted` マーカーで追跡され、正式版ビルドでは
  自動的に削除され、RevenueCat の購入検証が唯一の権威となります

**テスターへの影響なし**

- 利用感はBuild 70と同じ（プレミアム無料体験・管理者アカウントどちらも継続）

---

## Chinese (中文)

**安全加固（发布前审查修复）**

- 修复了测试版中通过 BETA_FREE_PREMIUM 授予的 Premium 状态在切换到
  正式版后仍然保留的漏洞 —— 原本可能导致测试者无支付记录下永久免费使用
- 测试授权现在使用 `ps_beta_granted` 标记跟踪，正式版构建启动时会自动
  清除，使 RevenueCat 成为唯一的权限验证来源

**测试者无感知变化**

- 与 Build 70 用户体验完全相同（免费 Premium 体验和管理员账号均保留）

---

## Changes in this Build

### Code
- `lib/core/services/purchase_service.dart`:
  - `_saveSecurePremiumState()`: when saving Premium under `_isBetaFreePremium=true`,
    also writes `ps_beta_granted='1'` marker to secure storage
  - `_loadSecurePremiumState()`: on load, if marker present AND current build
    has `_isBetaFreePremium=false`, wipe premium state and marker
  - `_clearSecurePremiumState()`: also deletes the marker

### Version
- `pubspec.yaml`: 1.0.0+70 → 1.0.0+71

### No changes
- UI / UX layer
- Localization
- Build scripts (already good)
- Other services

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- Pre-deployment audit: all 1 BLOCKER resolved, 2 WARN accepted as low risk

## 정식 출시 시 동작 예상

1. 테스터가 Build 71 설치 → `BETA_FREE_PREMIUM=true` → Premium 부여
   (secure storage: `ps_isPremium=1`, `ps_beta_granted=1`)
2. 나중에 `.env.local`에서 `BETA_FREE_PREMIUM` 제거 후 정식 빌드 업로드
3. 테스터가 정식 빌드로 업데이트 → 앱 시작 시 마커 발견 → Premium 자동 해제
4. 진짜로 결제 원하면 App Store/Play 구독 → RevenueCat 정식 검증 경로로 전환

**결과**: 테스터 장치에 누적된 "가짜 Premium"이 깨끗하게 정리되어 실제
결제를 거친 사용자만 Premium 상태 유지.
