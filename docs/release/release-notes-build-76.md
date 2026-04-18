# Release Notes — Build 76 (1.0.0+76)

Date: 2026-04-18

---

## Korean (한국어)

**관리자 이메일 전환**

- 관리자 계정이 `shimyup@gmail.com` 에서 **`ceo@airony.xyz`** 로 변경되었습니다
- 이 이메일로 로그인 시 릴리스 빌드에서도 관리자 패널 + 브랜드 권한 자동 활성

**Firestore 보안 규칙 배포 완료**

- anonymous 인증 기반 아키텍처 고려하여 규칙을 재설계했습니다
- 관리자 UID 주입 없이도 배포 가능한 구조로 변경
- `firebase deploy` 로 `lettergo-147eb` 프로젝트에 배포 완료

**구조 설명**

- 앱 UI 관리자 판별: 이메일 매칭 (클라이언트)
- 관리자 데이터 접근: API key REST (Build 74 에서 이미 수정)
- Firestore 규칙: 일반 사용자 기본 보호만 담당

---

## English

**Admin Email Migration**

- Admin account moved from `shimyup@gmail.com` to **`ceo@airony.xyz`**
- Signing in with this email on release builds activates admin panel
  and brand tier automatically

**Firestore Security Rules Deployed**

- Rules redesigned to fit the anonymous-auth-based architecture
- Deployable without admin UID injection
- Successfully deployed to `lettergo-147eb` via `firebase deploy`

**Architecture**

- In-app admin gating: email match (client-side)
- Admin data access: API-key REST (already fixed in Build 74)
- Firestore rules: baseline user-data protection only

---

## Japanese (日本語)

**管理者メール変更**

- 管理者アカウントが `shimyup@gmail.com` → **`ceo@airony.xyz`** に変更
- このメールでログインするとリリースビルドでも管理者パネル + ブランド権限が自動有効化

**Firestore セキュリティルール配置完了**

- anonymous 認証アーキテクチャを考慮してルール再設計
- 管理者 UID 注入なしで配置可能な構造に変更
- `firebase deploy` で `lettergo-147eb` プロジェクトに配置完了

---

## Chinese (中文)

**管理员邮箱迁移**

- 管理员账号从 `shimyup@gmail.com` 变更为 **`ceo@airony.xyz`**
- 使用此邮箱登录后，正式版构建也会自动激活管理员面板和品牌权限

**Firestore 安全规则已部署**

- 根据 anonymous 认证架构重新设计规则
- 改为无需注入管理员 UID 即可部署的结构
- 通过 `firebase deploy` 成功部署到 `lettergo-147eb` 项目

---

## Changes in this Build

### Code / config
- `.env.local`: `BETA_ADMIN_EMAIL=ceo@airony.xyz` (gitignored, local only)
- `lib/core/config/app_keys.dart`: `DebugConstants.testBrandEmail` →
  `'ceo@airony.xyz'` — debug builds auto-brand this email now
- `firestore.rules`: rewrote for anonymous-auth architecture.
  Removed `isAdmin()` UID whitelist (doesn't work with rotating
  anonymous UIDs). Baseline protection only:
  · users: read/list open, write requires signed-in
  · letters: read/list open, mutations require signed-in
  · reports: create only; no read/list/update/delete
  · fallback: closed

### Deployment
- Firestore rules + indexes deployed to `lettergo-147eb`:
  - `firestore.rules` (new simplified rules)
  - `firestore.indexes.json` (composite indexes on
    destinationCountry+sentAt, senderId+sentAt)

### Docs
- `docs/release/firestore-rules-setup.md` updated to ceo@airony.xyz
- `docs/release/release-notes-build-74.md` / `75.md` updated
- `docs/release/server-cost-optimization.md` updated

### Version
- `pubspec.yaml`: 1.0.0+75 → 1.0.0+76

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- Build log confirms `BETA_ADMIN_EMAIL=ceo@airony.xyz` injected

## 배포 후 검증 체크리스트

1. Build 76 설치 후 **ceo@airony.xyz 로 회원가입 + OTP 인증 완료**
2. 설정 → 🔐 관리자 패널 메뉴가 보이는지 확인
3. 회원 관리 진입 → 목록이 로드되는지 (HTTP 403 없어야 함)
4. 다른 이메일 계정으로 로그인 → 관리자 메뉴 **안 보임** 확인
5. shimyup@gmail.com 도 Build 76 에서는 **일반 사용자** 로 동작하는지 확인
