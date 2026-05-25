# Build 367 세션 핸드오프 — 다음 세션 시작점

> 새 세션에서 이 문서 path 를 첫 prompt 로 보내거나, 아래 "다음 세션 prompt"
> 섹션 복붙.

---

## 📌 현재 상태 (2026-05-25 p3)

### Git
- main 최신: **`75c607c`** "fix(i18n+state): 잔여 P1 — 분사 일치 + AR 잔존 + PT 통일 + prefs cleanup + timestamp (PR-BB5, Build 367)"
- pubspec: `1.0.0+367`
- 전 PR 모두 squash merge

### 빌드/배포 상태
- ⏳ **TestFlight 업로드 대기** — Build 324 이후 archive 안 됨 (`./scripts/release_to_testflight.sh`)
- ❌ Apple/Google/RC 콘솔 IAP 등록 대기

### 검증
- `flutter analyze`: clean
- `flutter test`: 137/137 (1 skipped) — SecureClipboard 10건 (lifecycle observer 3건 추가)

---

## 🎯 이번 세션 누적 (Build 360 → 367, **8 PRs** + 4-agent 시뮬레이션)

### AA 시리즈 — 신규 기능 / 정리 (3 PR)
- **PR-AA1** ([#98](https://github.com/shimyup/thiscount/pull/98)) Build 360 — admin/compose zone 매장 POS 코드 토글 + createZone schema fix (centerLat → mapValue)
- **PR-AA2** ([#99](https://github.com/shimyup/thiscount/pull/99)) Build 361 — EU/SEA 9언어 letter→쿠폰 270건
- **PR-AA3** ([#100](https://github.com/shimyup/thiscount/pull/100)) Build 362 — SecureClipboard 45s TTL 7 사이트

### BB 시리즈 — 4-agent 시뮬레이션 audit fix (5 PR)
- **PR-BB1** ([#102](https://github.com/shimyup/thiscount/pull/102)) Build 363 — Premium gift card + invite code TTL 회귀 hotfix (결제 자산 손실 방지)
- **PR-BB2** ([#103](https://github.com/shimyup/thiscount/pull/103)) Build 364 — IT template literal + RU 미치환 5건 + 성수 일치
- **PR-BB3** ([#104](https://github.com/shimyup/thiscount/pull/104)) Build 365 — Firestore rules hasOnly + redemptionCode 검증 + admin id rand suffix + _submitAutoZone try/finally + cache in-place inject + 만료 zone 코드 숨김
- **PR-BB4** ([#105](https://github.com/shimyup/thiscount/pull/105)) Build 366 — SecureClipboard WidgetsBindingObserver (background P0 fix) + try/catch + share text copyPersistent 통일
- **PR-BB5** ([#106](https://github.com/shimyup/thiscount/pull/106)) Build 367 — FR/ES/PT/IT 여성 분사 일치 + AR 'برسالتك' 2건 + PT-PT/BR 'cupão→cupom' 13건 + stamp/tower 분사 + brand_zones_seen prefs cleanup + createZone timestamp 통일

### 4-agent 시뮬레이션 라운드 — 총 65건 발견
- AA1 zone: 12건 (P0 2/P1 5/P2 5)
- AA2 i18n: 18건 (P0 4/P1 9/P2 5)
- AA3 SecureClipboard: 18건 (P0 2/P1 7/P2 9)
- 전반 회귀: 17건 (P0 2/P1 8/P2 7)

→ BB 시리즈로 P0 8건 + P1 핵심 fix. 잔여 P1 일부 + P2 다수는 다음 라운드 백로그.

---

## 📋 백로그 (다음 세션 추천)

### 1. SnackBar TTL 안내 i18n (AA3 P1-4) — 사용자가 clipboard clear 시점 모름
- 7 secret copy site 의 SnackBar 메시지에 "45초 안 paste" 추가 또는 countdown
- 14언어 신규 키 추가 필요

### 2. WCAG 280건 fix 라운드 (PR-CC 시리즈)
이전 세션 audit 결과 — 다음 세션 fix:
- P0 색상 토큰 재조정 (`textMuted #5A5A5F` 4.5:1 fail)
- P0 IconButton tooltip 9건
- P0 SnackBar 대비 (compose teal+white 1.9:1)
- P1 RTL `EdgeInsets.fromLTRB` 157곳 → Directional
- P1 Image semanticLabel 14곳

상세: `~/.claude/projects/.../memory/wcag_audit_2026_05_25.md`

### 3. compose dispose draft 손실 (전반 P1 #4)
다른 send path 도 공유 — 별도 PR 로 refactor:
- `_didSubmitSuccessfully` 플래그
- dispose() 에서 success 시만 draft 제거, 그 외 보존

### 4. compose `_attachRedemptionCode` 토글이 zone 분기 category noop (AA1 P1 #6)
가이드 dialog 카피 수정 또는 zone 분기에도 category 자동 전환 적용

### 5. AA1 P2 — admin 화면 한국어 hardcoded (i18n 일관성)
- 'matchstring POS 코드 자동 부여' / 'zone 1개 = 코드 1개' / '특별 메시지 zone 생성' 한국어
- 비-ko admin 사용자 노출 (현재 admin 1명이라 P2)

### 6. Phase 2 — proper auth 마이그레이션
가장 큰 unlocker. 별도 아키텍처 세션:
- Letter / User / BrandZone update owner check (Cloud Function)
- redemptionCode public read 분리 (sub-collection + sender-only rule)
- 다중 디바이스 sync
- GDPR sub-doc cleanup 자동화

### 7. 추가 시뮬레이션 영역
- 마케팅 SEO (Apple Search / App Store description)
- 분쟁 / 클레임 처리 흐름
- 재무 / 결제 audit (RevenueCat receipt 위조)

---

## ✅ 보장된 동작 (Build 367 stable)

Build 359 의 모든 보장 동작 그대로. 추가:

### 매장 POS 코드 zone
- ✅ admin/compose 양쪽 zone 1개 = 코드 1개
- ✅ admin id collision 차단 (rand suffix)
- ✅ _submitAutoZone try/finally — _isSending 영구 disable 해소
- ✅ createZone cache in-place inject — 첫 손님 race 해소
- ✅ 만료 zone 코드 표시 차단 (부정 사용)

### Firestore rules
- ✅ brand_zones_create hasOnly 13 필드 화이트리스트
- ✅ redemptionCode optional (6-16 char, `^[0-9A-Z]+$`)
- ✅ redemptionInfo size cap 500
- ✅ brandId size cap 64 (UUID + 'admin' literal)

### i18n
- ✅ 14언어 letter 단어 0건 (PR-AA2 + BB2 + BB5 완전 정리)
- ✅ FR/ES/PT/IT 성수/분사 일치 (envoyé/recibido/recebido/ricevuto)
- ✅ PT BR 통일 (cupom/cupons)

### 보안
- ✅ Secret 코드 45s TTL clear (7 사이트 + lifecycle observer)
- ✅ Background → resumed 시 pending clear 재시도
- ✅ Premium gift / invite 는 TTL 제외 (공유 자산)
- ✅ 모든 Clipboard.setData 호출 SecureClipboard 경유

### State / Storage
- ✅ brand_zones_seen prefs prefix-scoped cleanup (storage bloat 방지)
- ✅ user-scoped prefs 19+1 키 cleanup

---

## 💬 다음 세션 prompt (복붙)

```
/Users/shimyup/Documents/New project/Lettergo/SESSION_HANDOFF_BUILD_367.md
파일 읽고 현재 상태 + AA/BB 8 PR + 백로그 파악 후, 다음 중 우선순위 정해 진행:

  A. SnackBar TTL 안내 14언어 i18n (AA3 P1-4 잔여)
  B. WCAG 280건 fix 라운드 (PR-CC 시리즈)
  C. compose dispose draft 손실 refactor
  D. AA1 P2 — admin 한국어 hardcoded i18n
  E. Phase 2 proper auth (Cloud Function 기반)
  F. 추가 시뮬레이션 라운드 (마케팅 SEO / 결제 audit / 분쟁 처리)
  G. TestFlight Build 367 archive + upload (사용자 작업)
  H. 사용자 별도 지시

매 PR 마다 commit + push (feature branch + squash merge 패턴).
flutter analyze + flutter test 매 PR 검증. 보안 영역 같이 점검.
```

---

## 📁 핵심 파일 추가 (이번 세션 BB)

- `firestore.rules` — isValidBrandZoneCreate hasOnly + redemptionCode 화이트리스트
- `lib/core/utils/secure_clipboard.dart` — _pendingValue/_pendingExpiresAt + WidgetsBindingObserver
- `lib/core/services/brand_zone_service.dart` — createZone cache in-place inject + timestamp stringValue
- `lib/features/admin/admin_special_message_screen.dart` — admin id rand suffix + 만료 zone 코드 숨김
- `lib/features/compose/screens/compose_screen.dart` — _submitAutoZone try/finally
- `lib/state/app_state.dart` — _clearUserScopedPrefs brand_zones_seen prefix cleanup
- `lib/features/premium/premium_screen.dart` — gift/invite copyPersistent + share text 통일

---

## 🚨 절대 깨면 안 되는 invariant (Build 367 확장)

기존 7건 + 추가:

8. **신규 (PR-BB1)**: 결제 자산 코드 (Premium gift / invite) 는 `copyPersistent` — `copyEphemeral` 적용 금지 (TTL clear 시 결제 자산 손실 회귀)
9. **신규 (PR-BB3)**: `BrandZoneService.createZone()` 의 cache update 는 in-place inject (`[..._cache, newZone]`) — `_cache = const []` 로 무효화 금지 (race window)
10. **신규 (PR-BB3)**: admin zone id 는 `admin_<ms>_<rand6hex>` — `admin_<ms>` 단독 금지 (ms collision)
11. **신규 (PR-BB4)**: 모든 `Clipboard.setData` 호출은 `SecureClipboard.copyEphemeral` 또는 `copyPersistent` 경유 — raw `Clipboard.setData` 금지
12. **신규 (PR-BB5)**: `_clearUserScopedPrefs` 가 prefix matching 으로 `brand_zones_seen_` 모든 key 제거 — 단일 list 만 사용 금지
13. **신규 (PR-BB5)**: BrandZone Firestore POST timestamp 필드는 `stringValue` (admin/compose 양 path 동일) — `timestampValue` 사용 금지 (rule `is string` 검사 양립성)
