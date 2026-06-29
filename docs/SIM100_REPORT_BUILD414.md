모든 핵심 결함이 코드와 일치함을 확인했습니다. `firestore.rules`의 `isValidLetterCreate`(48-63)에 `senderIsBrand` 게이트가 없어 위조 가능, 전체동의 카드가 `_agreeMarketing`까지 ON(번들링 위반)도 확인. 충분히 검증되었습니다. 리포트를 작성합니다.

---

# Thiscount Build 414 — 100-시나리오 출시 readiness 종합 리포트

## 1. 한줄 요약
**코드/구성 관점 출시 불가.** 정식 출시를 막는 P0(blocker) 4건이 확정 — 핵심은 (a) firestore.rules 화이트리스트와 클라이언트 PATCH 마스크 불일치로 **Brand·유료 상태가 서버에 저장되지 않고(403 atomic 거부) 결제 후 권한 손실/재설치 영실**, (b) `senderIsBrand` 위조로 **'공식 발송인' 사칭**, (c) Storage 미활성 시 **로컬 경로가 Firestore에 저장돼 수신자에게 깨진 이미지**. (a)/(b)는 익명 Auth 한계와 얽혀 있어 정식 Auth(Phase 3) 또는 rules 화이트리스트 보강+검증 게이트가 선행돼야 함.

---

## 2. 출시 차단 (P0 / blocker)

### P0-1. 유료/Brand 프로필 PATCH가 rules `hasOnly` 위반 → 전체 update atomic 403 거부
- **file**: `lib/state/app_state.dart:5629, 5662, 5698` (PATCH fields) ↔ `firestore.rules:107-134` (`isAllowedUserUpdate`)
- **무엇이 깨지나**: `_doSaveUserToFirestore`의 fields 맵에 `isBrand`(5629), `brandName`(5630-5632), `welcomeTrialClaimedAt`(5668), `pickedUpCampaignIds`(5698)를 항상 포함하는데, rules 화이트리스트(111-133)에는 이 키들이 없음. Firestore update는 atomic이라 화이트리스트 밖 키가 하나라도 있으면 **PATCH 전체가 403**. 결과: Brand 가입/구매 후 `isBrand`·`brandExactDropCredits` 등 모든 프로필 변경이 서버 미저장 → 재설치·타기기 로그인 시 Free로 강등(결제 분쟁).
- **권장 수정**: rules 화이트리스트에 `isBrand`/`brandName` 추가하거나(create는 여전히 `isValidUserCreate`로 false 강제), `_doSaveUserToFirestore`에서 비-self 필드(`isBrand`/`brandName`/`welcomeTrialClaimedAt`/`pickedUpCampaignIds`/`id`)를 별도 경로(admin REST / Cloud Function)로 분리. 근본은 Auth Phase 3 cutover.

### P0-2. 클라이언트가 `senderIsBrand=true` + 임의 senderName 위조 → '공식 발송인' 사칭
- **file**: `firestore.rules:48-63` (`isValidLetterCreate` — `senderIsBrand` 게이트 없음, grep 확인) ↔ `lib/state/app_state.dart:8348`
- **무엇이 깨지나**: letter create rule이 `senderName.size()<=100`만 보고 `senderIsBrand`를 전혀 검증하지 않음. 익명 Auth 상태의 임의 사용자가 `senderIsBrand:true` + 위조 senderName으로 letter를 직접 write → 수신자에게 👑 공식 발송인 배지·브랜드 광고 팝업 사칭(피싱).
- **권장 수정**: `isValidLetterCreate`에 미검증 writer의 `senderIsBrand==true` 거부 추가, 또는 verified-brand 화이트리스트 doc 대조. 단기 완화로 `featuredBrandPromo` 자동 브로드캐스트를 검증 brand로 제한. 근본은 정식 Auth(authUid owner-scope).

### P0-3. 익명 Firebase Auth — 임의 인증 사용자가 타 사용자 users 문서 화이트리스트 필드 변조
- **file**: `firestore.rules:175-183` (`allow read: if true` + update가 owner-check 불가)
- **무엇이 깨지나**: 익명 auth라 `request.auth.uid ≠ 앱 userId`. update가 `isSignedIn()`+화이트리스트만 걸려, 어떤 인증 사용자든 **타인 doc의 isMapPublic·좌표·username 등 화이트리스트 필드를 변조** 가능. read는 전면 public.
- **권장 수정**: Auth Phase 3 cutover(`firestore.rules.phase2`의 owner-scope). 익명 auth 상태에선 rules 단독 해결 불가 → 정식 Firebase Auth 마이그레이션 필수. 임시로 고위험 필드(isMapPublic/좌표)를 Cloud Function 서버측 write로 전환.

