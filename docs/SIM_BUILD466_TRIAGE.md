# 시뮬레이션 결과 트리아지 (Build 466 → 467, 2026-06-14)

8-도메인 페르소나 시뮬레이션(73 에이전트, 적대적 검증) → 65 발견 → 38 확정(P1 9/P2 24/P3 5).
아래는 **2차 코드 재검증 후 트리아지**. 적대적 검증조차 놓친 과장/무효를 걸러냄.

## ✅ 수정 완료 (Build 467)
- **P11 [실 버그] 리딤 코드 레이스** — `letter_read_screen.dart:90` refetch 가 `content.isEmpty` 일 때만 호출 → 본문은 있고 매장 코드만 map-sync mask 로 null 인 브랜드 쿠폰은 영영 refetch 안 돼 코드 박스 공백. 트리거에 '코드 누락 브랜드 쿠폰/교환권' 추가(`refetchLetterContentIfEmpty` 의 needsCode 는 이미 처리). 
- **P14 [방어] guest→로그인 정리 누락** — `setUser` isNewUser 가 guest 제외 → 게스트 세션 잔존이 새 계정에 누수 가능. `isFromGuest` 추가해 in-memory/prefs 정리 트리거 확장(isBrand OR-fallback 은 불변).

## ❌ 무효/과장 (적대적 검증이 놓침 — 2차 확인으로 기각)
- **P12 trial 30/day farming** — 무효. 신규 발송은 **Brand 전용**(compose:557 BrandOnlyGate). Free/Premium/trial 발송 불가라 send 한도 farming 무의미.
- **P19 스탬프 중복 적립** — 무효. `markLetterRedeemed:1982` 상단 `_redeemedLetterIds.contains` 가드로 letter 당 1회.
- **P28 zone 수량 0/음수** — 무효. 마법사:273 `maxR <= 0` 검증 이미 존재.
- **P27 zone 항상 30일** — 무효(오해). 마법사에 custom duration UI 자체가 없음. 30일 기본은 의도.
- **P211 giftExpiry prefs 미정리** — 사실상 무효. purchase_service resetForLogout 가 giftExpiry 관리.

## ⏸️ 구조적/기존 인지 (Auth Phase 3 게이트 — 신규 아님)
- **P16 followerCount IDOR** — ±1 바운드된 anon-auth 한계(review-bombing 차단됨).
- **P17/P215 brandAuthUid null → zone permissive** — **의도된 설계**(anon/legacy zone permissive, 정식인증 zone 만 소유자 보호). Phase 3 후 전체 보호.
- **P18 redemptionCode 평문 공개** — rules 에 문서화된 Phase 2 항목(subcollection 분리 예정).
- **P213 isBrand self-promote** — anon-auth client tier 구조적 한계.
- **P214 클립보드 강제종료 잔존** — 문서화된 한계(lifecycle observer 로 best-effort).
- **P15 [주의] isBrand 환불 후 유지** — RC 환불 시 `_pendingAuthoritativeDowngrade` 미설정 → syncPremiumStatus OR-fallback 이 isBrand=true 유지. ⚠️ 진성 우려지만 **NN1 client-Brand(결제 없이 가입시 Brand 선택)와 RC-refund-Brand 를 구분 불가**(둘 다 RC isBrand=false) → 무조건 authoritative 하면 정상 signup-Brand 강등. **서버 entitlement(Phase 3) 없이는 클린 수정 불가.** 정식 IAP 등록 + RC webhook 후 재검토.

## 🔻 저우선 (비활성/마이너 — 백로그)
- **P216~221, P34 v5_preview/* i18n** — `/v5_preview`는 일반 동선 밖 프리뷰 화면. 정식 화면 아님.
- **P222 settings koEn** — koEn 으로 이미 양언어 처리(미승격일 뿐).
- **P21/P31 픽업 시트 빈 미리보기** — 본문 없는 브랜드 쿠폰 edge. P11 refetch 와 함께 대체로 완화.
- **P22/P23 TTL 표기/2h 자동완료** — 설계 선택(데이터 정합엔 문제 없음).
- **P24/P26 canUseInterestFilter Brand 제외 / trial 1km** — 마이너 정책 일관성.
- **P29 마법사 Step2 검증** — Step2 는 모드 선택뿐(항상 유효).
- **P33 zone 목록 deactivate 후 stale** — IndexedStack keep-alive 시 새로고침 지연. resume 새로고침 추가 검토.
- **P224 나침반 stale letter** — 타 유저 소진 직후 edge.
- **P212 Brand 다운그레이드 _trialExpiry** — P15 와 동일 구조 영역.
- **P35 zone seen-set 재설치 시 중복** — 재설치 시 auto-drop 1회 재노출(영향 경미).

## 총평
적대적 검증을 거쳤음에도 38건 중 **진성 출시차단(P0)=0**. 실 수정 가치 2건(P11/P14)만 코드 반영. 나머지는 무효(5)·구조적 Phase3(6)·비활성/마이너(다수). **Build 461 이후 누적 수정으로 코드 견고도는 높은 수준** — 남은 진성 이슈는 대부분 anon-auth 구조(Phase 3) 또는 정식 IAP 등록 의존.
