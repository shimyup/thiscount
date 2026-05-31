Confirmed both:
- `_onAuthSuccess` setUser (285-296) does NOT pass `isBrand` or `brandName` from `userData`. Compared to main.dart cold-start path (which the JSON cites at 266-269). So in-session login to a Brand account → `setUser` with isNewUser path uses default `isBrand:false` → Brand demoted to Free. Confirmed P1.
- Onboarding PageView (463-473) uses `AlwaysScrollableScrollPhysics` with `onPageChanged` only updating state — no guard preventing swipe past the location page without granting/skip warning. Confirmed P2.

I have verified the highest-severity and most novel claims (P0 credit-403, P1 pickup-purge, P1 Brand-demotion, P1 cross-account leaks, P2 double-tap, P2 onboarding-swipe, deleteAccount). The findings are consistent with the actual code. The two P0 entries describe the same root cause (credit increase blocked by rules → atomic 403). I'll now produce the report.

I have enough verification. The JSON's claims are accurate against the code. Producing the final report.

---

# Thiscount 출시 Readiness 종합 리포트 (200-시나리오 카오스 시뮬레이션, Build 414)

## 1. 한줄 요약
**출시 불가.** 신규 P0 1건(중복 root-cause 2 entry) — Build 414 인증 헤더 fix가 노출시킨 회귀로, 유료 크레딧 결제 직후 사용자 doc 저장 전체가 영구 403에 빠져 프로필/위치/카운터/결제자산이 서버에 안 남는다. 결제 무결성과 GDPR 측면에서 코드 핫픽스 없이는 못 낸다.

## 2. 신규 출시차단 P0

### P0-A: ExactDrop/추가발송권 크레딧 증가 → user doc PATCH 전체 영구 403 (Build 414 회귀)
- **위치**: `lib/state/app_state.dart:1160-1169` (adminGrantExactDropCredits) + `:5671-5673` (save mask) + `firestore.rules:161-177` (isReasonableUserCounterDelta)
- **무엇이 깨지나**: `_doSaveUserToFirestore`의 updateMask가 `brandExactDropCredits`/`inviteRewardCredits`/`brandExtraMonthlyQuota`를 **무조건** 포함(5663/5664/5671). 룰은 이 3개 카운터를 **감소만** 허용(176: `newEx <= curEx && newIn <= curIn && newBQ <= curBQ`). 결제로 크레딧을 증가시키면(1162 `+= amount` → 1167 save) 룰 위반으로 전체 PATCH가 atomic 403. 이 시점부터 위치·프로필·타워·카운터·픽업dedup 등 **모든** 서버 저장이 막힌다. Build 414가 Bearer 토큰을 붙이면서 이전엔 "조용히 무인증 실패"하던 게 이제 "인증은 됐는데 룰에서 거부"로 바뀌어 노출됨.
- **권장수정(출시 핫픽스, 옵션 B)**: 일반 프로필 save의 mask에서 credit 3필드를 **제거**하고, 크레딧 변경은 별도 단독 PATCH로만 write. 그러면 일반 프로필/위치/카운터 저장이 항상 `isReasonableUserCounterDelta`를 통과. **근본(Phase 3 백로그)**: 크레딧 grant를 Cloud Function(영수증 검증) 서버화하고 client는 consume(감소)만. 룰을 "증가 허용"으로 푸는 것은 Build 300의 self-mint(결제 우회) 표면 재개방이므로 금지.
- **참고**: app_state.dart:5667-5673의 "크레딧 영속 보장" 주석은 서버화 전까지 거짓이므로 정정 필요.

(JSON의 brand-billing P0와 state-dedup P1 blocker:true 항목은 동일 root cause — 1건으로 합산.)

## 3. P1 — 분류·회원유형별

| ID | 분류 | 회원 | 핵심 |
|---|---|---|---|
| P1-1 | pickup | both | 지도 픽업 후 LetterReadScreen 직행 시 `readLetter()` 미호출 → status=delivered 잔존 → `_purgeExpiredReadLetters`가 7일 후 **유효 쿠폰 자동 삭제** (world_map:2262, letter_read_screen:86-95, app_state:2547-2556 검증 완료) |
| P1-2 | member | brand | 인터랙티브 로그인 `_onAuthSuccess`가 `isBrand`/`brandName`를 setUser에 미전달(auth_screen:285-296) → 같은 세션 Brand 계정 전환 시 **Free로 강등** (검증 완료) |
| P1-3 | security | both | 동일 기기 계정 전환 시 DM·팔로우브랜드·사용완료쿠폰이 다음 사용자에게 누수 — in-memory(isNewUser 블록 4745-4777 미clear) + prefs(_clearUserScopedPrefs 8609-8673 미포함) 양쪽 (검증 완료) |
| P1-4 | purchase | brand | ExactDrop 유료 크레딧 동일기기 계정 전환 누수 (`brandExactDropCredits` in-memory/prefs 둘 다 미reset) |
| P1-5 | purchase | brand | Brand 추가발송권(1000통) 검증 후 sync가 화이트리스트 밖 필드로 403 (P0-A 동일 계열, 배포 시) |
| P1-6 | purchase | brand | 구매 ExactDrop 크레딧 서버 미영속 → 재설치/기변 시 유료 자산 소실 (P0-A 동일 계열) |
| P1-7 | send | brand | letter 첨부 이미지 Storage 업로드 실패 시 로컬경로가 imageUrl로 저장 → 수신자 전원 깨진 이미지 (voucher 흐름만 가드, attach 흐름 미가드, compose:1077-1093) |