### P0-4. 이미지/바우처 첨부가 Storage 비활성(기본값) 시 로컬 경로로 Firestore 저장 → 수신자 깨진 이미지
- **file**: `lib/features/compose/screens/compose_screen.dart:4146` (`_redemptionInfoController.text = compressedPath`), 4156-4159 (uid 없으면 업로드 스킵하고 로컬 경로 잔존)
- **무엇이 깨지나**: `FIREBASE_STORAGE_ENABLED`가 꺼진 빌드(기본값)에서 `uploadPath.isEmpty`면 업로드를 스킵하지만 컨트롤러에는 이미 로컬 파일경로가 들어가 있어 그대로 Firestore에 저장됨. 발송자 기기 외 모든 수신자는 깨진 이미지(소비자 기만 소지).
- **권장 수정**: 출시 전 Firebase Blaze 활성화 + `--dart-define=FIREBASE_STORAGE_ENABLED=true` 주입(코드 변경 불필요). 즉시 불가하면 Storage 비활성 시 사진/교환권 첨부 UI를 숨기거나 발송 차단해 로컬 경로 저장 방지.

> 참고: P0-1·P0-3는 같은 익명 Auth 뿌리. AUTH_BIND_ENABLED는 현재 프로덕션 OFF이며 Phase 3 cutover 전까지 rules 단독으로 owner-check 불가 — 출시 전 의사결정 필요(완전 마이그레이션 vs rules 화이트리스트 보강+Cloud Function 게이트).

---

## 3. P1 중대 (분류별 요약)

**결제·구매 정합성 (4건)** — 사용자 금전 피해/오인 직결:
- 구매 후 Firestore write 실패 시 ExactDrop 유료 크레딧 소실(비가산형 덮어쓰기) `app_state.dart:5810`
- Premium→Brand '지금 업그레이드' 결제 취소/실패에도 녹색 '성공' 스낵바 `premium_screen.dart:3004-3028`
- 다운그레이드 다이얼로그가 "다음 결제일부터 청구 안 됨" 허위 안내(실제 스토어 미해지) `premium_screen.dart:382` / `purchase_service.dart:1219`
- `_doSaveUserToFirestore` PATCH가 인증 토큰 미부착 → `isSignedIn()` 차단(=P0-1과 동일 뿌리) `app_state.dart:5723`

**보안·PII (3건)**:
- 계정 전환 시 in-memory `isBrand/brandName`가 새 사용자에게 OR-fallback 상속(Brand 권한 누수) `app_state.dart:4788`(확인됨: `isBrand: isBrand || _currentUser.isBrand`)
- user PATCH가 화이트리스트 밖 필드 포함해 atomic 403(=P0-1) `app_state.dart:5698`

**발송 (2건)**:
- Express+Bulk 발송 시 redemptionCode(사용 코드) 토글 무시 → 매장 코드 없는 쿠폰 발송 `app_state.dart:8683`
- 이미지 첨부 Storage 비활성 시 로컬 경로 저장(=P0-4) `compose_screen.dart:4146`

**픽업·UX (3건)**:
- 신규 가입자 GPS 미수집 → (0,0)으로 줍기 전면 불가 `world_map_screen.dart:2518`
- 다운그레이드 후 schedule 미클리어 → 재구독해도 Premium 회수 `purchase_service.dart:641-656`
- 구매 복원: 활성 구독 없어도 '복원 성공' 거짓 안내 `purchase_service.dart:1190-1204`(확인됨: `restorePurchases`가 entitlement 무관 `return true`)

---

## 4. UX 개선 핵심 (이탈/완성도 영향순)

**구독자 관점 (전환·신뢰 직결)**:
1. Premium→Brand 업그레이드 취소/실패에도 '✅ 성공' 표시 → 결제 안 됐는데 됐다고 오인(P1, 신뢰 붕괴)
2. 다운그레이드 안내 "청구 안 됨" 허위 → 실제 계속 청구 = 환불/리뷰 폭탄 리스크(P1)
3. Premium Gate 1차 전환 화면이 14개 언어 전부 ₩4,900 하드코딩 → 비한국 App Store 사용자에 잘못된 통화 `premium_gate_sheet.dart:184` (P2)
4. premium_screen 전환 문구 12개 언어 영어 노출 + Brand 추가발송권 ₩15,000 하드코딩 `premium_screen.dart:2342, 567` (P2)

