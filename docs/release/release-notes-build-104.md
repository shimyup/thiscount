# Release Notes — Build 104 (1.0.0+104)

Date: 2026-04-19

Build 102–104 3연속 업데이트를 한 번에 묶은 노트. 세 빌드 모두 같은
방향성("편지 줍기 / 보물찾기" 전환)의 단계적 롤아웃이며 기능상 연결되어
있어 하나의 릴리즈로 묶어 설명합니다. Build 101 이전(94–98, 99–101)의
기능 요약은 각각 [release-notes-build-98.md](release-notes-build-98.md) ·
[release-notes-build-101.md](release-notes-build-101.md) 참조.

- Build 102 — 줍기 햅틱 · XP/레벨 1–50 · Brand 정확 좌표 드롭
- Build 103 — 5탭 네비 · 답장 무제한 · 등급별 반경 · 편지 카테고리 · 3단 개봉 애니메이션
- Build 104 — Brand = 발송 전용 포지셔닝 확정

---

## 🇰🇷 Korean

### 🎯 포지셔닝 전환: 브랜드는 뿌리는 쪽, 회원은 줍는 쪽 (Build 102·103·104)

Letter Go 의 루프를 "지도 전역에 흩뿌려진 할인권·이벤트 편지를 주워 활용하는
보물찾기"로 재정의했습니다. Brand 계정은 편지를 만들고 "떨어뜨리는" 쪽,
Free·Premium 은 가까이 다가가서 "줍는" 쪽.

### 🎮 등급별 줍기 반경 (Build 103)

`pickupRadiusMeters` 가 단일 진입점이 되었고, 등급에 따라 실제 줍기 거리가
달라집니다.

| 등급 | 줍기 반경 | 쿨다운 |
|------|-----------|--------|
| Free | **200m** | 60분 |
| Premium | **1km** | 10분 |
| Brand | **차단** | 해당 없음 |

### 👑 Brand = 발송 전용 (Build 104)

- 지도 상단 오렌지 배너: "당신은 발송 전용 계정입니다"
- 줍기 시도 시 `statePickupBrandBlocked` 로컬라이즈 에러 (14개 언어)
- 줍기 반경 0m + `pickUpLetter()` 진입 가드 이중 차단
- 근처 알림·인박스 힌트도 Brand 계정에서는 숨김

Free·Premium 은 인박스 상단에 티일 톤 힌트 "🎟 주변에 뿌려진 할인권·이벤트
편지를 주워 활용해보세요" 가 노출됩니다.

### 🗺 Brand 전용 정확 좌표 드롭 (Build 102)

브랜드가 보낼 때 지도를 직접 찍어 떨어뜨리는 `ExactDropPicker` 가 추가되었어요.
기존 "도시 선택" 모드와 병행 사용 가능. flutter_map 기반.

### ✉️ 편지 카테고리 (Build 103)

- `LetterCategory { general, coupon, voucher }` 필드 신설
- 작성 화면의 브랜드 전용 패널에 🎟 할인권 / 🎁 교환권 / ✉️ 일반 선택 UI
- 수집첩 상단 필터에 "할인권·교환권" 칩 추가
- 편지 카드의 브랜드 뱃지가 카테고리에 따라 색을 바꿉니다 (티일 = 쿠폰/교환권, 오렌지 = 일반)
- **서버 가드**: Free/Premium 계정이 coupon/voucher 로 요청해도 강제로 `general`
  로 기록됨 — 일반 회원이 위조 쿠폰을 발행할 수 없음

### 🧭 5탭 바텀 네비 (Build 103)

중앙의 금빛 펄스 FAB ("편지 쓰기") 가 사라지고 5개 탭으로 재편되었습니다.

  **탐험 · 수집첩 · 보내기 · 타워 · 프로필**

보내기가 다른 주요 활동과 동등한 탭으로 승격되어, "자주 여는 액션"이 아니라
"게임의 한 기둥"처럼 배치됩니다.

### 🎬 3단 개봉 애니메이션 (Build 103)

편지 개봉이 1200ms 2단 → **1500ms 3단**으로 확장되었습니다.

1. **Phase 1 (0.0–0.3, 400ms)** — 봉투가 아래에서 올라옴 (light haptic)
2. **Phase 2 (0.3–0.6, 350ms)** — 실링이 터지며 좌우로 약간 흔들림 (medium haptic + system click)
3. **Phase 3 (0.6–1.0, 750ms)** — 편지지가 scale 0.85 → 1.0 으로 펼쳐짐 (heavy haptic)

줍기(Build 102) → 열기(Build 103) 까지 햅틱 리듬이 일관되게 이어집니다.

### 📬 답장 무제한 (Build 103)

"편지당 1회 답장" 제한이 사라졌습니다. `hasReplied` 는 이제 gate 가 아니라
최근성 힌트. 이미 답장한 편지의 버튼 라벨은 "다시 답장 쓰기" 로 바뀌고
아래에 작은 이탤릭 안내가 붙습니다.

### 🏆 XP + 레벨 1–50 (Build 102)

Free/Premium 전용 경험치 시스템이 추가되었어요. 편지 송·수신·답장으로 XP
가 쌓이며 Level 1–50 진행 표시. Brand 는 제외 — 대신 "👑 공식 발송인"
배지가 유지됩니다.

### 🖐 줍기 햅틱 (Build 102)

`FeedbackService.onLetterPickUp()` 신설. 등급별로 강도가 미세하게 다르며,
Brand 가 있는 흐름(테스트·스크린샷 등 발송 계정 체크) 에서는 heavy-tap
추가 레이어가 붙습니다.

---

## 🇺🇸 English

