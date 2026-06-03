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

## 현재 상태 (2026-06-03 갱신)
- 브랜치: `launch-readiness-build411` (PR #150). main 아님.
- 최신 커밋: `5552639` (device 수정: 비-지도 탭 전체화면 + 메세지 버리기 재출현).
- 빌드: pubspec `1.0.0+419`. TestFlight **417·418·419 업로드됨**(417/418 Internal 그룹 확인, 419 업로드 성공·그룹 재확인 중). **다음 빌드는 420 로 bump**.
- 검증 게이트(매 수정 후 필수): `flutter analyze lib/` 무경고 + `flutter test` 전체 통과(현재 **143**).
- ⚠️ flaky 없음(이전 redemption flaky 는 `58c73e2` 에서 근본 수정).
- 누적 진행: sim100 배치(`5fb1557`·`b2655ea`) + iter1~4(`988fb1b`·`bee0d10`·`13cd521`·`0adc0d5`) + device(`5552639`) = 15+건 수정.

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

## 사용자 device 보고 수정 (2026-06-03) — 우선 처리
- [x] 비-지도 탭에서 지도 96px peek 노출 제거 → 탭 콘텐츠 전체화면 (main_scaffold.dart:304, _kMapPeek 제거)
- [x] 작성 메세지 '버리기' 후 재출현 — _saveDraft hasState 가 기본 선택국가만으로 brand draft 저장 → 빈 메세지도 '이어쓰기' 무한 재출현. hasState 를 닫기확인 hasContent 기준(대량/특송/타깃/특정국가/혜택정보)으로 정정 (compose_screen.dart:693)
- Build 419 빌드.
