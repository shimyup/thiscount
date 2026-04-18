# Build 71 — Paste-Ready Release Notes

Date: 2026-04-18
Version: 1.0.0 (71)

이번 빌드는 배포 전 보안 감사 결과 발견된 취약점을 수정한 핫픽스입니다.
테스터에게는 Build 70과 동일하게 보입니다.

---

## 📱 Google Play Console (500자 제한 · 언어별)

### 한국어 (ko-KR)
```
🔒 내부 보안 강화

• 안정성을 높이기 위한 내부 업데이트입니다
• 테스터가 체감하는 변화는 없습니다 — Build 70과 동일하게 이용하실 수 있어요
• Premium 무료 체험과 관리자 계정 기능은 그대로 유지됩니다

피드백은 계속 환영합니다!
```

### English (en-US)
```
🔒 Internal Security Hardening

• Under-the-hood stability update
• No visible change for testers — works identically to Build 70
• Free Premium trial and admin account access remain available

Keep the feedback coming!
```

### 日本語 (ja)
```
🔒 内部セキュリティ強化

• 安定性向上のための内部アップデート
• テスターへの見た目の変化はありません — Build 70 と同じように使えます
• プレミアム無料体験と管理者アカウント機能はそのまま維持

フィードバックをお待ちしています！
```

### 中文 (zh-CN)
```
🔒 内部安全加固

• 用于提升稳定性的底层更新
• 测试者无感知变化 — 使用体验与 Build 70 完全相同
• Premium 免费体验与管理员账号功能保持不变

期待您继续反馈！
```

---

## 🍎 App Store Connect — TestFlight "테스트할 내용"

### 한국어
```
Build 71 (1.0.0+71) — 핫픽스 빌드

Build 70에서 발견된 보안 이슈를 수정한 빌드입니다.
테스터는 기존과 동일하게 모든 기능을 사용하실 수 있습니다.

확인해주세요:
1. Premium 기능 정상 작동 (결제 없이 "구독 시작하기" → 즉시 활성화)
2. shimyup@gmail.com 로그인 → 관리자 패널 접근 가능
3. 오늘의 편지, 차단 버튼, 언어 변경 즉시 반영 등 기존 기능 정상

새 이슈 발견 시: shimyup@gmail.com
```

### English
```
Build 71 (1.0.0+71) — Hotfix Build

Addresses a security issue flagged in the pre-release audit of Build 70.
Testers will see the same experience as before — all features unchanged.

Please verify:
1. Premium features still activate instantly via "Start Subscription"
   (no payment screen, under the beta free mode)
2. Admin panel still accessible when logged in as shimyup@gmail.com
3. Today's Letter / Block button / instant language switch all intact

Report new issues to: shimyup@gmail.com
```

---

## 🔒 정식 출시 전 점검 체크리스트 (Build 72+ 준비 시)

Build 71 에는 보안 가드가 포함되어 있어 정식 출시 전환이 안전합니다.
최종 릴리스 빌드 생성 시:

- [ ] `.env.local` 에서 `BETA_FREE_PREMIUM=true` 줄 제거
- [ ] `.env.local` 에서 `BETA_ADMIN_EMAIL=...` 줄 제거
- [ ] 버전을 1.0.0+72 이상으로 증가
- [ ] 재빌드 후 빌드 로그에 `BETA_` 메시지가 출력되지 않는지 확인
- [ ] TestFlight 내부 테스터 장치에서 Build 72 업데이트 시
      Premium 상태가 자동으로 해제되는지 실기기 테스트
- [ ] shimyup@gmail.com 로 로그인해도 관리자 메뉴가 보이지 않는지 확인

---

## 🔗 관련 파일

- 상세 릴리즈 노트: `docs/release/release-notes-build-71.md`
- 보안 수정 상세: commit `0c827bd`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab` (53MB)
- iOS IPA: `build/ios/ipa/Letter Go.ipa` (37.9MB)
