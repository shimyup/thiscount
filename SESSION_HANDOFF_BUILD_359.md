# Build 359 세션 핸드오프 — 다음 세션 시작점

> 새 세션에서 이 문서 path 를 첫 prompt 로 보내거나, 아래 "다음 세션 prompt"
> 섹션 복붙. 새 Claude 세션이 이 문서 읽고 현재 상태 + 다음 작업 즉시 파악.

---

## 📌 현재 상태 (2026-05-25)

### Git
- main 최신: **`e823d8f`** "fix(security): ScreenProtector 공통 ref counter 통합 (PR-Z2, Build 359)"
- pubspec: `1.0.0+359`
- 전 PR 모두 squash merge — 분기 없음

### 빌드/배포 상태
- ⏳ **TestFlight 업로드 대기** — Build 324 archive 후 Build 325~359 은 아직 archive 안 됨
- ❌ Apple/Google/RC 콘솔 IAP 등록 대기 (ExactDrop 50/100/500 패키지 — PR-T4)

### 검증
- `flutter analyze`: clean
- `flutter test`: 127/127 (1 skipped — brand_zone_test)

---

## 🎯 이번 세션 누적 (Build 325 → 359, **36 PRs**)

### Tier 2 — 5차 audit (PR-T1 ~ T6) Build 325-330
- T1 gold→violet AI 분리 ([#62](https://github.com/shimyup/thiscount/pull/62))
- T2 AI +N 다신호 보조 ([#63](https://github.com/shimyup/thiscount/pull/63))
- T3 온보딩 6→3 페이지 ([#64](https://github.com/shimyup/thiscount/pull/64))
- T4 ExactDrop 50/100/500 3티어 ([#65](https://github.com/shimyup/thiscount/pull/65))
- T5 카드 5요소 룰 ([#66](https://github.com/shimyup/thiscount/pull/66))
- T6 brandInsights 홈 위젯 ([#67](https://github.com/shimyup/thiscount/pull/67))

### 매장 코드 인증 (PR-S1 ~ S17) Build 331-347 — **6 시뮬레이션 라운드**
- S1 코드 발급 + 모델 — Letter.redemptionCode (8자 Crockford) ([#68](https://github.com/shimyup/thiscount/pull/68))
- S2 손님 reveal UI — Code128 + 큰 텍스트 ([#69](https://github.com/shimyup/thiscount/pull/69))
- S3 ROI 4단계 funnel ([#70](https://github.com/shimyup/thiscount/pull/70))
- S4 Brand 코드 표시 — dedup section + reveal dialog ([#71](https://github.com/shimyup/thiscount/pull/71))
- S5 14언어 i18n 26 키 ([#74](https://github.com/shimyup/thiscount/pull/74))
- S6 IDOR 가드 + Firestore await ([#72](https://github.com/shimyup/thiscount/pull/72))
- S7 Firestore rule + UX 폴리시 ([#73](https://github.com/shimyup/thiscount/pull/73))
- S8 sticky CTA + 밝기 ref counter + TTL 2h ([#75](https://github.com/shimyup/thiscount/pull/75))
- S9 캠페인 코드 그루핑 + POS 가이드 docs ([#76](https://github.com/shimyup/thiscount/pull/76))
- S10 codeRevealedAt 동기 + verify 한계 명시 ([#77](https://github.com/shimyup/thiscount/pull/77))
- S11 clone() reset + 16 결함 ([#78](https://github.com/shimyup/thiscount/pull/78))
- S12 a11y + 빈 코드 안내 ([#79](https://github.com/shimyup/thiscount/pull/79))
- S13 sentinel cleanup + fallback 제거 ([#80](https://github.com/shimyup/thiscount/pull/80))
- S14 normalize + lifecycle + zone code ([#81](https://github.com/shimyup/thiscount/pull/81))
- S15 sanitize 보존 + Panel revert + copyWith ([#82](https://github.com/shimyup/thiscount/pull/82))
- S16 plural i18n + verify cache ([#83](https://github.com/shimyup/thiscount/pull/83))
- S17 guide dialog 중첩 가드 ([#84](https://github.com/shimyup/thiscount/pull/84))

### 계정 / 구매 / 위치 (PR-U1 ~ U4) Build 348-350
- U1 maxReaders Firestore claim rollback + GPS 0,0 + 19 키 prefs ([#85](https://github.com/shimyup/thiscount/pull/85))
- U2 Trial+Premium leak + buy operation race ([#86](https://github.com/shimyup/thiscount/pull/86))
- U4 letter → 쿠폰 25+ 인스턴스 (JP/ZH/EU) ([#87](https://github.com/shimyup/thiscount/pull/87))

### 성능 / 알림 / 데이터 (PR-V1 ~ V4) Build 351-354
- V1 _flushPrefs 500ms debounce + timer null ([#88](https://github.com/shimyup/thiscount/pull/88))
- V2 알림 ID SHA256 prefix (collision ~0) ([#89](https://github.com/shimyup/thiscount/pull/89))
- V3 햅틱 200ms throttle + sort id tiebreaker ([#90](https://github.com/shimyup/thiscount/pull/90))
- V4 검색 200ms debounce + inbox corruption skip log ([#91](https://github.com/shimyup/thiscount/pull/91))

### 보안 hardening (PR-W1, X1, Y1, Z1, Z2) Build 355-359
- W1 streak SecureClock — 시계 조작 차단 ([#92](https://github.com/shimyup/thiscount/pull/92))
- X1 deeplink 정규식 강화 + Firestore 3회 retry ([#93](https://github.com/shimyup/thiscount/pull/93))
- Y1 redemption panel ScreenProtector ([#94](https://github.com/shimyup/thiscount/pull/94))
- Z1 ScreenProtector ref counter + paused flush ([#95](https://github.com/shimyup/thiscount/pull/95))
- Z2 ScreenProtector 공통 헬퍼 통합 ([#96](https://github.com/shimyup/thiscount/pull/96))

---

## 🔴 다음 세션 추천 우선순위

### 1. **빌드 배포 마무리** (사용자 작업 대기)
- Xcode → Organizer → Distribute App → ASC Upload
- 또는 `./scripts/release_to_testflight.sh` (account 먼저 연결)
- ExactDrop 50/500 SKU 콘솔 등록: `thiscount_exact_drop_50_ios` / `thiscount_exact_drop_500_ios`
- 가이드: [`docs/release/store-code-pos-setup.md`](docs/release/store-code-pos-setup.md)

### 2. **Phase 2 deferred 작업** (anonymous Firebase Auth 한계 해소)
가장 큰 unlocker — proper auth 마이그레이션 필요:
- Letter / User / BrandZone update **owner check** (Cloud Function gating)
- **redemptionCode public read** 분리 (subcollection + sender-only rule)
- **다중 디바이스 sync** (codeRevealedAt / blocks / longestStreak)
- **GDPR sub-doc cleanup** 자동화
- **서버 API key 발급** (Twilio / SendGrid)

### 3. **운영 polish** (이번 세션 deferred)
- BrandZone setup 화면 코드 토글 UI (model 만 추가됨 — UI 누락)
- 270+ EU/SEA 잔존 letter 용어 정리 (fr/de/es/pt/ru/tr/it/hi/th/ar)
- 알림 timezone fractional offset (flutter_timezone 패키지)
- 지도 Consumer rebuild 최적화 (select)
- _findRecentMatchingCode 성능 indexing (1000+ iter)
- HTTPS certificate pinning (`http_certificate_pinning`)
- AppLifecycle reauth (idle 10분 후)
- Session timeout / remote logout
- Clipboard 자동 만료 (workaround)
- FCM 토큰 정책

### 4. **추가 시뮬레이션 가능 영역**
- **WCAG 접근성 audit** (VoiceOver, TalkBack, RTL Arabic)
- **마케팅 SEO** (Apple Search / App Store description)
- **분쟁 / 클레임 처리 흐름** (사용자가 매장에서 거절당했을 때)
- **재무 / 결제 audit** (RevenueCat receipt 위조 차단)
- **부적절 컨텐츠 ML 검출** (image / text)
- **데이터 export GDPR portability**

---

## 📊 결함 fix 정량

총 ~130 P0/P1 결함 해소 (시뮬레이션 9 라운드 누적):

| 카테고리 | 결함 수 | 대표 |
|---|---|---|
| **P0 (시스템 무산)** | ~10 | Brand 코드 표시 / maxReaders race / sentinel stuck / clone reset / sanitize 손실 / Firestore timestamp / paused flush / ScreenProtector race |
| **P1 (회귀/보안)** | ~60 | IDOR 가드 / 14언어 i18n / clock skew / dialog 중첩 / Semantics / 5요소 룰 / category 의존 / sort tiebreaker / 햅틱 throttle / 검색 debounce / deeplink 정규식 / Firestore retry / streak SecureClock |
| **P2 (폴리시)** | ~60 | hit area / FittedBox / 단복수 / 디버그 메시지 / corruption log / panel header 일관성 |

---

## ✅ 보장된 동작 (Build 359 stable)

### 매장 코드 인증
- ✅ 발급: Crockford 8자 + 2자 check digit
- ✅ Reveal: Code128 바코드 + 큰 텍스트 + 화면 밝기 1.0 + ScreenProtector
- ✅ ROI: 4단계 funnel (📮 발송 → 🎯 픽업 → 🛒 노출 → ✅ 사용) + 코칭 메시지
- ✅ 14언어 + 단복수 분기 (en/de/fr/es/pt/ru/tr/it)
- ✅ 다중 디바이스: codeRevealedAt timestamp ISO/ms 호환
- ✅ 보안: IDOR + race lock sentinel (-now) + clock skew
- ✅ bulk send 100통 동일 코드 → 매장 POS 1회 등록

### 계정 / 구매
- ✅ 계정 전환 19 키 prefs 격리
- ✅ maxReaders race: Firestore claim 412 → local rollback
- ✅ GPS 0,0 픽업 차단
- ✅ Trial+Premium ambiguous state 해소
- ✅ 동시 buy operation skip

### 성능
- ✅ _flushPrefs 500ms debounce (50회 → 1회)
- ✅ Timer null safety (leak guard)
- ✅ paused / detached 시 flushPrefsBlocking
- ✅ 검색 200ms debounce
- ✅ 햅틱 200ms throttle

### 보안
- ✅ Streak SecureClock (시계 조작 차단)
- ✅ Deeplink 정규식 `[A-Za-z0-9_-]{1,128}`
- ✅ Firestore 3회 exponential retry (1s, 2s backoff)
- ✅ ScreenProtector 공통 ref counter (3 객체 통합)
- ✅ 알림 ID SHA256 prefix (collision ~0)
- ✅ Letter.fromJson timestamp 호환 (ISO/ms epoch/seconds 휴리스틱)
- ✅ Inbox corruption skip + 카운트 노출

---

## 💬 다음 세션 prompt (복붙)

```
/Users/shimyup/Documents/New project/Lettergo/SESSION_HANDOFF_BUILD_359.md
파일 읽고 현재 상태 + 누적 PR 36건 + Phase 2 deferred 영역 파악 후, 다음
중 우선순위 정해 진행:

  A. TestFlight Build 359 archive + upload (사용자 작업 필요)
  B. Phase 2 보안 작업 (proper auth + Cloud Function gating)
  C. 운영 polish (BrandZone UI / 270 EU letter / certificate pinning)
  D. 추가 시뮬레이션 라운드 (WCAG / 부정 사용 / 결제 audit)
  E. 사용자가 별도로 지시한 작업

매 PR 마다 commit + push (feature branch + squash merge 패턴).
flutter analyze + flutter test 매 PR 검증.
보안 영역은 항상 같이 점검.
```

---

## 📁 핵심 파일 위치

### 코드
- `lib/state/app_state.dart` — 모든 상태 (~9000줄)
- `lib/features/inbox/widgets/letter_read_screen.dart` — redemption box + reveal panel + _ScreenProtectionGuard
- `lib/features/inbox/screens/inbox_screen.dart` — letter card (5요소) + filter + 검색
- `lib/features/compose/screens/compose_screen.dart` — Brand compose + ExactDrop tier paywall + code 가이드 dialog
- `lib/features/map/screens/world_map_screen.dart` — 지도 + 핀
- `lib/features/brand/brand_insights_screen.dart` — 4단계 funnel + 발급 코드 dedup
- `lib/widgets/main_scaffold.dart` — nav + trial 배너 + brandInsights 홈
- `lib/core/services/purchase_service.dart` — IAP (Premium / Brand / ExactDrop 50/100/500)
- `lib/core/services/notification_service.dart` — local notifications + SHA256 ID
- `lib/core/services/firestore_service.dart` — REST + 3회 retry
- `lib/core/utils/redemption_code.dart` — Crockford generate / verify / normalize

### i18n
- `lib/core/localization/app_localizations.dart` (28000+줄, 14언어, 26 redemption 키)

### 문서
- `docs/release/store-code-pos-setup.md` — 매장 POS 등록 가이드
- `docs/release/exact-drop-iap-setup.md` — ExactDrop IAP 등록
- `docs/release/exact-drop-launch-checklist.md` — 7 step 출시 체크
- `firestore.rules` — letter / user / brand_zone / consents rule
- `~/.claude/projects/.../memory/MEMORY.md` — 누적 session handoff 인덱스

### Models
- `lib/models/letter.dart` — Letter (redemptionCode + codeRevealedAt + sanitize + _parseDateTime 휴리스틱)
- `lib/models/brand_zone.dart` — BrandZone.redemptionCode + copyWith
- `lib/models/brand_insights.dart` — 4단계 funnel + coachingTip(AppL10n)

### Scripts
- `scripts/release_to_testflight.sh` — 자동 빌드 + ASC 업로드
- `scripts/build_*_release.sh` — 권장 빌드 흐름

---

## 🚨 절대 깨면 안 되는 invariant

1. **매장 코드 흐름**: redemptionCode 발급 시 캠페인 1개 = 코드 1개 (bulk 동일)
2. **per-user state**: clone() 이 codeRevealedAt / redeemedAt null reset
3. **race lock**: sentinel = -now (5분 stale TTL)
4. **계정 전환**: 19 키 user-scoped prefs 정리
5. **Firestore**: revealedCount 화이트리스트 + delta 0/+1
6. **flutter test 127/127** + **flutter analyze clean** 매 PR 검증
7. **commit message**: `feat/fix(scope): 제목 (PR-XX, Build NNN)` 형식

---

## 💡 운영 권장

- TestFlight Build 359 업로드 + Internal group 7명 배포
- Brand 사장 대상 POS 등록 가이드 1page PDF (`docs/release/store-code-pos-setup.md` 기반)
- ExactDrop 50/500 콘솔 등록 후 Brand 사용자에게 알림
- Phase 2 작업 시작점은 proper auth 마이그레이션 (anonymous → email/phone)
