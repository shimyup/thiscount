# Build 362 세션 핸드오프 — 다음 세션 시작점

> 새 세션에서 이 문서 path 를 첫 prompt 로 보내거나, 아래 "다음 세션 prompt"
> 섹션 복붙. 새 Claude 세션이 이 문서 읽고 현재 상태 + 다음 작업 즉시 파악.

---

## 📌 현재 상태 (2026-05-25 p2)

### Git
- main 최신: **`7c49832`** "feat(security): redemption code clipboard 45s TTL auto-clear (PR-AA3, Build 362)"
- pubspec: `1.0.0+362`
- 전 PR 모두 squash merge

### 빌드/배포 상태
- ⏳ **TestFlight 업로드 대기** — Build 324 이후 archive 안 됨 (필요 시 `./scripts/release_to_testflight.sh`)
- ❌ Apple/Google/RC 콘솔 IAP 등록 대기 (ExactDrop 50/100/500 패키지 — PR-T4)

### 검증
- `flutter analyze`: clean
- `flutter test`: 134/134 (1 skipped) — SecureClipboard 7건 추가

---

## 🎯 이번 세션 누적 (Build 360 → 362, **3 PRs**)

### PR-AA1 — BrandZone setup 코드 토글 (Build 360, [#98](https://github.com/shimyup/thiscount/pull/98))
- admin 특별 메시지 zone 화면 + compose zone 분기에 매장 POS 코드 자동 부여 토글.
- zone 1개 = 코드 1개 → 발급되는 모든 letter 가 동일 코드 공유 (POS 1회 등록).
- **P0 fix**: `BrandZoneService.createZone()` 스키마 — 이전 `centerLat`/`centerLng` 평면이 `BrandZone.fromJson(j['center'] as Map)` 와 mismatch → silent parse-skip 으로 compose 로 만든 zone 이 cache 진입 실패. `center: mapValue {lat, lng}` 로 admin 과 통일.
- `_RecentZonesList` 카드에 🎫 코드 + 복사 액션 표시.

### PR-AA2 — EU/SEA letter→쿠폰 9언어 정리 (Build 361, [#99](https://github.com/shimyup/thiscount/pull/99))
- PR #87 deferred ~270 인스턴스 일괄 처리.
- fr(lettre→coupon, 분사 일치 envoyée→envoyé)/de(Brief→Coupon, Briefkasten/Briefmarke 보존)/es(carta→cupón)/pt(cupom)/it(coupon)/ru(6 격)/tr(접미사)/ar(قسيمة)/hi(कूपन)/th(คูปอง).
- 보존: it 'Carta regalo' (gift card), de 'Briefkasten'/'Briefmarke', it 'letterario'.
- 사용자 facing letter 단어 0건 (코드 식별자는 유지).

### PR-AA3 — Redemption code clipboard 45s TTL (Build 362, [#100](https://github.com/shimyup/thiscount/pull/100))
- 신규 `SecureClipboard` 유틸 + 7 secret-copy 사이트 전환.
- `copyEphemeral(text, ttl: 45s)`: 즉시 복사 + 45초 후 우리 값 일치 시 빈 문자열 clear.
- `copyPersistent(text)`: TTL 없음, 직전 timer cancel (share text 등 비-비밀).
- background 시 clear skip (iOS 14+ paste prompt 회피).
- 단위 테스트 7건 (TTL clear / 사용자 변경 skip / timer cancel / persistent 보호).

---

## 📋 백로그 (다음 세션 추천)

### 1. WCAG 2.1 AA fix 라운드 (PR-BB 시리즈)
이번 세션 audit 결과 ~280건 식별. 우선순위:
- **P0 색상 토큰 재조정** — `AppPalette.textMuted` `#5A5A5F` / Light `#8E8E96` 4.5:1 fail. 토큰만 바꾸면 30+ 곳 일괄 fix
- **P0 IconButton tooltip 9건** — VoiceOver 사용자가 액션 식별 불가 (legal risk)
- **P0 SnackBar 대비** `compose_screen.dart:372` teal+white = 1.9:1
- **P1 RTL `EdgeInsets.fromLTRB` 157곳 → `EdgeInsetsDirectional.fromSTEB` 일괄 치환** (ar 사용자)
- **P1 Image `semanticLabel` 14곳**

상세: `~/.claude/projects/.../memory/wcag_audit_2026_05_25.md`

### 2. 보안 hardening 잔여
- HTTPS certificate pinning — cert rotation OTA mechanism (Remote Config) 설계 필요
- AppLifecycle reauth (idle 10분 후) — admin email 만 적용
- FCM 토큰 정책 (logout 시 unregister)
- Session timeout / remote logout

