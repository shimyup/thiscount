# 세션 핸드오프 — Build 445 (2026-06-07)

새 창에서 이 문서를 먼저 읽고 이어서 시작하세요. (전체 맥락은 auto-memory `MEMORY.md` 에도 있음)

## 현재 상태
- **브랜치**: `launch-readiness-build411` (PR #150 계열)
- **버전**: `1.0.0+445` — main commit `8463c13`
- **TestFlight**: Build 445 업로드됨 (VALID, Internal 그룹). 빌드 435~445 누적 업로드.
- **빌드/배포**: `./scripts/release_to_testflight.sh` (analyze+test→archive→altool→Internal 추가→.env 원복, 비대화형, ASC 키 `~/private_keys/AuthKey_PPC3B3JS5V.p8`).
- analyze 클린 + 139 테스트 통과 상태.

## 이번 세션(435~445) 한 일 — 전부 TestFlight 출시됨
- **435**: 인박스 카드 paint 크래시(비균일 Border+borderRadius) 수정 → 카드 본문 정상 렌더 / 프로필 타이틀-아바타 겹침 해소.
- **436**: 지도 픽업 팝업 깨진 이미지 → 업종 이모지 플레이스홀더.
- **437**: 사용자 피드백 6건 — 페이월 반경viz 정리 / Brand 캠페인 카드 compact / 특급발송 per-country 패널 노출 / ExactDrop 자동충전 best-effort / 공식발송인 배지 / 지도 줌 +/- 버튼.
- **438~440**: 온보딩 페이월 한 화면 압축 + 텍스트/viz 좌우 배치 + 좁은기기(390pt) 글씨 축소(iPhone 16e 검증).
- **441**: 100-시뮬(68확정) 안전 코드수정 6건 — trial 배너 production 숨김 / trial 카드 결제CTA / Gmail farming canonicalize / production cold-start trial 소실 / trial 투명성 배지 / Brand '월10,000통' 카피.
- **442**: resume 예약 다운 재평가 / trial+paid 정리 / cold-start 강등 flag.
- **443**: revenueCatWebhook 구독 만료/환불 서버 권위 강등 + client 수용(_restoreProfileFromServer revoke 마커). **functions/index.js 코드 준비됨 — 배포 대기.**
- **444**: 앱 기본 폰트 → **Pretendard**(assets/fonts/*.otf, OFL). 2026 트렌드 목업 3종(docs/mockups/2026_*.png — Pretendard+Liquid Glass+Bento).
- **445**: ExactDrop 발송 100m 거리가드 제거(매장 위치 고정 발송 차단 해소).

## 시뮬레이터 테스트 결과
- **구매 PASSED**: 트라이얼→구독시작하기→테스트모드 확인시트→구매(테스트)→Premium 활성화→트라이얼 배너 사라짐(정식 전환).
- **발송**: ExactDrop 100m 블로커 수정. 전체 Brand 발송 tap-through 미검증(Brand 진입이 ₩99,000 결제 게이트 + 시뮬 다이얼로그 클릭 불안정).
- 실기기 "여비패두두두두두두두"=iPhone 13 Pro Max state=unavailable → flutter 직접배포 불가, **TestFlight 가 실기기 경로**.

## 다음 할 일 (우선순위)
### A. 사용자 확인 대기
- **대량발송**: 실기기 Build 445 에서 재확인. 여전히 안 되면 증상(버튼 회색/에러문구/무반응) 받아 진단.
- **매장 위치 고정**: "기본 매장 좌표 저장"(매번 재지정 없이) 의미였는지 확인 — 맞으면 기능 추가.

### B. 코드 외 '실 배포' 영역 (사용자 자격증명 필요)
- `firebase deploy --only functions:revenueCatWebhook` + RC 대시보드 **EXPIRATION/RENEWAL/PRODUCT_CHANGE/UNCANCELLATION** 이벤트 전송 활성 (functions/README) → #2 매출무결성·#6 크레딧 영속 발효.
- **Auth Phase 3 cutover**(P0 신규기기 로그인): firestore.rules(authUid additive 존재)+rules.phase2 배포 + `AUTH_BIND_ENABLED=true` + 실기기 검증 (docs/AUTH_PHASE3_CUTOVER_RUNBOOK.md).

### C. 디자인 후속 (사용자 판단 — 목업 제시됨)
- **Liquid Glass**(BackdropFilter 탭바/시트/지도컨트롤) + **Bento 프로필** — docs/mockups/2026_*.png 참고. 적용 시 실기기 blur 성능·가독성 검증 필요.

### D. 100-시뮬 잔여 P2/P3 (docs tasks/w5bl16ox1.output, 백엔드 필요분 제외)
- #9 trial 그리핑(server OTP) 등.

## 주의/교훈
- **시뮬 클릭**: simctl 스크린샷 y추정이 ~40px 빗나가 다이얼로그 클릭 반복 실패 → **mac `screencapture -R win` 으로 측정**(screen = 창origin + capture_px/2)해야 정확. 창 타이틀바 ~38pt 오프셋. 불필요 시뮬 shutdown(멀티 부팅 클릭 간섭).
- **release 스크립트**가 .env.local BETA 플래그 임시 변경 후 원복 — 중단 시 .env 확인.
- 빌드번호는 매 출시 +1 (현재 445 다음 446).
- 미커밋 인박스 리워크(_InboxQuickStatusCard)가 inbox_screen.dart 에 이전 세션부터 섞여 있었음(435 에서 함께 커밋됨).
