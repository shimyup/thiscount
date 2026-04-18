# Build 72 — Paste-Ready Release Notes

Date: 2026-04-18
Version: 1.0.0 (72)

이번 빌드는 앱의 **핵심 기능 완성** 빌드입니다. 이제 테스터끼리 실제로 편지를
주고받을 수 있고, 지도에서 다른 회원이 실시간으로 보입니다.

---

## 📱 Google Play Console (500자 제한 · 언어별)

### 한국어 (ko-KR)
```
✉️ 드디어 진짜로 편지가 오고 갑니다!

• 다른 테스터에게 보낸 편지가 실제로 상대방에게 도착해요
  (30초 이내 동기화)
• 상대방이 답장을 보내면 내 편지함에도 곧바로 도착합니다
• 지도에서 로그인한 다른 회원의 타워가 실시간으로 보여요
• 차단한 회원의 타워는 즉시 지도에서 사라집니다

이제 진짜로 전 세계와 연결되는 Letter Go를 경험해보세요!
```

### English (en-US)
```
✉️ Real letters now travel between testers!

• Letters you send actually reach the recipient now
  (synced within 30s)
• Replies from other testers arrive in your inbox
• Map now shows live towers of other logged-in members
• Blocking a sender removes their tower from the map instantly

Experience the real global connection Letter Go was built for!
```

### 日本語 (ja)
```
✉️ ついに本物の手紙がやり取りできます！

• 他のテスターに送った手紙が実際に相手に届きます（30秒以内で同期）
• 相手からの返信も受信トレイに届きます
• 地図上でログイン中の他ユーザーのタワーがリアルタイム表示
• ブロックしたユーザーのタワーは地図から即座に消えます

本当の世界とのつながりをLetter Goで体験してください！
```

### 中文 (zh-CN)
```
✉️ 测试者之间终于可以真正互相收发信件了！

• 发给其他测试者的信件现在真的会送到对方（30秒内同步）
• 对方回信也会立刻出现在你的收件箱
• 地图上实时显示其他登录中的用户塔楼
• 屏蔽用户后其塔楼从地图上立即消失

来体验 Letter Go 真正的全球连接吧！
```

---

## 🍎 App Store Connect — TestFlight "테스트할 내용"

### 한국어
```
Build 72 (1.0.0+72) — 핵심 기능 완성

이번 빌드에서 테스터끼리 실제 편지 교환이 작동합니다!

1. 실제 편지 수신 테스트
   • 다른 테스터에게 편지 발송 → 상대방이 30초 이내 받는지 확인
   • 상대가 답장 → 내 편지함에 30초 이내 도착 확인
   • 전달 경로에 따라 inbox (도착) 또는 지도 (이동 중) 에 표시

2. 지도 실시간 동기화
   • 지도에서 다른 로그인 회원 타워가 30초마다 갱신되는지
   • 회원가입 직후 본인 타워가 다른 사람 지도에도 나타나는지
   • 지도 공개 OFF → 다른 사람 지도에서 사라지는지

3. 차단 즉시 반영
   • 받은 편지에서 🚫 차단 → 해당 발송자 타워 지도에서 즉시 삭제
   • 차단 후 30초 후에도 재등장하지 않는지

4. 네트워크 내성
   • 비행기 모드 → 에러 메시지 없이 조용히 대기
   • 복구 후 다음 주기에 자동 동기화

알려진 이슈: 첫 동기화까지 최대 30초 소요 가능
문의: shimyup@gmail.com
```

### English
```
Build 72 (1.0.0+72) — Core Feature Complete

Real cross-tester letter exchange now works!

1. Real Letter Reception Test
   • Send a letter to another tester → they should receive within 30s
   • They reply → appears in your inbox within 30s
   • Letter routes to inbox (delivered) or map (in-transit)

2. Map Live Sync
   • Other logged-in towers refresh every 30 seconds
   • Your own tower appears on others' maps after signup
   • Toggling map-visibility OFF → tower disappears from others

3. Instant Block Propagation
   • 🚫 Block from a received letter → sender's tower gone from map
   • Confirm it doesn't reappear after 30s tick

4. Network Resilience
   • Airplane mode → no error toast, silent wait
   • After recovery → auto-sync on next tick

Known: Up to 30s delay for first sync
Contact: shimyup@gmail.com
```

---

## 🔒 정식 출시 전 점검 체크리스트 (Build 73+ 준비 시)

- [ ] `.env.local` 에서 `BETA_FREE_PREMIUM=true` 줄 제거
- [ ] `.env.local` 에서 `BETA_ADMIN_EMAIL=...` 줄 제거
- [ ] 버전을 1.0.0+73 이상으로 증가
- [ ] 서버 동기화 주기 30초 유지 or 조정 (비용/배터리 트레이드오프)
- [ ] Firestore 보안 규칙 점검:
      users 컬렉션에 isMapPublic=false 인 문서가 조회 안 되는지,
      본인이 아닌 자는 자기 문서만 쓸 수 있는지
- [ ] 실기기 2대 이상으로 A→B 편지 전달 실측 (KR↔JP, KR↔US 등)
- [ ] 배터리 영향 측정 (1시간 idle 상태에서 % 소모)

---

## 🔗 관련 파일

- 상세 릴리즈 노트: `docs/release/release-notes-build-72.md`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab` (53MB)
- iOS IPA: `build/ios/ipa/Letter Go.ipa` (37.9MB)