### 3. 운영 polish
- 알림 timezone fractional offset (flutter_timezone 패키지)
- 지도 Consumer rebuild 최적화 (select)
- `_findRecentMatchingCode` 성능 indexing
- 알림 sound 우선순위

### 4. Phase 2 — proper auth 마이그레이션
가장 큰 unlocker. 별도 아키텍처 세션:
- Letter / User / BrandZone update owner check (Cloud Function gating)
- redemptionCode public read 분리 (sub-collection + sender-only rule)
- 다중 디바이스 sync (codeRevealedAt / blocks / longestStreak)
- GDPR sub-doc cleanup 자동화
- 서버 API key 발급 (Twilio / SendGrid)

### 5. 추가 시뮬레이션 영역
- WCAG audit (이번 라운드 완료 — 다음 라운드 fix 적용 후 재 audit)
- 마케팅 SEO (Apple Search / App Store description)
- 분쟁 / 클레임 처리 흐름
- 재무 / 결제 audit (RevenueCat receipt 위조)
- 부적절 컨텐츠 ML 검출

---

## ✅ 보장된 동작 (Build 362 stable)

PR-AA1 ~ AA3 만 신규 — Build 359 (`SESSION_HANDOFF_BUILD_359.md`) 의 모든
보장 동작 그대로. 추가:

### 매장 POS 코드 zone
- ✅ admin/compose 양쪽에서 zone 1개 = 코드 1개 부여 가능
- ✅ admin 화면 _RecentZonesList 에 🎫 + 복사 액션
- ✅ createZone 스키마 정상화 (mapValue center)

### i18n
- ✅ 14언어 letter 단어 0건 (사용자 facing 영역)

### 보안
- ✅ Redemption code clipboard 45s TTL auto-clear (7 사이트)
- ✅ SecureClipboard.copyPersistent 가 ephemeral timer 호환

---

## 💬 다음 세션 prompt (복붙)

```
/Users/shimyup/Documents/New project/Lettergo/SESSION_HANDOFF_BUILD_362.md
파일 읽고 현재 상태 + AA 시리즈 3 PR + 백로그 파악 후, 다음 중 우선순위 정해 진행:

  A. WCAG 280건 fix 라운드 (P0 색상 토큰 + tooltip + RTL)
  B. Phase 2 proper auth (Cloud Function 기반)
  C. 보안 hardening (cert pinning OTA / FCM token 정책 / session timeout)
  D. 추가 시뮬레이션 라운드 (마케팅 SEO / 분쟁 처리 / 결제 audit)
  E. TestFlight Build 362 archive + upload (사용자 작업)
  F. 사용자가 별도로 지시한 작업

매 PR 마다 commit + push (feature branch + squash merge 패턴).
flutter analyze + flutter test 매 PR 검증. 보안 영역은 항상 같이 점검.
```

---

## 📁 핵심 파일 추가 (이번 세션)

- `lib/core/utils/secure_clipboard.dart` — `SecureClipboard.copyEphemeral` / `copyPersistent`
- `test/secure_clipboard_test.dart` — 7건 unit test
- `lib/features/admin/admin_special_message_screen.dart` — `_attachCode` 토글 + 🎫 표시
- `lib/core/services/brand_zone_service.dart` — `createZone(redemptionCode:)` + center mapValue 스키마

WCAG audit: `~/.claude/projects/.../memory/wcag_audit_2026_05_25.md`

---

## 🚨 절대 깨면 안 되는 invariant (Build 359 + 추가)

1. 매장 코드 흐름: redemptionCode 발급 시 캠페인 1개 = 코드 1개 (bulk 동일)
2. per-user state: clone() 이 codeRevealedAt / redeemedAt null reset
3. race lock: sentinel = -now (5분 stale TTL)
4. 계정 전환: 19 키 user-scoped prefs 정리
5. Firestore: revealedCount 화이트리스트 + delta 0/+1
6. **flutter test 134/134** + **flutter analyze clean** 매 PR 검증
7. commit message: `feat/fix(scope): 제목 (PR-XX, Build NNN)` 형식
8. **신규 (PR-AA3)**: 매장 POS 코드 / 프로모션 코드 / invite 코드 등 SECRET 텍스트 copy 는 `SecureClipboard.copyEphemeral()` 사용. 일반 share text 는 `Clipboard.setData` 또는 `SecureClipboard.copyPersistent()`.
9. **신규 (PR-AA1)**: `BrandZoneService.createZone()` 의 center 필드는 `mapValue {lat, lng}` — 평면 centerLat/centerLng 로 회귀 금지 (silent parse-skip P0).