**일반회원 P1**: 픽업 쿠폰 7일 소실(P1-1).
**브랜드회원 P1**: Brand 강등(P1-2), 유료 크레딧 403/누수/소실(P1-4/5/6, 모두 P0-A 계열), 깨진 이미지 발송(P1-7).
**both**: 계정전환 데이터 누수(P1-3).

## 4. 보안 이슈 (Build 414 회귀 집중)

- **[회귀, CRITICAL→결제]** P0-A: Build 414 Bearer 토큰 추가가 credit 증가 403을 노출. **414 변경이 직접 만든 회귀** 맞음. credit grant 서버화 전까지 결제 자산이 서버에 안 남음 → 사실상 결제 무결성 결함.
- **[회귀 아님, 잔존]** 계정 전환 누수 P1-3/P1-4: `_clearUserScopedPrefs`에 `brandExactDropCredits`/`redeemedLetterIds`/`followedBrandIds`/`chatSessions`/`dmMessages` 누락 + isNewUser 블록 in-memory 미reset. Build 409/412가 같은 패턴을 부분적으로만 메웠고 이 필드들은 빠짐. cold restart 후에도 prefs에서 부활.
- **[P3]** `_deleteRemoteAccountDataBestEffort`의 `pending_gdpr_deletions` 큐를 직후 `prefs.clear()`가 삭제(auth_service:1505-1507) + reader/processor 0건 → GDPR 재시도 큐 데드. 단 백엔드 hard-delete Function 부재가 선결이라 이 수정만으론 Art.17 미이행 해소 안 됨(코드 밖 BLOCKER ⑥과 연동).
- **Build 414 isBrand 화이트리스트 추가 self-promote 우려**: 조사 결과 setUser(4797)의 `isNewUser ? isBrand : (isBrand || _currentUser.isBrand)` 분기로 신규 계정의 상속은 차단됨. 화이트리스트 추가 자체가 새 self-promote를 열지는 않음(anon-auth cross-user write 한계는 기존 백로그). **414가 만든 신규 self-promote 회귀는 미발견.**

## 5. 일반회원 vs 브랜드회원 핵심 이슈

**일반회원(Free)**
- 픽업 쿠폰이 지도→상세 직행 시 7일 미열람 판정으로 삭제(P1-1, 결제·신뢰 직격)
- OTP 인증 후 username 중복으로 signUp 실패 시 인증화면 데드락(P3)
- 온보딩 위치 동의 스와이프 우회(P2), 가입 폼 언어 혼재/선택기 무력(P2 i18n ×2)
- 인박스 정렬칩이 Premium→Free 후 'AI 추천' 거짓 표시(P3)

**브랜드회원(Brand)**
- 유료 크레딧 결제→서버 저장 전면 403(P0-A), 계정전환 누수/재설치 소실(P1 다수)
- Brand 계정 전환 시 Free 강등(P1-2)
- 첨부 이미지 업로드 실패 시 깨진 이미지 발송(P1-7)
- 자동 zone이 발송 quota 미소비 + 요약카드 허위(P2), bulk/express와 상호배제 미적용(P3)
- 발송 버튼 더블탭 시 express/bulk 병렬 발송 + 크레딧 2배 소모(P2)
- 한정 수량 입력 상한/필터 없음(P3), 자동 zone 라벨 '편지보내기→🇰🇷' 오표시(P2)

## 6. UX 개선안

**관리감독자(Admin)**
- Admin 'Free'/'Premium' 등급 버튼이 release에서 `debugSetTier` no-op이지만 `syncPremiumStatus`는 실행 → **거짓 성공 스낵바 + Purchase/AppState tier 영구 desync**. Debug Tools 섹션 전체를 `kDebugMode || !isProductionBuild` 게이트로 감싸 release 비노출 권장(P3 ×2).

**구독자(Premium/Brand)**
- 구독 해지/다운그레이드 진입이 'compare all plans' 토글 뒤에 숨고, 전용 `_DowngradeSection`은 데드코드(P3). 기본 뷰에 명시적 '구독 관리' 진입점 노출.
- 구매 복원 '복원할 것 없음' 케이스 silent no-op → 토스트 추가(P2).
- ExactDrop 구매 다이얼로그 'BEST' 배지의 통당 단가 근거 소실(P3).

