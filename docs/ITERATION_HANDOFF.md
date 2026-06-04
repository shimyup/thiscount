# 반복 수정 핸드오프 (실기기 무오류까지 / 세션 연속)

> 이 문서는 **세션이 바뀌어도 작업이 끊기지 않게** 하는 단일 진실원이다.
> 새 세션은 **이 파일을 먼저 읽고** → 다음 미완 항목을 수정 → 검증 → 커밋 →
> 이 문서를 갱신하라. 목표: 실 배포 전까지 실기기 테스트 무오류.

## 🆕 새 창(새 세션) 진입 방법
> 이 저장소(`/Users/shimyup/Documents/New project/Lettergo`)에서 새 Claude Code
> 창을 열고 아래 한 줄만 입력하면 동일 루프가 이어진다:
>
> **"docs/ITERATION_HANDOFF.md 읽고 루프 절차대로 반복 수정·검증·커밋·빌드 계속 진행"**
>
> (클라우드/원격 스케줄은 불가 — flutter test·git push·TestFlight 빌드가 이 Mac +
>  Xcode + 서명키를 요구하므로 반드시 **로컬 새 세션**이어야 함.)

## 현재 상태 (2026-06-04 갱신)
- 브랜치: `launch-readiness-build411` (PR #150). main 아님.
- 최신 커밋: `c845eac` (UX 개선 스윕: DM 탭 발견성 + UI 대비 + draft 검증 + 데드코드).
- 백업 태그: `v427-pre-ux-overhaul` (`98a0716`, origin). 되돌리기 `git reset --hard v427-pre-ux-overhaul`.
- 빌드: pubspec `1.0.0+428`. TestFlight **417~428 업로드됨**(428=VALID+Internal, Delivery `06310a94-7257-4e57-9e08-8fe518fc38ef`). 다음 빌드 429.
- 검증 게이트(매 수정 후 필수): `flutter analyze lib/` 무경고 + `flutter test` 전체 통과(현재 **139**).
- ⚠️ flaky 없음.
- 누적 진행: sim100 + iter1~5 + device + sim-fresh + sim-fresh2 + sim-crosscut + **WCAG 라운드(접근성 백로그)**.

## 루프 절차 (매 iteration)
1. 이 문서의 "남은 백로그"에서 **코드로 안전히 고칠 수 있는** 상위 항목 1~5개 선택.
2. 해당 file:line 을 Read 로 확인 → 수정.
3. `flutter analyze lib/` 무경고 + `flutter test` 통과 확인(필수).
4. 의미 단위로 커밋(메시지 끝 `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`), 사용자 확인 없이 push 가능(사용자가 반복 진행 승인함).
5. 이 문서의 체크리스트 갱신(✅ 표시 + 커밋 해시).
6. 5~8개 수정 누적되거나 P0/P1 일괄 처리 시 → pubspec build++ 후 `release_to_testflight.sh` 로 TestFlight 빌드(실기기 테스트용) + `asc_assign_to_internal.py <build>` 로 Internal 그룹.
7. 백로그의 코드-fixable 항목이 모두 소진되면 → 새 sim(워크플로우) 1회 돌려 신규 결함 발굴 → 백로그에 추가.
8. **구조/배포/결제 영역(아래 ⛔)은 코드 블라인드 수정 금지** — 보고만, 사용자/배포 대기.

## 컨텍스트 한도 시 연속
- 컨텍스트가 차면: 이 문서를 **최신 상태로 갱신**하고 마무리 → 새 세션이 동일 절차로 이어감.
- 새 세션 진입점: "docs/ITERATION_HANDOFF.md 읽고 다음 미완 항목 반복 수정" 라고만 하면 됨.

---

## ✅ 이번 라운드 수정 완료 (sim100, commits `5fb1557`·`b2655ea`)
- [x] **P0** redemptionCode Firestore 미전파 (저장맵+파싱2+refetch+rarity보존) `5fb1557`
- [x] **P1** 본문 최소 20→10 회귀(검증+14언어 문구) `5fb1557`
- [x] **P1** auto-zone '📍매장반경' 칩 제거 `5fb1557`
- [x] **P1** 프로필 비번변경 self-lockout (verifyCurrentPassword+validatePassword) `5fb1557`
- [x] **P1** 거주국가 EU16 연령동의 무단승격 가드 `5fb1557`
- [x] **P1** inviteClaims 룰 추가(배포 필요) `b2655ea`
- [x] **P2** 비번 hint 6~12→8~20 + fr/it 오역 `5fb1557`
- [x] **P2/P3** OTP autofillHints+digitsOnly `5fb1557`
- [x] **P2** premium 비교표 ₩ 하드코딩→RC priceString `b2655ea`
- [x] **P2** zone auto-drop 쿠폰 rarity roll `5fb1557`

## ⛔ 미적용 — 구조/배포/결제 (코드 블라인드 수정 금지, 보고만)
- **P1** 구독 다운그레이드 권위 ×2 (purchase_service.dart:826 / app_state.dart:2727): `_keyIsBrand` cross-module stale. 실 RC/결제 **디바이스 테스트 후** 같이 수정.
- **P1** letters.status world-writable 검열 IDOR (firestore.rules:71-80,225): anon-auth → rules.phase2 owner-scope 필요.
- **P1** brand_zones redemptionCode world-readable (firestore.rules:324): subcollection/Cloud Function 필요(배포).
- **P1** 초대 크레딧 *증가* grant 403 (anti-self-mint): 서버/webhook 영역.
- **P1** deleteMyData(GDPR 물리삭제) 미배선 (auth_service.dart:1536): Phase3/배포.
- 배포 대기: `firebase deploy --only firestore:rules` (inviteClaims + merchant_interest + authUid).

## 🔧 남은 백로그 — 코드로 안전히 고칠 수 있는 후보 (다음 iteration 대상)
> 전체 원본: `/tmp/sim100_backlog.txt`(256줄). 아래는 코드-fixable 우선순위.
- [x] **P2** OTP fallback 카드 한국어 하드코딩 → authBetaCodeFallback 14언어 (auth_screen.dart:2454) ✅ Build 417
- [ ] **P2** ExactDrop consumable 환불 webhook 미처리(REFUND/CANCELLATION) (functions/index.js:466) — *배포 동반*
- [ ] **P3** mustChangePassword dead flag (임시비번 강제변경 미강제) (auth_service.dart:285)
- [ ] **P3** Trial 다운그레이드 효력일 now+30일(즉시해제 안 됨) (purchase_service.dart:1241)
- [ ] (이하 P2/P3) inbox/roi/i18n/chaos 도메인 findings — `/tmp/sim100_backlog.txt` 참조해 코드-fixable 만 선별 처리
- [ ] 코드-fixable 소진 시 → 새 sim 워크플로우 1회 → 신규 백로그 보충

## 참고
- sim100 원본 결과: task `wmodim4vb` output (P0 2/P1 15/P2 22/P3 25, 102 시나리오).
- 빌드/업로드: `./scripts/release_to_testflight.sh` (BETA 모드 자동, .env.local 자동 원복).
- 그룹 재할당(ASC 처리 지연 시): `python3 scripts/asc_assign_to_internal.py <buildNum>`.
- 크레덴셜: `~/private_keys/AuthKey_PPC3B3JS5V.p8` (정상).

## Iteration 1 (2026-06-03) — commit 대기
- [x] P2 compose 카운터/버튼 trim 길이 기준 통일 (compose_screen.dart:567)
- [x] P2 replyToLetter 서버측 acceptsReplies 가드 (app_state.dart:9622)
- [x] P3 inbox _industryKeywords 'IT' 단독 키워드 제거 (inbox_screen.dart:271)
- 남은 코드-fixable 후보(다음): inbox _sortFollowedFirst 죽은쿠폰 정렬, '안읽음 점프' 인덱스, premiumPricePerMonth 9언어, compose dead-code 정리(신중), 만료판정 SecureClock 일관, 계정전환 draft 정리, 오프라인 아웃박스 guest 로그아웃 정리.

## Iteration 2 (2026-06-03)
- [x] P2 compose_draft + pending_letter_uploads 를 _clearUserScopedPrefs 에 추가 (계정전환/guest 로그아웃 cross-account 본문 누수 + 아웃박스 유실) (app_state.dart)
- [x] P2 inbox _sortFollowedFirst 가 죽은 쿠폰(만료/사용완료) 상단고정 제외 (inbox_screen.dart:878)
- TestFlight Build 417 = VALID + Internal 그룹 (Delivery 551848eb). 다음 빌드는 418.
- 남은 후보: '안읽음 점프' 인덱스 정합, premiumPricePerMonth 9언어, 만료판정 SecureClock 일관, compose dead-code 정리(신중), roi 비논리 카운트 보정, send_bulk 스낵바 N×M 수식.

## Iteration 3 (2026-06-03)
- [x] P2 premiumPricePerMonth 월 접미사 14언어 전체 현지화 (app_localizations.dart:16029)
- [x] P3 brand_insights 퍼널 절대수치 단조감소 clamp (redeemed>pickup 등 비논리 표시 차단) (brand_insights_screen.dart:187)
- 누적 8건 → Build 418 빌드 예정.
- 남은 후보: send_bulk 랜덤모드 스낵바 '0개 나라' 수식, '안읽음 점프' 인덱스, maxRedeems per-device, autozone dedup seen 신호, mustChangePassword(플로우-신중).

## Iteration 4 (2026-06-03)
- [x] P2 express+bulk 랜덤모드 성공 스낵바 '0개 나라' 수식 → count-only (compose_screen.dart:1631)
- [x] P2 '안읽음 점프' 인덱스를 표시리스트(뮤트필터+_sortFollowedFirst)와 동일 계산 (inbox_screen.dart:1391)
- TestFlight Build 418 = VALID + Internal (Delivery c2702f69).
- 남은 후보: maxRedeems per-device(구조-검토), autozone dedup seen 신호, roi 카드 redeemed>pickup, send_single auto-zone 5자 카피(auto-zone 제거로 무효일수도), i18n 잔여. 코드-fixable 거의 소진 → 다음 새 sim 고려.

## WCAG 라운드 (2026-06-04) — Build 424
> 메모리 `wcag_audit_2026_05_25` 백로그(Build 359 시점 280건)에서 코드-fixable·저위험 항목 처리.
- [x] P0 정적 AppColors.textMuted #5A5A5F(3.3:1 fail)→#7C7C82(≈5.0:1, 동적 팔레트 이미 채택값에 정렬) — **600+ 참조 일괄 대비 통과** `e1884b1`
- [x] P1 letter_read 첨부 Image.file 2곳 semanticLabel(Image.network 형제 parity) `e1884b1`
- [x] P0 닫기/뒤로 IconButton tooltip 12개(world_map/letter_detail_map/settings/premium/stamp_album/profile/auth/tower_popup/weekly_reflection/dm×2) `504167c`
- **미적용(시각검증 필요/보류)**: RTL `EdgeInsets.fromLTRB`→`EdgeInsetsDirectional.fromSTEB` 157곳(ar 레이아웃 — 시뮬레이터 RTL 시각검증 후 일괄) / teal(#B8FF5C)+white 대비 per-site(각 site foreground 개별 확인 필요, 다수는 tealInk 이미 적용).

## Sim-crosscut 라운드 (2026-06-04) — Build 423
> 8 교차관심사 lens(dispose누수/async race/firestore정합/error-swallow/null-bounds/계정전환누수/a11y/i18n) finder→적대검증 → **32 보고 / 31 확정 → 30 수정**.
- [x] P1 bulk/express 0통 발송 가짜성공 + phantom POS 코드 차단 (totalSent==0 가드 2곳) `48ff1c3`
- [x] P1 계정전환 prefs 누수 6키(compose_draft_brand/last_sent_content/축하/AI날짜/회고/welcome) + in-mem reset `48ff1c3`
- [x] P2 다이얼로그 TextEditingController 누수 7화면(신고/비번/SNS/계정삭제/아이디찾기/사업자등록 등) `d55b09d`
- [x] P2 Letter enum index 안전(_safeEnum)+tower hex 가드+BrandZone tryParse+letterType sync/parse+socialLink 정규화+login 재진입 `70ea415`
- [x] P2 구매 락 race — _startLoading bool + 6 buy 메서드 bail(ExactDrop 중복 grant/이중결제 차단) `22f6c35`
- [x] P2/P3 i18n 하드코딩 4건(koEn) + a11y(비번토글/내위치/기억하기/검색지우기 라벨 + 뱃지 가독) `0a3676f`
- TestFlight **Build 423 = VALID + Internal** (Delivery `a84aea82-c422-4f07-94ca-d86d429897be`). 다음 빌드 424.
- **미적용**: #29 닫기버튼 tooltip(보고 line 4157 stale — 파일 3555줄, 위치 불명확 → skip).

## Sim-fresh2 라운드 (2026-06-04) — Build 422
> 10-도메인 워크플로우(admin/onboarding/recommendation/geocoding/coupon-ai/storage-location/letter-model/map-camera/tower-streak-journey/penpal-progression) finder→적대검증 → **49 보고 / 36 확정 → 33 수정**.
- [x] P1 계정전환 누수 4건: admin Event Mode·속도/XP baseline/마일스톤집합/챌린지보상 `30f54c8`
- [x] P1 AI 추천 extraSignalCount category.key 정합 + score/topReason/extra SecureClock `30f54c8`
- [x] P1 지오코딩 null 캐시오염 차단 + 바우처 업로드 race + 발송게이트 업로드중 차단 `b756bb0`
- [x] P1 지도 '내 타워' 매칭 5.5km→500m + GPS(0,0) 차단 `b756bb0`
- [x] P2 Letter.fromJson expiresAt/redemptionExpiresAt _parseDateTime + 국경검문소 i18n `d7cb7bf`
- [x] P2 JourneyCard 합집합 + Hunt wallet redeemedAt 기준 사용집계 `d7cb7bf`
- [x] P2 AI 다이얼로그 controller 해제/빈입력 가드/garbage 응답 + 온보딩 더블탭 `fa5c572`
- [x] P2 Connectivity in-flight 가드 + SecureLocation heuristic OR + 레벨업 배너 구분 `8b21c48`
- [x] P3 SecureClock(ETA/도착마커) + 내타워(0,0) 가드 + totalRedemptions 필터 + 코치마크 누수 + 지오코딩 타임스탬프 + user_progress 문서 + admin ban 가드 `d28b982`
- [x] P3 데드코드(TranslationService/penpal_tier) 제거 + AI 429 안내 `cc51c9c`
- TestFlight **Build 422 = VALID + Internal** (Delivery `df4d6d1b-571e-4b99-bd17-e1effb8ead8b`). 다음 빌드 423.
- **미적용(보류, 사유)**: #9 admin special msg 한국어(admin=개발자 전용, 비-end-user) / #16 위치거부 UI 피드백(heuristic 은 #14 적용, 다중 launch 경로 UI 는 silent fail-safe 허용) / #24 온보딩 투어 한국어(비-ko 는 이미 자동 skip, 14언어 번역은 별도 大작업).

## Sim-fresh 라운드 (2026-06-04) — Build 421
> 9-도메인 워크플로우(dm/notifications/social/settings/progression/map/brand_zone/premium/profile/share) finder→적대검증 → **53 보고 / 46 확정 code-fixable** → **37 수정**.
- [x] P1 계정전환 in-memory 누수: _pendingDMCount/streak 부속/followingIds reset `d965825`
- [x] P1/P2 _clearUserScopedPrefs 키 대량 추가(pendingDMCount/tower/preferred/activityScore/notify_*/merchant_interest_*/following·followerIds 등) `d965825`
- [x] P1 followingIds 영속 (저장/복원) `d965825`
- [x] P1 로그아웃 시 NotificationService.cancelAll (A 알림 B 디바이스 발화 차단) `d965825`
- [x] P1 sendDM banned/차단 가드 + followUser 차단/자기자신 가드 `d965825`
- [x] P1/P2 SecureClock: 이미지한도/trial expiry/닉네임 쿨다운/빌링 fallback `340cc21`
- [x] P1 auto-zone 발송 쿼터 게이트 + Hunt wallet brand-scoped + XP km 백필 4/6 `4c01374`
- [x] P2 나침반 _isLetterConsumed + journey 합집합 + DM 텍스트보존/정렬 + 공유 grapheme `4c01374`
- [x] P2 설정 일일알림 권한반영 + zone seen-without-letter(bool 콜백) + DM 자동응답 배지 `aae5e35`
- [x] P3 월드뷰 마커 hasPickedUpCampaign + localizedPriceFor 빈문자 + 데드마커2 삭제 `aae5e35`
- [x] P1 XP 레벨 라벨 영어 매핑 + 지도 brand 배너 i18n `3246379`
- [x] P1/P2/P3 i18n 하드코딩(공유헤더/프로필카드/카테고리칩/tower편집) + 독·러 문법 `47eb8ff`
- [x] P3 약관링크 언어기준 + 알림 데드코드 + digest 문서정합 `07119ea`
- [x] P3 언어 변경 시 일일 리마인더 재예약 `5aecc39`
- TestFlight **Build 421 = VALID + Internal** (Delivery `094e2ac3-9a90-4d65-b66a-8d7f52ddc128`). 다음 빌드 422.
- **미적용(보류, 사유 기재)**: #3 timezone IANA(플러그인 의존 — flutter_timezone 추가 필요) / #16 followers 탭 항상 0(백엔드 follow-graph 부재 = 제품결정) / #17 sendExpressLetter ~80줄 데드(기능배선 vs 삭제 결정) / #21 languageCode 서버 미저장(rules 화이트리스트 미포함 → PATCH 403 위험 = 룰 동반) / #23 city-of-month 한국어(데이터모델 14언어화 大) / #29 베타확인 koEn(이미 영어 노출).

## Iteration 5 (2026-06-03) — Build 420
- [x] P2 인박스 '사용 완료' 가 만료쿠폰/general 정보성 letter 에도 markLetterRedeemed → 브랜드 redeemedCount 오염: UI 만료차단 스낵바 + general 서버 증분 제외 (inbox_screen / app_state markLetterRedeemed) `957a7e6`
- [x] P3 brand_insights 캠페인 카드 퍼널 단조감소 clamp (메인 퍼널과 통일) `957a7e6`
- [x] P3 nearbyLetters getter 가 maxReaders 도달/isBlocked 제외 (비-nearby 소진판정과 일관) `fd21869`
- [x] P3 픽업 거리검증 GPS 0,0 가드 OR + Null Island(<0.0001) 강화 (부분초기화 우회 차단) `fd21869`
- [x] P3 만료 카운트다운 DateTime.now()→SecureClock 4곳 통일 (letter_read_screen×2 / brand_insights×2) `b9137b5`
- [x] P3 inbox 혜택 빅텍스트 퍼센트 정규식 \d{1,2}→\d{1,3}, n<=100 (100% 무료 누락) `b9137b5`
- [x] P3 픽업 claim rollback 시 _pickedUpCampaignIds 복원 (latent 영구차단) `c5e8ea2`
- TestFlight **Build 420 = VALID + Internal** (Delivery `53a69722-38d3-4e2f-b5a9-469b3635e89f`). 다음 빌드는 421.
- 남은 후보: maxRedeems per-device(구조-검토), autozone dedup seen 신호, mustChangePassword(플로우-신중), findId/resetPassword enumeration 통일(서버연계), phone OTP dead branch. 코드-fixable 거의 소진 → 다음 새 sim 워크플로우 고려.

## 사용자 device 보고 수정 (2026-06-03) — 우선 처리
- [x] 비-지도 탭에서 지도 96px peek 노출 제거 → 탭 콘텐츠 전체화면 (main_scaffold.dart:304, _kMapPeek 제거)
- [x] 작성 메세지 '버리기' 후 재출현 — _saveDraft hasState 가 기본 선택국가만으로 brand draft 저장 → 빈 메세지도 '이어쓰기' 무한 재출현. hasState 를 닫기확인 hasContent 기준(대량/특송/타깃/특정국가/혜택정보)으로 정정 (compose_screen.dart:693)
- Build 419 빌드.

## UX 개선 스윕 (2026-06-04) — Build 428, commits `09f5b64`·`5645202`·`c845eac`
> sim100 의 UX 44 + 잔여 codeFixable 중 안전·고가치 항목 구현. 백업 태그 `v427-pre-ux-overhaul`.
- [x] **[핵심] Premium 인박스 DM 탭 노출** — 기구현 `_DMTab` 미배선이던 것을 [받은/보낸/DM] 3탭으로 배선(canUseDM). 이전엔 편지 열어야만 DM 진입(발견성 0). `09f5b64`
- [x] 받은 인박스 빈 상태 CTA '작성'→'지도에서 줍기'(비-Brand 막다른 진입 제거) + _isHuntFilter 제거 `09f5b64`
- [x] UI: 필터칩 라벨 ellipsis(#41) / 통계 화살표 어포던스 14pt(#38) / 통계 라벨 11pt textSecondary 대비(#39) `5645202`
- [x] draft 복원 시 비-Brand brand상태 무력화(#25, 다운그레이드 방어) `5645202`
- [x] 데드 파일 brand_comparison_sheet.dart 제거 `c845eac`
- **백로그(시각검증/대형/위험 — 미적용)**: 쿨다운 pill top:180 충돌(#13·#14, 시뮬 RTL/오버레이 시각검증 필요) / 통합 버튼 컴포넌트(#40, 大리팩터) / logout AppState.reset(#35, setUser isNewUser 로 이미 완화) / 지도 double move(#12)·arrivedAt 영속(#18, write 증폭 위험)·privacy toggle await revert(#33) / DM 홈/프로필 추가 진입점(인박스 탭으로 1차 해소) / express 토글 Free 분기 dead(무해).
- TestFlight Build 428 빌드 예정.

## Sim100-build426 풀스윕 (2026-06-04) — Build 427, commits `0432603`·`552dd9b`·이후
> 14-도메인 100-시나리오 워크플로우(task `w4uib6v4c`) + **시뮬레이터 런타임 실행(iPhone17)**.
> **115 보고 / 96 확정** (error 38 · ux 44 · ui 8 · member-flow 6). 대부분 Build 426 Premium-발송제거 회귀.
> 시뮬레이터: 앱 예외 0건 정상 부팅·온보딩 렌더 확인(/tmp/sim426_home.png).
- [x] **티어 가드**: replyToLetter Premium·Brand(#48) / acceptChatInvite+letter_read 'Start Chat' canUseDM 게이트(#20·#22·#23) / _selectExactDrop Brand 전용(#26)
- [x] **P0/P1 카피 모순(14언어)**: composeGate→답장(#0·#3) / welcomeTrialBody(#45) / towerBenefitsPremiumFeat2·3(#44) / composePhotoAttachDesc(#46) / purchase_service fallback(#29) / premium 비교표 발송행+DM행(#31) / premiumPremiumTestDesc·stateDmUnavailableFree(#5) / gpsSkipWarningBody (Premium/Brand)→(Brand)
- [x] **계정전환**: _justLeveledUp/_previousUserLevel reset(#6)
- [x] **UI**: 프로필 '오늘 발송' 카드 Brand 만(#1) / inbox 필터칩 터치타깃 44pt(#36) / auth 버튼 disabled 구분(#37)
- **false-positive/skip**: #7(_celebratedMilestones 이미 clear) / #42·#43(Free/Premium/Brand=영문 제품명) / #47(presetColors const) / #24(sendLetter Brand-only 화 시 답장 깨짐 → compose 게이트로 충분)
- **🟡 UX 개선 백로그 (44건, 사용자 우선순위 결정 필요 — '체크' 결과)**:
  - **핵심 테마 (P1·반복 다수)**: Free/Premium 의 발송 탭이 사라졌는데 **그들이 뭘 할 수 있는지(줍기/답장/DM) 안내 부재** + **Premium DM 발견성 제로**(편지 열기 전엔 노출 안 됨 = 전환 절벽). → 권장: 빈 인박스 상태에 "줍기·답장·DM" 안내 / 홈/프로필에 DM 진입점 / Free nav 가 비어 보이는 것 설명.
  - **구조/디자인 (기능 신설)**: DM 홈 화면 진입점, Premium screen 에 BrandOnlyGate 안내 상시 노출, 온보딩에 Premium XP/줍기 가치 설명.
  - **잔여 코드-fixable 후보(다음 iteration)**: brand_comparison_sheet(현 미사용=dead) 정리 / express 토글 premium 분기 dead 정리 / 일부 BrandInsights 주석 stale / map P2(쿨다운 pill 위치 top:180 충돌·경계 사라짐) / SNS URL 검증(#P3) / benefit 텍스트 복합포맷(#P3).
  - 전체 원본: task `w4uib6v4c` output (codeFixable 49·ux 44·restricted 3).
- TestFlight Build 427 빌드 예정.

## 🔴 사용자 device 2차 보고 (2026-06-04) — Build 426, commit `1cad767`+`0755910`
> 실기기 스크린샷 피드백 + 사용자 결정(AskUserQuestion 2회).
> **⚠️ 큰 제품 변경: Premium 신규 발송 기능 완전 제거 → 줍기 전용 재포지셔닝.**
- **사용자 결정**: ① Premium 발송 = 신규 발송만 제거(답장·DM 은 Premium 유지) ② Free/Premium 에는 발송 탭 숨김(발송=Brand 전용).
- [x] [게이팅] main_scaffold 하단 발송/캠페인 탭 Brand 에게만 노출 + `_openCompose` Brand 게이트(BrandOnlyGateSheet). compose initState: 신규발송=Brand전용/답장=Premium·Brand.
- [x] [카피 14언어] onboarding4Body(Premium 홍보 제거)·뱃지 Brand 만 / onboardingPremiumFeat3 발송→DM·Feat4 특급배송→커스터마이즈(이모지 ✈️→💬) / onboardingFreeFeat2 발송→줍기 / premiumValueFeature1~4 발송셀링→반경·쿨다운·DM·커스터마이즈 / premiumFeature3 발송→DM·Feature4 특급제거 / premiumFreeFeature2 발송→지도·수집(이모지 ✉️→🗺️).
- [x] [compose UX] #2 카테고리 활성색 구분(_categoryAccent: 일반teal/할인권gold/교환권pink) / #3 목적지 초기 활성색 제거(_destinationTouched) / #4 편지지 헤더 태그라인 제거 / #5·#6 '더많은옵션' 시나리오칩(정확좌표·글로벌대량) 중복 제거(_scenarioChip/_applyScenario* 삭제) / #7 사진첨부 일반 카테고리만.
- 또한 1차 device(`253af18`)의 '광고없음' 제거는 그대로 유지.
- **검증 후속 권장**: 실기기에서 (a) Free/Premium nav 에 발송 탭 사라졌는지 (b) Premium 답장·DM 정상 (c) Brand compose 5건 UX (d) 온보딩/페이월 카피 일관성.

## Sim-fresh3 라운드 (2026-06-04) — Build 425, commit `423f1a2`
> 10-도메인 finder→적대검증 워크플로우 (task `we4r1mv70`). **68 보고 / 50 확정 code-fixable** → 안전·고가치 **13건 수정** + false-positive 3 제외.
- [x] #1·#2 compose draft 에 attachRedemptionCode·brandUniquePerUser 보존 + hasState 반영
- [x] #0·#3 _clearDraft 에 _imageFilePath·_voucherImageLocalPath·브랜드 토글 clear
- [x] #35·#36 compose 엔트리 게이트(auto-zone·단건) `hasRemainingDailyQuota`→`canSendByQuota`
- [x] #6·#9 unreadCount 뮤트 브랜드 필터(뱃지 vs 리스트 일치)
- [x] #19 ProfileScreen 언어 변경→일일 리마인더 재예약
- [x] #44 DM 버튼 canUseDM 렌더 게이트 / #45 sendDM 자기차단 / #46 follow 자기차단
- [x] #11 letter currentPositionAt 음수/0 div 강화 / #13 arrivalTime _parseDateTime
- [x] #10 world_map 오버랩 반경 200m→pickupRadiusMeters
- [x] #7 redemption auto-scroll box 렌더조건 일치 / #8 '사용완료' letter 만료도 차단
- [x] #29 AI 쿠폰 생성 6키 4→14언어
- **false-positive 제외**: #4(voucher 실패경로 이미 null 처리·Build414) / #43(방어권 증가스낵바 중복방지=의도) / #49(presetColors=const)
- **잔여 백로그(다음 iteration / 신중·구조·검증필요)**:
  - #14 reconcileLetterStatuses _sent ghost — worldLetters 미완전 로드 시 활성 letter 오인 위험 → **신중**(거짓 reconcile 주의)
  - #16 PremiumGateSheet 가격 비반응(offerings late load) / #17 다운그레이드 스케줄 후 피드백 / #18 비교표 stale fallback — premium **display**, 검토 후 가능
  - #20 로그아웃 후 프로필 이미지 in-mem 잔존 / #21 lastKnownLocation 계정전환 / #22 계정삭제 부분실패 / #23 GDPR export 필드 — profile/settings, 일부 **배포·GDPR** 연관
  - #24·#25 OTP resend 에러표시/fallback 코드 — auth **신중**(검증 필요)
  - #30 v5_preview 한국어 하드코딩 — **dev 라우트(/v5_preview)**, end-user 비노출 → 저우선
  - #31 brand_insights koEn 255곳 / #34 캠페인 redeem count 본인만 — **대규모/구조**
  - #37~#42 brand_insights/ExactDrop 표시 정합(clamp 이미 적용분 多) — 검토 후 선별
  - #47 _DMTab 미배선 — **제품 결정**(인박스 DM 탭 노출 여부) = 사용자 판단
  - #5 bulk 토글 OFF 시 express 동반 OFF — 의도적 방어(현 동작 defensible)

## ✅ 사용자 device 보고 추가 (2026-06-04 처리완료, commit `253af18`)
> Build 419 실기기 보고 3건. 모두 코드-fixable, 처리 완료.

1. [x] **[device] '광고 없음/제거/ad-free' 문구 제거** — 실측 결과 문구의 실체는 "홍보 안 보냄"이 아니라 **'광고 없음/제거' (ad-free)** 였음. 앱은 광고 SDK 미사용(REST-only)이라 공허·모순(쿠폰=콘텐츠) 문구 → 4곳 제거:
   - `onboardingPremiumFeat4` (app_localizations:17139) "광고 제거" → 페이월 정본 정렬 "캐릭터 커스터마이즈" (14언어)
   - `premiumGateAssurance` (10394) "언제든 해지 · 광고 없음" → "3일 무료 체험 · 언제든 해지" (14언어)
   - `premiumTrustLine` (16010) 끝 "· 광고 없음" 제거 (14언어)
   - `v5_premium.dart:298` '광고 없음'→'3일 무료 체험' + premium_gate_sheet 주석 정정
2. [x] **[device] 대량발송/특급배송 토글 pill화** — 신규 `_modeToggleButton`(brand 옵션 `_optionToggleButton` 와 동일 시각언어) 추가 → `_buildBulkModeToggle`/`_buildExpressToggle` 전면 재작성(full-width Switch 행 제거) → 호출부 Wrap 배치. 대량=Brand 만, 특급=비-답장 전체(Free=잠금 PRO 업셀 pill, 한도소진=opacity 0.55).
3. [x] **[device] 발송버튼 활성/비활성 구분 강화** — **근본원인 발견**: `onPressed==null` 일 때 Flutter 가 `backgroundColor` 대신 테마 기본 disabled 색을 써서 의도한 muted 색 미적용 → 약함. `disabledBackgroundColor`/`disabledForegroundColor` 명시 + 비활성 외곽선(1.2px) + 활성 elevation 3 그림자 + 이모지 dim(0.45).
