# Build 414 sim100 — 미수정 백로그 (사유별)

102-시나리오 시뮬레이션 확정 56건 중 코드로 안전하게 고친 항목은 커밋
`5c2a784`(1/2) + 후속 배치에서 처리. 아래는 **의도적으로 보류**한 항목과 사유.

## A. Auth Phase 3 / 익명-Auth 한계 (룰 단독 불가 — 정식 Auth 마이그레이션 필요)
- **#7 (P0-3)** 임의 인증 사용자가 타 user 문서 화이트리스트 필드 변조 + 전면 public read.
- **#10 (P0-2)** `senderIsBrand=true` + 위조 senderName → '공식 발송인' 사칭. 룰에서
  하드 차단 시 정상 Brand 발송도 막혀 불가. authUid owner-scope (firestore.rules.phase2)
  cutover 가 근본.
- **#14** brand_zones.redeemedCount griefing 증분. **#31** redemptionCode world-readable
  수집. **#32** adminFetchAllUsers 무인증 over-read.
- **#33/#34** Brand self-promote — 본 빌드에서 isBrand 를 화이트리스트에 넣어 Brand 영속을
  복구했으나(=client-writable), 이는 anon-auth 상 Brand 가 이미 client 티어라는 기존 현실의
  연장. Premium 은 의도적으로 화이트리스트 제외(결제 게이트 유지). 근본 차단 = Phase 3 +
  서버 entitlement 검증.
→ 공통 트랙: `docs/AUTH_MIGRATION_DESIGN.md` Phase 3 cutover. 코드 밖 BLOCKER ②.

## B. 운영/구성 (코드 아님)
- **#12 (P0-4)** 코드 완화는 적용(로컬경로 저장 차단). 정상 이미지 발송엔 Firebase Blaze +
  `--dart-define=FIREBASE_STORAGE_ENABLED=true` 주입 필요.
- **#20 (P2)** Admin 등급변경/차단이 deployed rules 에 막혀 403 — `isPremium` 을 화이트리스트에
  넣으면 무료 Premium 승급 구멍이라 불가. 근본 = admin custom-claim Cloud Function(Phase 3).
  현재는 Firebase 콘솔로 운영. UI 데드버튼 안내는 후속 UX 라운드.

## C. 결제-크리티컬 — 회귀 위험으로 보류 (기존 RC/스토어 보호 존재)
- **#25 (P2)** ExactDrop 멱등성(claim dedup) — RC/스토어가 consumable replay 를 1차 차단 중.
  트랜잭션ID 스레딩이 실 결제 경로를 건드려 위험 → 별도 검증 라운드.
- **#15 (P2)** purchase_service `_setError` 한국어 하드코딩 14언어화 — 광범위 i18n 리팩터.

## D. i18n 키 추가/플러밍 (기능 영향 없음, 후속 i18n 배치)
- **#17/#19/#27** premium_screen/premium_gate 의 koEn 12건 + ₩4,900/₩15,000 하드코딩 가격을
  `localizedPriceFor` + 14언어 키로. 위젯별 `purchase` 주입 + 신규 키 필요.
- **#46** main_scaffold 신규 사용자 발송 게이트 coachmark koEn → 14언어 키.

## E. P3 autosend — 회귀 위험 대비 가치 낮음
- **#40/#42/#43/#44** auto-drop 마커 persistence/status/markSeen/trigger 타이밍. 지도·발급
  로직을 건드려 regression 위험이 P3 가치를 상회 → 후속 전용 라운드.
- **#45** 발송자 픽업/redeem 실시간 알림 = FCM 도입(post-launch 로드맵).

## F. 기타
- **#22 (P2)** Brand auto-zone ROI 미집계 — brandInsights 합성 확장 필요(중간 규모).
- **#30 (P2)** banned fail-closed + secure 영속 — 절반 구현 시 정상 사용자 오차단 위험,
  서버 강제(Cloud Function)가 근본 → Auth 마이그레이션 트랙.
- **#50 (P3)** picked-id Set FIFO cap — eviction 시 중복 픽업 재허용 부작용, 트리거 임계
  (5천+ 픽업) 비현실적 → 보류.
- **#29 (P2)** 임시비번 1회용화 — 즉시 폐기 시 변경 완료 전 앱 종료하면 잠금 위험. 강제
  변경 화면 게이트와 함께 설계 필요. (#52 실패카운터 리셋 + #51 SecureClock 은 적용됨.)
- **#53 (P3)** 초대 크레딧 대량발송 write 폭주 — 트리거 빈도 0, 시뮬레이션도 미수정 권장.
