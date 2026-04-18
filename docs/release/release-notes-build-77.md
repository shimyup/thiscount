# Release Notes — Build 77 (1.0.0+77)

Date: 2026-04-19

---

## Korean (한국어)

**긴급 핫픽스 — 인증 이메일 미도착 이슈**

- SendGrid API 키가 빌드에 주입되지 않아 OTP 이메일이 실제로 발송되지
  않던 문제를 베타 기간 임시 해결
- SendGrid 미설정 상태에서는 앱 화면에 인증 코드를 **직접 표시**하도록
  변경 (오렌지 박스 + "베타 인증 코드 (이메일 미발송 중)" 안내)
- SendGrid 키가 주입되면 이 임시 노출은 자동으로 사라짐 → 즉시 복구 가능

**테스터 행동 변화**

- 기존: 이메일 인증 화면에서 메일 기다리다 막힘 (메일이 영영 안 옴)
- 신규: OTP 화면 상단 오렌지 박스에 6자리 코드가 바로 표시됨 → 그 코드를
  아래 입력란에 입력하고 회원가입 완료

---

## English

**Hotfix — Auth Emails Not Arriving**

- SendGrid API key was not injected into the build, so OTP emails were
  never actually sent. EmailService.sendOtp() was silently returning
  null (treated as "success") while testers waited forever.
- Now during beta, when SendGrid isn't configured, the OTP code is
  **displayed directly on screen** (orange callout box with message
  "Beta verification code — email delivery unavailable").
- Once SendGrid is configured via dart-define, this on-screen fallback
  auto-hides — no code changes needed.

**Behavior change for testers**

- Before: stuck at OTP screen waiting for email that never arrived
- Now: 6-digit code shown in orange box above the input field. Type it
  into the input and continue signup normally.

---

## Japanese (日本語)

**緊急ホットフィックス — 認証メール未到着問題**

- SendGrid API キーがビルドに注入されておらず OTP メールが実際には
  送信されなかった問題をベータ期間用に一時解決
- SendGrid 未設定時はアプリ画面に直接認証コードを表示
- SendGrid キー注入後は自動的にこの一時表示が消えます

---

## Chinese (中文)

**紧急热修复 — 认证邮件未到达**

- SendGrid API 密钥未注入到构建中, OTP 邮件实际未发送的问题
  在测试期间临时解决
- SendGrid 未配置时在应用界面直接显示验证码
- SendGrid 密钥注入后此临时显示会自动消失

---

## Changes in this Build

### Code
- `lib/features/auth/screens/auth_screen.dart` (line ~1959):
  - Previously: `if (kDebugMode && _devOtpCode != null)` — DEBUG only
  - Now: `if ((kDebugMode || !EmailService.isConfigured) && _devOtpCode != null)` —
    also show in RELEASE builds when SendGrid isn't configured
  - UI reworked to include context labels: header "📬 베타 인증 코드
    (이메일 미발송 중)" and footer "위 코드를 아래 입력란에 넣어주세요"

### Version
- `pubspec.yaml`: 1.0.0+76 → 1.0.0+77

### No changes
- Backend behavior (EmailService still returns null when unconfigured)
- Other screens / features
- Build pipeline

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- BETA_FREE_PREMIUM / BETA_ADMIN_EMAIL injected in both platforms

## 근본 해결 경로 (Build 78+ 에서)

Build 77 은 베타 구제 임시 조치입니다. 정식 출시 전 다음 두 가지 중 택일:

### 옵션 1: SendGrid 연동 (권장, 30분)
1. SendGrid 계정 생성 (https://signup.sendgrid.com, 무료)
2. Sender Authentication → 발신 이메일 검증 (예: `noreply@airony.xyz`)
3. Settings → API Keys → 새 키 발급
4. `.env.local` 에 추가:
   ```
   SENDGRID_API_KEY=SG.xxxxxxxxxx
   SENDGRID_FROM_EMAIL=noreply@airony.xyz
   ```
5. `scripts/build_{ios,android}_release.sh` 에 dart-define 주입 추가
6. Build 78 재빌드 → TestFlight/Play 교체 → Build 77 의 화면 노출
   자동 숨김, 실제 이메일 발송 작동

### 옵션 2: Firebase Auth Email Link (무료, 구현 1-2시간)
Google 인프라 사용, 별도 결제 없음. 매직링크 방식으로 전환.
OTP 6자리 대신 이메일의 링크 클릭으로 인증.

## 배포 후 테스터 안내

테스터들에게 다음 메시지를 전달해주세요:

> "Build 77 설치 후 회원가입 시 오렌지색 박스에 표시되는 6자리
> 인증코드를 아래 입력란에 그대로 입력해주세요. 이메일 발송 시스템은
> 별도 작업 중이며, 일시적으로 화면에 직접 표시됩니다."