### 🎯 Positioning shift: brands drop, members hunt (Build 102·103·104)

Letter Go's core loop was reframed. Brand accounts are now broadcasters that
scatter promo / coupon / event letters across the world; Free and Premium
members walk up to them and pick them up.

### 🎮 Tier-based pickup radius (Build 103)

A single `pickupRadiusMeters` source of truth:

| Tier | Pickup radius | Cooldown |
|------|---------------|----------|
| Free | **200m** | 60 min |
| Premium | **1km** | 10 min |
| Brand | **blocked** | n/a |

### 👑 Brand = send-only (Build 104)

- Orange banner at the top of the map: "You are a send-only account"
- Pickup attempts return a localized `statePickupBrandBlocked` error (14 languages)
- Double-blocked: radius=0m AND explicit guard in `pickUpLetter()`
- Nearby-letter alerts and inbox hints are hidden for brand accounts

Free and Premium now see a teal inbox hint: "🎟 Pick up promo and event
letters dropped nearby."

### 🗺 Brand-only exact-coordinate drop (Build 102)

`ExactDropPicker` — a flutter_map picker where brand accounts tap the exact
coordinate they want a letter to land on. Runs alongside the existing
city-picker mode.

### ✉️ Letter categories (Build 103)

- New `LetterCategory { general, coupon, voucher }` field.
- Brand compose panel now has 🎟 Coupon / 🎁 Voucher / ✉️ General chips.
- Inbox filter bar gained two new chips for coupon/voucher.
- Brand badges recolor by category (teal for coupon/voucher, orange for general).
- **Server guard**: if a Free/Premium caller sends with `coupon`/`voucher`,
  the server forces `general` — regular users can't mint fake coupons.

### 🧭 5-tab bottom nav (Build 103)

The gold-pulse central FAB is gone. Five peer tabs instead:

  **Explore · Collection · Send · Tower · Profile**

Send is now leveled with explore / collection / tower / profile — it's a
pillar of the experience, not a floating shortcut.

### 🎬 3-phase open animation (Build 103)

Letter open grew from 1200ms / 2 phases to **1500ms / 3 phases**:

1. **Phase 1 (0.0–0.3, 400ms)** — envelope rises from below (light haptic)
2. **Phase 2 (0.3–0.6, 350ms)** — seal bursts with a horizontal wobble
   (medium haptic + system click)
3. **Phase 3 (0.6–1.0, 750ms)** — letter paper unfolds scale 0.85 → 1.0
   (heavy haptic)

Pickup (Build 102) → open (Build 103) haptic rhythm is now continuous.

### 📬 Reply unlimited (Build 103)

The one-reply-per-letter limit is gone. `hasReplied` is now a recency hint,
not a gate. The reply button is always active; if `hasReplied` is true, the
label becomes "Reply again" with a small italic helper underneath.

### 🏆 XP + Level 1–50 (Build 102)

A Free/Premium progression layer. Sending, receiving, and replying earn
XP; levels 1 to 50 with visible progress. Brand accounts are excluded —
they keep the "👑 Official Sender" badge instead.

### 🖐 Pickup haptic (Build 102)

New `FeedbackService.onLetterPickUp()`. Strength varies subtly by tier; in
Brand-involved flows (internal checks) an extra heavy-tap layer is added.

---

## 🔧 Technical

- 0 new runtime dependencies (reuses existing `flutter_map`, `dart:math`)
- `flutter analyze`: 0 issues
- `flutter test`: 35 passing (11 → 35 across this series)
- Firestore rules unchanged; `lastSeenAt`/`loggedOutAt` (added in Build 99)
  already covered by the existing `/users/{userId}` write rule
- 3 commits: 3f2dcdc (102), 9c18906 (103), f024ce3 (104)
- Version: 1.0.0+101 → 1.0.0+104

### Sensitive points to preserve on future edits

- `pickupRadiusMeters` in `app_state.dart` — single source of truth; 200 / 1000 / 0 affects gameplay balance
- Brand pickup block exists in TWO places (radius=0 AND explicit `pickUpLetter` guard). Keep both
- `LetterCategory` JSON uses `.key`; don't rename enum values without a migration
- Server-side category override (Free/Premium → general) is a security boundary, not a UX decision

---

## 📋 Post-deploy checklist

1. **5-tab nav** — launch the app and confirm 탐험 / 수집첩 / 보내기 / 타워 / 프로필 are visible; the gold-pulse FAB should be gone.
2. **Brand send-only** — log in with a brand test account. Map should show the orange send-only banner. Trying to pick up (via admin tool bypass) should return the blocked error.
3. **Free pickup radius** — stand near a dropped letter as a Free account. Only letters within 200m should promote to `nearYou`.
4. **Premium radius** — repeat with a Premium account, confirm up to 1km.
5. **Exact drop** — as Brand, compose a letter and use the map picker; confirm the letter lands on the tapped coordinate.
6. **Category filter** — in the collection tab, tap 할인권 / 교환권 chips and confirm filtering works.
7. **Reply again** — open a letter that was already replied to; confirm the "다시 답장 쓰기" label + helper text.
8. **3-phase open animation** — open any letter and watch for the rise / seal-burst wobble / unfold. Each phase should fire a distinct haptic on a real device.
9. **XP/Level** — as Free/Premium, send or receive a letter and verify XP increments on the profile screen.
10. **Brand badge color** — a coupon letter should show a teal brand badge; a general-brand letter should stay orange.

---

## 🚀 Store-submission summary

Builds 102–104 bundle together as a single user-facing update ("brand = send,
member = pick up"). Store-facing copy lives in
[release-notes-build-104-paste-ready.md](release-notes-build-104-paste-ready.md).