**관리감독자(Brand/Admin) 관점**:
1. Admin 등급변경/차단 버튼이 deployed rules에 막혀 **항상 403** → 앱 내 모더레이션 불가, 콘솔 우회 필요 `user_management_screen.dart:424` (P2)
2. Brand 자동존(zone) 캠페인이 월간/일일 quota 게이트 완전 우회 `compose_screen.dart:1269` (P2)
3. Brand auto-zone 성과가 ROI 대시보드(brandInsights)에 미집계 → 자동존 효과 측정 불가 `app_state.dart:1959` (P2)
4. 회원가입 '전체 동의'가 광고성 수신(선택)까지 자동 ON → 정보통신망법 제50조 번들링 위반 `auth_screen.dart:1758-1779`(확인됨: `_agreeMarketing = next`) — 법적/심사 리스크 (P2)
5. 동의 철회/문의 mailto가 메일 앱 없으면 무반응 데드버튼 `settings_screen.dart:1150-1163` (P2)

---

## 5. P2/P3 분류별 건수

| 분류 | P2 | P3 |
|---|---|---|
| 보안 (auth/pii/payment) | 6 | 3 |
| 구매/구독 | 4 | 2 |
| 발송 (send) | 2 | 3 |
| 픽업 (pickup) | 2 | 4 |
| 자동발송 (autosend) | 1 | 6 |
| i18n | 4 | 1 |
| 회원/관리 (member) | 3 | 0 |
| UX | 1 | 0 |
| a11y | 0 | 1 |
| **합계** | **23** | **20** |

(P0=4, P1=11 포함 전체 확정 결함 58건. blocker 표기는 P1 area 분류이나 실제 출시차단 분석 결과 위 4건이 진성 P0.)

---

## 6. 다음 액션 우선순위

1. **[P0, 코드] rules ↔ PATCH 마스크 정합** — `isAllowedUserUpdate` 화이트리스트에 `isBrand`/`brandName` 추가 + `welcomeTrialClaimedAt`/`pickedUpCampaignIds` 분리, PATCH에 인증 토큰 부착(P0-1/P1 동일 뿌리). 가장 빠르게 출시 가능선에 도달하는 단일 수정.
2. **[P0, 코드] senderIsBrand 게이트** — `isValidLetterCreate`에 미검증 writer의 `senderIsBrand==true` 거부 추가(룰만 수정, 빠름).
3. **[P0, 구성] Storage 활성** — Blaze + `FIREBASE_STORAGE_ENABLED=true` 빌드 주입, 또는 비활성 시 첨부 UI 차단.
4. **[P1, 코드] 결제 정합 묶음** — ExactDrop 가산형 복원(5810), 업그레이드 성공 스낵바 bool 분기(3004), 복원 결과 검증(1196), 다운그레이드 안내 문구 정정, schedule 클리어.
5. **[P1, 코드] 신규 GPS 수집** — 온보딩 finish/world_map initState에서 1회 getCurrentPosition→updateUserLocation.
6. **[P1, 코드] setUser isBrand 상속 차단** — isNewUser 블록에서 `_currentUser.isBrand=false`(4788 OR-fallback 제거).
7. **[법무/UX] 전체동의 마케팅 번들링 해제**(정보통신망법) + Admin 모더레이션 데드버튼 처리.
8. **[P2/P3 백로그]** i18n 하드코딩 가격·문구, 픽업 정렬(redemptionExpiresAt), autosend ghost 마커 등은 출시 후 라운드.

---

## 코드 밖 운영 BLOCKER (별도 트랙 — 출시 전 필수, 본 시뮬 범위 밖)
- [CRITICAL] Resend/Twilio 키 rotate + Cloud Function 배포(Blaze) + functions:secrets 등록 + 함수 URL 빌드 주입 (Build 413 코드는 완료, 배포·rotate 미완)
- [HIGH] 익명 Auth → 정식 Firebase Auth 마이그레이션 Phase 3 cutover (위 P0-1/P0-3/P1 다수의 근본; firestore.rules 미배포 + firebase CLI 재인증 필요)
- brand_zones redemptionCode subcollection 분리 + redeemedCount Cloud Function enforce
- 방통위 위치기반서비스사업 신고(emsit.go.kr)
- privacy/terms/location_terms thiscount.io 호스팅(현재 in-app 링크 404)
- letters hard-delete Cloud Function(GDPR Art.17)
- App Store Privacy Label / Play Data Safety 폼

**관련 파일(절대경로)**: `/Users/shimyup/Documents/New project/Lettergo/firestore.rules`, `/Users/shimyup/Documents/New project/Lettergo/lib/state/app_state.dart`, `/Users/shimyup/Documents/New project/Lettergo/lib/features/compose/screens/compose_screen.dart`, `/Users/shimyup/Documents/New project/Lettergo/lib/core/services/purchase_service.dart`, `/Users/shimyup/Documents/New project/Lettergo/lib/features/premium/premium_screen.dart`, `/Users/shimyup/Documents/New project/Lettergo/lib/features/auth/screens/auth_screen.dart`