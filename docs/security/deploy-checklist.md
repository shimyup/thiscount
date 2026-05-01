# Letter Go 릴리스 배포 보안 체크리스트

매 정식 출시(빌드 200대 이상) 전 반드시 항목별로 확인하고 PR 본문에
체크박스 형태로 옮겨 붙여 주세요.

---

## 코드/빌드 검증

- [ ] `flutter analyze` 0 issues
- [ ] `flutter test` 모두 pass (최소 48개)
- [ ] `pubspec.yaml` 버전 bump (`1.0.0+N`)
- [ ] `flutter pub outdated` 의 SECURITY-tagged 패키지 업데이트 검토
- [ ] 디버그 출력 스캔: `grep -rn "debugPrint\|print(" lib/` 결과 중 PII / 비밀
      정보 출력 라인이 없어야 함 (`assert(() {...}())` 안에 있으면 OK)

## 환경 변수 / 비밀

- [ ] `--dart-define` 주입 목록 확인:
  - `RESEND_API_KEY` 또는 `SENDGRID_API_KEY` (이메일 OTP)
  - `TWILIO_AUTH_TOKEN` (SMS OTP)
  - `REVENUECAT_API_KEY_IOS` / `REVENUECAT_API_KEY_ANDROID`
  - **`BETA_FREE_PREMIUM`** ← 정식 출시 시 **반드시 제거**
  - **`BETA_ADMIN_EMAIL`** ← 정식 출시 시 **반드시 제거**
  - `BETA_DISABLE_IN_RELEASE` 는 default `true` — 명시적 override 안 함
- [ ] 리포지토리에 `.env*`, `*-secret.json`, key 파일이 commit 되지 않았는지
      `git ls-files | grep -i 'secret\|key\|env'` 확인
- [ ] `ios/Runner/GoogleService-Info.plist` 와 `android/app/google-services.json`
      의 API 키가 GCP Console > Credentials 에서 **bundle ID / package name
      restriction** 설정돼 있는지 확인

## Firebase 규칙 배포

- [ ] `firestore.rules` 변경 시: `firebase deploy --only firestore:rules`
- [ ] `storage.rules` 변경 시: `firebase deploy --only storage`
- [ ] 배포 후 Firebase Console > Rules > **Simulator** 로 다음 시나리오 검증:
  - 익명 사용자가 `letters/{anyId}` create → reject (signedIn 필요)
  - signedIn 사용자가 `letters/{id}` 의 `content` 필드 변경 PATCH → reject
  - signedIn 사용자가 `letters/{id}` 의 `pickupCount` 증가 PATCH → allow
  - signedIn 사용자가 `users/{otherId}` 삭제 → allow (베타 한계 — 익명 인증)
  - 익명 사용자가 Storage `vouchers/foo.jpg` GET → reject
  - signedIn 사용자가 Storage `vouchers/foo.zip` (10MB+) PUT → reject
  - signedIn 사용자가 Storage `brand_ads/x.jpg` PUT → reject (admin REST 만)

## iOS / Android 권한

- [ ] `ios/Runner/Info.plist` 에 `NSLocationAlwaysAndWhenInUseUsageDescription`
      이 **없어야 함** (When In Use 만)
- [ ] iOS App Store Connect Privacy "App Privacy" 항목이 다음을 정확히 선언:
  - Coarse Location (Optional, App Functionality)
  - User-Generated Content / Photos (Optional, App Functionality)
  - Email Address (Required, App Functionality + Account Management)
  - Phone Number (Optional, App Functionality)
- [ ] Android `Manifest` 의 `ACCESS_BACKGROUND_LOCATION` 권한이 **없어야 함**

## 프로덕션 검증 (TestFlight / Internal Testing)

- [ ] OTP 발송 실패 시 화면에 코드가 표시되지 않는지 (Twilio/Resend 일시
      차단 시뮬레이션)
- [ ] 익명 편지 발송 후 Firestore Console 에서 letter 문서를 직접 확인 →
      `senderId='anon_...'`, `senderName='__anonymous__'` 인지 확인
- [ ] 회원 탈퇴 → Firestore `users/{id}` 사라짐, `letters` 의 본인 발송 항목
      `status='deletedBySender'` 로 마킹됨
- [ ] Premium 구독 결제 → Brand 자동 승급 안 됨 (정식 출시는 Premium 만 자동)
- [ ] BETA_DISABLE_IN_RELEASE=true 빌드에서 `BETA_ADMIN_EMAIL` 가 작동 안 함
- [ ] 광고 모달 새 letter 도착 시 정상 노출 + 같은 letter 재노출 안 됨

## 사고 대응 준비

- [ ] [SECURITY.md](../../SECURITY.md) 의 사고 대응 섹션 1회 정독
- [ ] Firebase Console 권한자 목록 최신화 (퇴사자 제거)
- [ ] Apple Developer / Google Play Console 의 2FA 활성화 확인

---

체크리스트 완료 후 PR 본문에 다음을 기재:
> ✅ Build 207 release security checklist completed by @<reviewer> on YYYY-MM-DD
