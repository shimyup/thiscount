# SESSION HANDOFF — Build 473 (2026-06-14)

> 새 세션 시작 프롬프트: **"SESSION_HANDOFF_BUILD_473.md 읽고 이어서 진행"**

## 현재 상태
- **브랜치**: `launch-readiness-build411` (PR #150) · 작업본 = `f9728c9` (1.0.0+473) · **working tree clean**
- **품질**: `flutter analyze` 클린 + **152 테스트** 통과
- **TestFlight**: Build 472 (`f43d7809`) VALID 까지 업로드됨. **⚠️ Build 473 은 아직 미배포** (커밋·push 만 됨)
- **Firebase 배포 계정**: **ceo@airony.xyz** (shimyup@gmail.com 아님 — lettergo-147eb 권한 없음). firebase deploy·콘솔은 ceo@airony.xyz 로.
- **백업 태그**: v461~v473 (최신 `v473-fab-ai-color`)

## ⏭️ 즉시 다음 작업 (사용자 승인 대기 중)
**수집첩 받은 메시지 재디자인** — 목업 제시 완료, 사용자가 "이대로 구현할까요?" 답 전에 새 창 전환 요청. 새 세션에서 **사용자에게 진행 여부 먼저 확인** 후 구현:
- **Free/Premium 보낸 탭 제거**: `inbox_screen.dart` `_wantTabLength()`(585) — 현재 Free=2[받은/보낸], Premium=3[받은/보낸/DM]. → Free=1[받은], Premium=2[받은/DM]. `_buildTabBar()`·TabBarView children(1121~1230)·`_ensureTabLength` 분기 동기화 필수(불일치 시 length assertion 크래시).
- **받은 카드 가시성 개선** (공용 `_LetterCard` 또는 `_ReceivedTab` 카드): 카테고리 좌측 색바(할인=coral/교환=teal-lime/홍보=gray) + 우측 **'사용하기'** 버튼(쿠폰 사용 동선) + 사용완료=흐림·취소선 + 큰 업종 이모지 아바타.
- 카테고리 필터는 하단 바 유지(Build 466).
- ⚠️ 시각 변경이라 구현 후 **TestFlight 배포 → 실기 확인** 루프 필수.

## 이번 세션(Build 461→473) 누적
- **461-462**: 브랜드 운영 5건(zone관리/숫자단일화/재발송/redeem귀속/팔로워) + 보안감사 + 첫인상 i18n. **firestore:rules 배포 완료(ceo@airony.xyz)**.
- **463**: brand 화면 i18n 완결(brand/onboarding koEn=0) + `docs/LAUNCH_GATE_ACTION_PACKAGE.md`(비코드 출시 BLOCKER 5건).
- **464-465**: 디자인 a11y(터치 44pt) + UX 상호작용 갭(zone 스피너/발송 햅틱).
- **466**: 실기 피드백 6건(접이식 닫기/draft 재출현 근본수정/수집첩 필터하단·사장님카드 겹침/계정전환 점검).
- **467**: 8-도메인 시뮬레이션(38확정→진성 2건 P11 리딤코드레이스/P14 guest정리). `docs/SIM_BUILD466_TRIAGE.md`.
- **468-469**: UI 단순화(목업 승인 기반) — 수집첩 상단 5단→1단 헤더 / Brand 캠페인 히어로카드→컴팩트 발송 헤더.
- **470**: **캠페인 발송 3단계 마법사 통일**(혜택→대상→확인). ComposeScreen 본문을 IndexedStack 3단계 재배치(발송로직·picker 100% 재사용). 답장은 단일스크롤. 진입점 전부 ComposeScreen 통일.
- **471**: 2단계 목적지 4개 이름+14언어(매장근처/국가선택/랜덤국가/위치지정) + 마법사 chrome 14언어.
- **472**: 캠페인 작성 '오늘의 영감' 제거 + AI 생성 버튼 가시성(텍스트→칩).
- **473**(현재): 캠페인 하단 FAB 제거 + AI 생성 버튼 색 teal→**gold**(가독성).

## 작업 규칙 (이 프로젝트 패턴)
- 빌드/배포: 반드시 `./scripts/release_to_testflight.sh` (백그라운드 실행 권장) — 끝나면 .env.local 자동 원복, working tree clean 확인. raw flutter build 금지.
- 커밋: 한국어 + `Build NNN` 프리픽스 + `Co-Authored-By: Claude ...`, 백업 태그 `vNNN-슬러그`, push origin launch-readiness-build411.
- 검증: 매 빌드 `flutter analyze` 클린 + `flutter test`(152) 필수.
- **i18n**: 신규 사용자 노출 문자열은 `_t({...})` 14언어(ko/en/ja/zh/fr/de/es/pt/ru/tr/ar/it/hi/th). koEn 은 ko/영어 2언어뿐 — 첫인상 동선엔 금지. 기존 getter 재사용 우선.
- **UI 변경은 목업(visualize show_widget) 먼저 → 승인 → 구현 → TestFlight → 실기 확인** 루프.
- 시뮬레이션: Workflow 툴로 멀티에이전트 + 적대적 검증. 2차 코드 재검증으로 과장 기각.

## 출시 게이트 (코드 밖, 사용자 영역 — `docs/LAUNCH_GATE_ACTION_PACKAGE.md`)
코드 출시준비는 사실상 완료(analyze0/152테스트/rules배포/결제배선완비). 남은 병목은 비-코드:
① 문서 호스팅(privacy/terms/location_terms → thiscount.io) ② 방통위 위치기반사업 신고(emsit.go.kr) ③ 실 IAP 상품등록 + RevenueCat 매핑(현 BETA_UPGRADE_SIMULATOR) ④ App Store Privacy Label ⑤ Auth Phase 3 cutover(런북 `docs/AUTH_PHASE3_CUTOVER_RUNBOOK.md`).

## 보류/구조적 (Phase 3)
- anon-auth IDOR(redemptionCode 평문/임의 카운터/isBrand self-promote/zone permissive) = 서버 entitlement 없이 클린수정 불가. `docs/SIM_BUILD466_TRIAGE.md` 참조.
- 디자인 백로그: coupon(#FF4D6D)=error 동일색 / textMuted ~4.7:1 경계 — 전역토큰이라 실기 시각검증 필요.
- 지도(탐험) 화면 단순화: 스크린샷 기반 권장(블라인드 변경 회피).
