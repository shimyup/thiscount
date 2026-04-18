# Build 70 — Paste-Ready Release Notes

Date: 2026-04-18
Version: 1.0.0 (70)

베타 테스터 경험 개선 빌드입니다. 아래 내용을 Play Console과 TestFlight 필드에
그대로 복사해 사용하세요.

---

## 📱 Google Play Console (500자 제한 · 언어별)

### 한국어 (ko-KR)
```
🎁 테스터 전용 혜택

• 프리미엄 기능을 결제 없이 체험할 수 있어요
  (내부 테스트 빌드 한정)
• 관리자 테스터 계정(shimyup@gmail.com)은 앱 내 관리자 패널을 바로 열 수 있어요

안정성 개선과 함께 베타 테스트 환경을 더 편하게 만들었어요.
피드백은 언제든지 환영합니다!
```

### English (en-US)
```
🎁 Tester Perks

• Experience Premium features without real payment
  (internal test builds only)
• Admin tester account (shimyup@gmail.com) can open the in-app admin
  panel directly

We polished the beta testing environment. Your feedback is always welcome!
```

### 日本語 (ja)
```
🎁 テスター限定特典

• Premium機能を課金なしで体験可能
  （内部テスト版のみ）
• 管理者テスターアカウント（shimyup@gmail.com）はアプリ内管理者パネルに
  直接アクセス可能

ベータテスト環境を改善しました。フィードバックお待ちしています！
```

### 中文 (zh-CN)
```
🎁 测试者专属福利

• 无需付费即可体验 Premium 功能
  （仅限内部测试版）
• 管理员测试账号（shimyup@gmail.com）可直接进入应用内管理员面板

我们改进了测试环境，欢迎随时反馈！
```

---

## 🍎 App Store Connect — TestFlight "테스트할 내용"

### 한국어
```
Build 70 (1.0.0+70) — 테스트 가이드

이번 빌드의 핵심 체크 항목:

1. Premium 무료 체험
   • 프로필 → Letter Go Premium → "구독 시작하기" 탭
   • 결제 화면 없이 즉시 Premium 기능(하루 30통, 이미지+링크, 특송 등) 활성화되는지 확인
   • 홈·편지함·작성 화면의 프리미엄 한도와 뱃지가 바뀌는지 확인

2. 관리자 패널 (shimyup@gmail.com 로그인 시에만)
   • 설정 → 🔐 관리자 패널 진입
   • 편지 속도 조절, 편지 수동 배달, 차단 관리 등이 정상 작동하는지 확인
   • 다른 이메일로 로그인 시 관리자 메뉴가 보이지 않는지 확인

3. 이전 빌드 기능 회귀 확인
   • 오늘의 편지 연속 탭 → 다른 글귀 표시
   • 설정 → 언어 변경 즉시 반영 (한 ↔ 영 ↔ 아랍어)
   • 회원가입 시 전화번호 비워도 가입 가능
   • 받은 편지에서 🚫 차단 버튼 + 다이얼로그 작동

알려진 이슈: 없음
문의: shimyup@gmail.com
```

### English
```
Build 70 (1.0.0+70) — Testing Guide

Key checks in this build:

1. Free Premium Trial
   • Profile → Letter Go Premium → "Start Subscription"
   • Premium features (30/day, image+link, express) should activate instantly
     without going through the payment screen
   • Verify premium quotas and badges appear across home / inbox / compose

2. Admin Panel (only when logged in as shimyup@gmail.com)
   • Settings → 🔐 Admin Panel
   • Verify speed control, manual delivery, block management all work
   • With any other email, admin menu should NOT appear

3. Regression Checks from Previous Builds
   • Today's Letter — tapping repeatedly shows different quotes
   • Settings → language change applies instantly (KO ↔ EN ↔ AR)
   • Signup works without entering phone number
   • 🚫 Block button on received letter shows dialog and filters inbox

Known Issues: None
Contact: shimyup@gmail.com
```

---

## 🔒 정식 출시 전 점검 체크리스트

Build 70 은 베타 전용 플래그가 활성화되어 있습니다. 정식 출시 빌드 전에
반드시 확인하세요:

- [ ] `.env.local` 에서 `BETA_FREE_PREMIUM=true` 줄 제거
- [ ] `.env.local` 에서 `BETA_ADMIN_EMAIL=...` 줄 제거
- [ ] 재빌드 후 `grep "BETA_" build/app/outputs/bundle/release/app-release.aab`
      결과에 플래그가 없는지 확인 (또는 빌드 로그에 BETA 메시지 미출력 확인)
- [ ] TestFlight / Play Console 업로드 전 사이드 테스트
      → Premium 구매 시 RevenueCat 결제 화면이 실제로 뜨는지 확인
      → shimyup@gmail.com 로 로그인해도 관리자 패널 메뉴가 보이지 않는지 확인

---

## 🔗 관련 파일

- 상세 릴리즈 노트: `docs/release/release-notes-build-70.md`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab` (53MB)
- iOS IPA: `build/ios/ipa/Letter Go.ipa` (37.9MB)
