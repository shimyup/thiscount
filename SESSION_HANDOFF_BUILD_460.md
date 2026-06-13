# SESSION HANDOFF — Build 460 (2026-06-13)

> 새 세션 시작 프롬프트: **"SESSION_HANDOFF_BUILD_460.md 읽고 이어서 진행"**

## 현재 상태
- **브랜치**: `launch-readiness-build411` (PR #150) · main = `0a520ba` (1.0.0+460) · working tree clean
- **TestFlight**: Build 460 **state=VALID**, Internal 그룹 배포됨 (456~460 연속 VALID)
- **품질**: `flutter analyze` 클린 + **149 테스트** 통과
- **백업 태그**: v451~v460 (최신 `v460-key-visual`)
- **firebase 룰**: write-once(redeemedAt/codeRevealedAt) + authUid 화이트리스트 **배포 완료** (lettergo-147eb)
- **시뮬레이터**: iPhone 17 (F87B6F89-…) — 디버그 빌드 설치됨(온보딩 국가화면에서 정지). 실행 스크립트 `/tmp/run_app.sh` (없으면 .env.local source + dart-define 12개로 재생성)

## 이번 세션(Build 446→460) 누적
- **브랜드 UX**: 할인코드 발급(미리보기·POS 가이드·입력란 하단 토글·기본 OFF) / 일반홍보 명칭 / 캠페인 2탭(보낸/받은DM)+그룹화+탭→코드 상세 / 인사이트·프로필 분리 하단탭 / 고정 매장 위치(+카테고리 표기, 골드 카드) / 관리자 패널 프로필 진입(ceo@airony.xyz)
- **유니크 강점**: 단골 스탬프(5회→epic 보상, 프로필 카드) + 친구 쿠폰 선물(코드 공유→수집첩 🎁 수령) + 관심 카테고리 픽업 필터(Premium, 지도 🔎)
- **시뮬레이션 3회**: 브랜드 100(47건) / 3-티어 96(40건) / 페르소나 6관점 — P0·P1 전부 수정(대량발송 "1개만"=precise 오인 P0, 인박스 탭 크래시, ExactDrop 무료우회, 매장주변 기본목적지, 체험 쿨다운 면제, DM 정직화, 픽업 미리보기 등)
- **온보딩 2단계**: 가입 전 3장 + 로그인 후 티어별 투어(TierTourScreen, Brand/Premium/Free 각 3장)
- **UI 다이어트**: 안내카드 dismiss / 빈상태 게이트 / 국가바 줌 게이트 / 프로필 '내 기록' 접이식 / 캠페인 히어로 1카드 / **3스텝 발송 마법사**(BrandQuickSendWizard — 히어로 CTA·투어 진입, 고급모드=기존 compose)
- **키비주얼(460)**: 가입 계정카드(틴트 원+그라디언트) / 브랜드 프로필 히어로(76px+매장명 메인) / 지도 픽업링 단독 위계+로고↑
- **신규 파일**: brand_stamp.dart, stamp_cards_row.dart, gift_code.dart, tier_tour_screen.dart, brand_quick_send_wizard.dart, brand_verification_sheet.dart, content_moderation.dart

## ⚠️ 미완(이번 세션에서 중단된 것)
- **Build 460 시각 검증 미완**: 키비주얼 3종(가입 카드/브랜드 히어로/지도)을 시뮬레이터로 확인하려던 중 종료. 앱은 온보딩 첫 화면에 떠 있음(prefs 초기화돼 brandtest1 세션+투어 seen 리셋된 상태일 수 있음)

## 다음 우선순위
1. (선택) Build 460 실기 확인 — 가입 계정카드·브랜드 히어로·픽업 링·3스텝 마법사 E2E
2. **코드 밖 출시 BLOCKER**(사용자 영역): 방통위 위치기반사업 신고(emsit.go.kr) · privacy/terms/location_terms thiscount.io 호스팅 · App Store Privacy Label · 실 IAP 상품 등록(현 BETA_UPGRADE_SIMULATOR) · Auth Phase 3 STEP2-4(바인딩률 95%→cutover, 런북 docs/AUTH_PHASE3_CUTOVER_RUNBOOK.md)
3. 페르소나 백로그(docs/PERSONA_ANALYSIS_BUILD457.md): 서버 집계 필요 항목(스탬프 임계값 커스텀/사장측 단골 지표/시간축 인사이트/zone 관리목록/재발송 버튼/다지점) + i18n 대량(국가명 145건/결제오류/koEn→14언어 승격)
4. 시뮬레이션 백로그 P2/P3: docs/TIER_SIM_BUILD452.md · docs/BRAND_SIM100_BUILD449.md

## 작업 규칙(이 프로젝트 패턴)
- 빌드: 반드시 `./scripts/release_to_testflight.sh` (raw flutter build 금지) — 끝나면 .env.local 자동 원복
- 커밋 메시지 한국어 + Build NNN 프리픽스, 백업 태그 vNNN-슬러그, push origin launch-readiness-build411
- 검증: flutter analyze + flutter test 필수, 시뮬레이터 검증 시 Chrome 포커스 탈취 → `killall "Google Chrome"; osascript Simulator activate`
- iOS 시뮬레이터 텍스트 입력은 computer-use로 불가(알려진 제약) — 클립보드/키 이벤트도 불안정
