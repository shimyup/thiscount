# Build 76 — Paste-Ready Release Notes

Date: 2026-04-18
Version: 1.0.0 (76)

이번 빌드는 **관리자 계정 전환 + Firestore 보안 규칙 배포** 빌드입니다.
일반 테스터 입장에서는 변화가 거의 없지만, 관리자 접근 계정이 바뀌었습니다.

---

## 📱 Google Play Console (500자 제한 · 언어별)

### 한국어 (ko-KR)
```
🔐 관리자 계정 전환 + 보안 규칙 적용

• 관리자 계정이 ceo@airony.xyz 로 변경되었어요
• Firestore 보안 규칙이 서버에 정식 적용되어 데이터 보호가 강화됩니다
• 일반 테스터 경험에는 변화가 없습니다 — 편지 교환, 지도, 알림 모두 그대로

이전 빌드(75)의 비용 최적화와 함께 안정적으로 운영될 준비가 완료되었습니다.
```

### English (en-US)
```
🔐 Admin Migration + Security Rules Deployed

• Admin account moved to ceo@airony.xyz
• Firestore security rules officially deployed — stronger data protection
• No visible change for regular testers — letters, map, notifications
  all work the same

Combined with Build 75's cost optimization, the app is now production-ready.
```

### 日本語 (ja)
```
🔐 管理者移行 + セキュリティルール配置

• 管理者アカウントが ceo@airony.xyz に変更されました
• Firestore セキュリティルールが本番配置され、データ保護が強化
• 一般テスターの利用感は変わりません — 手紙、地図、通知すべてそのまま

Build 75 のコスト最適化と合わせて、本番運用準備が完了しました。
```

### 中文 (zh-CN)
```
🔐 管理员迁移 + 安全规则部署

• 管理员账号迁移至 ceo@airony.xyz
• Firestore 安全规则正式部署，数据保护更完善
• 普通测试者使用体验不变 — 信件、地图、通知均照旧

结合 Build 75 的成本优化，应用已具备正式运营条件。
```

---

## 🍎 App Store Connect — TestFlight "테스트할 내용"

### 한국어
```
Build 76 (1.0.0+76) — 관리자 이메일 전환 + 보안 규칙 배포

이번 빌드의 중요 변경:
- 관리자 계정: shimyup@gmail.com → ceo@airony.xyz
- Firestore 보안 규칙 서버 배포 완료

테스트 체크리스트:
1. (관리자만) ceo@airony.xyz 로 회원가입 + OTP 인증
   • 설정 → 🔐 관리자 패널 메뉴가 보이는지
   • 회원 관리 → 목록이 로드되는지 (이전 HTTP 403 사라져야 함)
   • 편지 관리, 속도 조절 등 관리 기능 정상 작동

2. (일반 테스터) 이전 빌드와 동일하게 동작하는지
   • 편지 발송/수신 정상
   • 지도에서 다른 회원 타워 30초~3분 주기로 갱신
   • 오늘의 편지, 차단, 언어 변경 등 기존 기능 모두 유지

3. shimyup@gmail.com 으로 로그인 시 일반 사용자로 동작 확인
   (관리자 메뉴가 보이지 않아야 함)

새 이슈 발견 시: ceo@airony.xyz
```

### English
```
Build 76 (1.0.0+76) — Admin Migration + Security Rules

Key changes:
- Admin account: shimyup@gmail.com → ceo@airony.xyz
- Firestore security rules deployed to production

Testing checklist:
1. (Admin only) Sign up with ceo@airony.xyz + verify OTP
   • Settings → 🔐 Admin Panel should be visible
   • Member Management → list loads (no more HTTP 403)
   • Letter management, speed control etc. all work

2. (Regular testers) Same behavior as previous build
   • Send/receive letters works
   • Map towers refresh every 30s–3min
   • Today's Letter, Block, Language switch all intact

3. shimyup@gmail.com now functions as a regular user
   (admin menu should NOT appear)

Report issues to: ceo@airony.xyz
```

---

## 🔒 정식 출시 전 최종 점검 체크리스트

Build 76 기준으로 다음이 필요합니다 (정식 1.0 출시 전):

- [ ] `.env.local` 에서 `BETA_FREE_PREMIUM=true` 줄 제거
- [ ] `.env.local` 에서 `BETA_ADMIN_EMAIL=...` 줄 제거
- [ ] 버전을 1.0.0+77 이상으로 증가
- [ ] 재빌드 후 빌드 로그에 `BETA_` 메시지 미출력 확인
- [ ] Firestore 규칙: 현재 letters/users 모두 read/list 공개.
      스팸 우려 시 `isSignedIn()` 으로 좁히기
- [ ] FCM 푸시 알림 연동 검토 (10K MAU 돌파 전 우선 작업)
- [ ] 이전 베타 테스터들의 `ps_beta_granted` 마커가 정상적으로
      정식 빌드 첫 실행 시 삭제되는지 실기기 확인

---

## 🔗 관련 파일

- 상세 릴리즈 노트: `docs/release/release-notes-build-76.md`
- Firestore 규칙: `firestore.rules` (배포 완료)
- 비용 최적화 가이드: `docs/release/server-cost-optimization.md`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab` (53MB)
- iOS IPA: `build/ios/ipa/Letter Go.ipa` (37.9MB)
