# Build 372 세션 핸드오프 — 다음 세션 시작점

> 새 세션에서 이 문서 path 를 첫 prompt 로 보내거나, 아래 "다음 세션 prompt"
> 섹션 복붙.

---

## 📌 현재 상태 (2026-05-25 p4)

### Git
- main 최신: **`755f322`** "fix(rules+compose): rule center/expiresAt + compose try/catch + GPS service-disabled (PR-CC5, Build 372)"
- pubspec: `1.0.0+372`
- 전 PR 모두 squash merge

### 빌드/배포 상태
- ⏳ **TestFlight Build 372 출시 candidate** — `./scripts/release_to_testflight.sh`
- 🚀 **출시 차단 P0 21건 모두 처리 완료**
- ❌ ExactDrop 50/500 IAP 콘솔 등록 대기

### 검증
- `flutter analyze`: clean
- `flutter test`: 137/137 (1 skipped)

---

## 🎯 이번 세션 누적 (Build 360 → 372, **14 PRs** + 시뮬레이션 2 라운드)

### AA 시리즈 — 신규 기능 (3 PR)
- PR-AA1 ([#98](https://github.com/shimyup/thiscount/pull/98)) Build 360 — admin/compose zone 매장 POS 코드 토글
- PR-AA2 ([#99](https://github.com/shimyup/thiscount/pull/99)) Build 361 — EU/SEA letter→쿠폰 270건
- PR-AA3 ([#100](https://github.com/shimyup/thiscount/pull/100)) Build 362 — SecureClipboard 45s TTL

### 4-agent 시뮬레이션 1라운드 → BB 시리즈 (5 PR)
- PR-BB1 ([#102](https://github.com/shimyup/thiscount/pull/102)) Build 363 — Premium gift/invite 회귀
- PR-BB2 ([#103](https://github.com/shimyup/thiscount/pull/103)) Build 364 — i18n P0 hotfix
- PR-BB3 ([#104](https://github.com/shimyup/thiscount/pull/104)) Build 365 — Zone rules + admin id + try/finally
- PR-BB4 ([#105](https://github.com/shimyup/thiscount/pull/105)) Build 366 — SecureClipboard lifecycle observer
- PR-BB5 ([#106](https://github.com/shimyup/thiscount/pull/106)) Build 367 — 잔여 P1 (분사/AR/prefs/timestamp)

### 6-agent 시뮬레이션 2라운드 — **65건+115건 = 180건 발견**
구독/회원가입/발송/픽업/위치/Brand자동 6 영역. P0 21 / P1 50 / P2 44.

### CC 시리즈 — **출시 차단 P0 21건 hotfix** (5 PR)
- **PR-CC1** ([#108](https://github.com/shimyup/thiscount/pull/108)) Build 368 — 결제 5건 (scheduleBrand 무결제 / buyGiftCard 환상 / buyer Premium / Trial key / TestFlight bypass)
- **PR-CC2** ([#109](https://github.com/shimyup/thiscount/pull/109)) Build 369 — 데이터 누수 3건 (setUser inbox / prefs 키 / isMapPublic 좌표)
- **PR-CC3** ([#110](https://github.com/shimyup/thiscount/pull/110)) Build 370 — 회귀 5건 (tryClaimWelcomeTrial / redeemedCount / SecureClock 통일 / Splash debug / dispose race)
- **PR-CC4** ([#111](https://github.com/shimyup/thiscount/pull/111)) Build 371 — 보안 4건 (GPS spoofing SecureLocation 신규 / admin password / trial griefing forensic / multi-device deferred)
- **PR-CC5** ([#112](https://github.com/shimyup/thiscount/pull/112)) Build 372 — rules+compose 4건 (center 좌표/expiresAt cap/compose try-catch/GPS service-disabled)

---

## 🔴 잔여 P0 (Phase 2 — Cloud Function 필요)
- **trial griefing 100% 차단** — 현재 createdBy forensic 만 (admin 사후 정리). server-side issuance 필요.
- **multi-device email 동시 가입 atomic check** — anonymous Firebase Auth 한계로 client UUID 다름. Cloud Function 으로 atomic users 생성 필요.

## 🟡 잔여 P1/P2 — 백로그 (PR-DD 시리즈)
- SnackBar TTL 안내 14언어 (AA3 P1-4)
- ExactDrop bulk credit 차감 우회 (audit msg P1-2)
- canSend 게이트 5자 → 20자 (audit msg P1-4)
- DNS check IPv6/corporate proxy false-positive
- banned word 9언어 사전 추가
- compose bulk/express try/finally (단건만 처리됨)
- Free 답장 회귀 (audit pickup P1-4)
- 답장 disabled 버튼 시각 (audit pickup P1-5)
- _searchDebounce 미작동 (audit pickup P1-2)
- lastInboxLoadSkipped surfacing (audit pickup P1-1)
- category inference 'IT' 영어 단어 false-classify (audit pickup P2-1)
- WCAG 280건 (이전 audit 백로그)

---

## ✅ 보장된 동작 (Build 372 stable)

### 결제 (PR-CC1)
- ✅ `scheduleUpgradeToBrand` 무결제 분기 제거 — Brand 전환은 RC IAP 만
- ✅ `buyGiftCard` 출시 차단 (서버 redemption 흐름 완성까지)
- ✅ Trial expiry prefs.remove 정확
- ✅ `BetaConstants.isProductionBuild` 신규 — 모든 beta flag override

### 데이터 누수 (PR-CC2)
- ✅ setUser 시 _inbox/_sent/_worldLetters/_pendingRedemption clear
- ✅ _clearUserScopedPrefs 가 lkLat/lkLng/map_last_*/tutorial/demo 모두 cleanup
- ✅ isMapPublic OFF 시 좌표 4 필드 nullValue 강제 PATCH

### 회귀 (PR-CC3)
- ✅ tryClaimWelcomeTrial 가 widget.onSignupSuccess **앞**에서 호출
- ✅ Brand zone redeemedCount Firestore PATCH + in-memory bump
- ✅ SecureClock 5건 (redemption TTL) 우회 차단
- ✅ Splash kDebugMode 분기 제거
- ✅ compose dispose 시 항상 _saveDraft

### 보안 (PR-CC4)
- ✅ SecureLocation.guard() 4 사이트 — Mock GPS 차단 (release)
- ✅ admin password validation 강제
- ✅ trial_claims createdBy uid 추적

### Rules + Compose (PR-CC5)
- ✅ brand_zones create rule: center map + 좌표 범위
- ✅ ISO8601 길이 cap + durationDays.clamp(1,90)
- ✅ compose 단건 send try/catch
- ✅ GPS service-disabled SnackBar

### 빌드 스크립트 권장
`release_to_appstore.sh` (production) 가 `--dart-define=PRODUCTION_BUILD=true` 함께 주입. `release_to_testflight.sh` 는 그대로.

---

## 💬 다음 세션 prompt (복붙)

```
/Users/shimyup/Documents/New project/Lettergo/SESSION_HANDOFF_BUILD_372.md
파일 읽고 현재 상태 + AA/BB/CC 시리즈 14 PR + 잔여 백로그 파악 후, 다음 중
우선순위 정해 진행:

  A. TestFlight Build 372 archive + upload (출시 candidate)
  B. PR-DD 시리즈 — 잔여 P1/P2 (ExactDrop bulk credit / 답장 회귀 / debounce / banned word)
  C. WCAG 280건 fix 라운드
  D. Phase 2 — Cloud Function (trial griefing 100% / multi-device email atomic / proper auth)
  E. SnackBar TTL 안내 14언어 i18n
  F. compose bulk/express try/finally (단건만 처리됨)
  G. 추가 시뮬레이션 라운드 (마케팅 SEO / 분쟁 / RevenueCat receipt audit)
  H. 사용자 별도 지시

매 PR analyze + test + commit + push + squash merge + sync.
```

---

## 📁 핵심 파일 추가 (이번 세션 CC)

- `lib/core/services/secure_location.dart` 신규 — GPS spoofing 가드
- `lib/core/services/purchase_service.dart` — scheduleUpgradeToBrand fall-through / buyGiftCard 차단 / Trial expiry prefs / production guard
- `lib/core/config/app_keys.dart` — `BetaConstants.isProductionBuild` 신규
- `lib/state/app_state.dart` — setUser inbox/sent/world clear, _clearUserScopedPrefs 5키 추가, GPS cache reset, tryClaimWelcomeTrial 순서, SecureClock 5건, redeemedCount PATCH, trial_claims createdBy
- `lib/core/services/auth_service.dart` — admin password 강제, logout/deleteAccount 의 resetForLogout
- `lib/core/services/brand_zone_service.dart` — bumpRedeemedCount, durationDays.clamp
- `lib/features/auth/screens/auth_screen.dart` — tryClaimWelcomeTrial 순서, GPS guard
- `lib/features/compose/screens/compose_screen.dart` — dispose draft, GPS guard, send try/catch
- `lib/features/map/screens/world_map_screen.dart` — GPS guard, service-disabled
- `lib/features/splash/splash_screen.dart` — kDebugMode 분기 제거
- `firestore.rules` — brand_zones center/expiresAt 범위, trial_claims createdBy

---

## 🚨 절대 깨면 안 되는 invariant (Build 372 확장 — 총 19건)

기존 13건 + 추가 6건:

14. **신규 (PR-CC1)**: Brand 전환은 RC IAP 만 — `scheduleUpgradeToBrand` 자동 flip 부활 금지
15. **신규 (PR-CC1)**: `buyGiftCard` 는 서버 redemption 흐름 완성 전까지 비활성 — UI 부활 금지
16. **신규 (PR-CC2)**: `setUser` isNewUser 분기에 `_inbox/_sent/_worldLetters/_cachedLastKnown*` reset 필수
17. **신규 (PR-CC2)**: `isMapPublic` OFF 시 좌표 4 필드 `nullValue` PATCH 필수
18. **신규 (PR-CC3)**: redemption TTL 계산은 `SecureClock.now()` — `DateTime.now()` 직접 사용 금지
19. **신규 (PR-CC4)**: GPS Position 사용 전 `SecureLocation.guard(pos)` 필수 — raw `Position.latitude/longitude` 직접 사용 금지