## 7. 문서/중복 이슈
- privacy.html이 Build 411 신규 마케팅 수신 동의(consent_marketing_ts, 정보통신망법 §50) 처리목적 미반영(P2) — 코드는 수집, 방침은 누락.
- EU/EEA '전체 동의' 카드가 연령요건 '14세+' 오표기, 실제 게이트는 16세(P2 i18n).
- 설정 '위치기반서비스 이용약관' 타일이 koEn 토글(12언어 영어 노출)(P3).
- `.env.example`의 PERMANENT_ADMIN_EMAIL 예시 `ceo@thiscount.io` ≠ 실제 `ceo@airony.xyz`(P3).
- app_state:5667-5673 "크레딧 영속 보장" 주석 거짓(P0-A 동반 정정).

## 8. P2/P3 분류별 건수

확정 신규 38건: **P0 2(동일 root, 실질 1) · P1 8 · P2 14 · P3 14**

- **P2 (14)**: i18n 5 / purchase 3 / send 3 / ux 1 / state 1 / docs 1
- **P3 (14)**: send 4 / pickup 3 / state 3 / purchase 2 / subscription 1 / ux 1
(autosend·security·docs는 P2/P3 분산)

## 9. 냉철한 비판적 총평
이 앱은 **결제와 데이터 영속성의 신뢰 기반이 깨진 상태**다. Build 414의 토큰 fix는 인증을 고쳤지만, 동시에 룰과 mask의 구조적 모순(credit 증가 vs 감소-only 룰)을 정면으로 드러냈다 — 결과적으로 **돈을 내면 그 결제 자산이 서버에 안 남고, 그 시점부터 위치·프로필까지 같이 막히는** 최악의 조합이다. 이건 "버그"가 아니라 아키텍처 부채(client가 grant를 write하는데 룰은 막는다)가 표면화된 것이고, 핫픽스(옵션 B)는 출혈을 멈출 뿐 근본 치료(서버 grant)는 Phase 3로 밀려 있다.

그 위에 **anon Firebase Auth라는 근본 한계**가 깔려 있어 cross-user write·doc 소유권 검증 불가가 여전하다. 계정 전환 누수가 빌드마다 "또 다른 필드"로 재발하는 것(409→412→414)은 `_clearUserScopedPrefs`/isNewUser가 화이트리스트 방식이라 새 상태 필드 추가 때마다 사람이 손으로 등록해야 하는 구조적 취약점이다 — 자동으로 또 샐 것이다.

UX도 핵심 가치 흐름에서 샌다: 일반회원이 쿠폰을 지도에서 픽업하면 7일 뒤 조용히 삭제되고, 브랜드가 정성껏 보낸 이미지가 Storage 미설정 시 전원에게 깨져 보인다. 이건 첫인상에서 신뢰를 잃는 종류다. 코드 밖에서는 메일/SMS 키 rotate, 방통위 위치기반서비스 신고, 문서 호스팅, GDPR hard-delete Function이 **여전히 미완**이다. 즉 코드를 다 고쳐도 **운영 BLOCKER만으로 출시 불가**다.

요약: 출시할 수 있는 상태가 아니라, "출시 직전인 척하는 상태"다.

## 10. 성공 가능성 — 현실적 평가
**현 상태 출시 시 성공 확률: ~15%.** 근거: ① 결제→서버 영속 실패(P0-A)로 유료 사용자(Brand)가 돈을 내고도 자산을 잃으면 환불·이탈·평점 폭락이 즉시 발생, ② anon-auth로 cross-user/누수가 구조적이라 보안 incident 1건이면 신뢰 회복 불가, ③ 위치기반서비스 신고·문서 호스팅 미완은 한국 법규/심사 리스크.

**P0-A 핫픽스 + 운영 BLOCKER top 3 해소 시: ~55-60%로 상승.** 제품 자체(위치기반 쿠폰)는 시장성이 있으나, 결제 신뢰와 법규 준수가 닫혀야 비로소 출발선.

**출시 전 반드시 닫아야 할 top 3**
1. **P0-A 크레딧 403 핫픽스** (옵션 B: credit 필드를 일반 프로필 mask에서 분리) — 안 닫으면 결제 즉시 데이터 손상.
2. **메일/SMS 키 rotate + Cloud Function relay 배포(Blaze)** — 코드 밖 BLOCKER ①, phishing 도메인 사칭 표면. functions/ 코드는 준비됨, 배포+키폐기만 남음.
3. **방통위 위치기반서비스사업 신고 + privacy/terms/location_terms thiscount.io 호스팅** — 코드 밖 BLOCKER ④⑤, 미이행 시 in-app 링크 404 + 한국 운영 위법.

(코드 밖 운영/Phase3 BLOCKER 별도: anon-auth 정식 마이그레이션, GDPR hard-delete Function, App Store Privacy Label/Play Data Safety, brand_zones redemptionCode subcollection — MEMORY 기재 항목들과 동일하므로 본 리포트에서는 신규 코드 결함만 다룸.)