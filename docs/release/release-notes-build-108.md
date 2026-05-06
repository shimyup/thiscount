# Release Notes — Build 108 (1.0.0+108)

Date: 2026-04-21

Build 105–108 묶음 릴리즈. 이 노트는 Build 104 릴리즈 이후 이어진 "프로모/
쿠폰 편지 헌트" 방향성의 확정판과 그 과정에서 있었던 포지셔닝 리셋을
정리합니다. Build 104 이전(94–98, 99–101, 102–104) 요약은 각각
[release-notes-build-98.md](release-notes-build-98.md) ·
[release-notes-build-101.md](release-notes-build-101.md) ·
[release-notes-build-104.md](release-notes-build-104.md) 참조.

- **Post-104 patch stream (버전 동일, 1.0.0+104 유지)** — 쿠폰 리디엠션
  필드 · 브랜드 음소거 · 체인 규칙 제거 · 종이 글로우 · 인박스/온보딩
  카피 정리 · 포지셔닝 리셋("모든 등급이 줍고 보낸다")
- **Build 105** — Level 1→50 마일스톤 시트 · 통합 "오늘의 영감" 카드
- **Build 106** — 레벨 보너스 (+10m/Lv) · Lv50 이후 포인트 적립 · Brand
  ExactDrop 유료화 · Free/Premium 브랜드 프로모 팝업
- **Build 107** — 쿠폰 티켓 모양 팝업 · 온보딩 프로모 중심 재작성 ·
  Build 105 의 "오늘의 영감" 카드 제거
- **Build 108** — 쿠폰 "사용 완료" 루프 · 어드민 ExactDrop 크레딧 부여
  UI · 14개 언어 전수 검증

---

## ⚠️ Build 104 포지셔닝 리셋

Build 104 에서 확정한 "Brand = 발송 전용" 정책은 후속 패치(`cc4ef55`,
Build 105 직전)에서 **철회**되었습니다. 새 정책:

- 모든 등급(Free · Premium · Brand)이 편지를 **주울 수 있음**
- Brand 줍기 반경 0 → 1000m (Premium 과 동일)
- 지도 상단 오렌지 "발송 전용" 배너 제거 (`_BrandOnlySendBanner` 위젯
  삭제, 약 60줄)
- `pickUpLetter()` 의 Brand 진입 가드 제거

따라서 Build 104 릴리즈 노트의 "👑 Brand = 발송 전용" 섹션은 더 이상
유효하지 않습니다. 현재 앱에서 모든 등급은 같은 헌트 루프 안에 있습니다.

인박스 구조도 이 리셋에 맞춰 단순화됐어요:

- 탭 3개 → 2개 (`📬 받은` / `📤 보낸`, DM 탭 숨김)
- 편지 읽기 화면의 🌱🕊️📜 펜팔 티어 뱃지 숨김 (데이터는 보존)
- 인박스 필터 칩 7 → 4 (전체 · 할인권 · 교환권 · 브랜드), 상태 필터는
  편지 카드 안의 라벨로만 표시

> 데이터 모델(`PenpalStats`, `PenpalTier`, DM 컬렉션)은 모두 보존됩니다.
> UI 만 숨긴 상태라 나중에 마이그레이션 없이 되살릴 수 있어요.

---

## 🇰🇷 Korean

### 🎟 쿠폰 리디엠션 루프 (post-104 + Build 108)

편지 안의 쿠폰을 "실제로 쓴다"라는 흐름이 완성됐어요. 과정은 두 단계
였습니다.

**1단계 (post-104, `48c9593`)** — `Letter.redemptionInfo` (최대 200자)
필드 추가. 브랜드가 작성 화면에서 🎟 할인권 / 🎁 교환권 을 고르면 "사용
코드·링크·매장 안내" 입력 필드가 표시되고, 수신자의 편지 읽기 화면에서
🎁 티일 그라디언트 카드로 렌더됩니다. 본문은 `SelectableText` 라 코드는
길게 눌러 복사 가능.

> 서버 가드: `Letter.redemptionInfo` 는 `isBrand` 호출자만 저장됨.
> Free/Premium 이 param 을 포함해도 서버에서 `null` 로 처리.

**2단계 (Build 108)** — 수신자가 쿠폰을 사용한 뒤 "🎫 사용 완료 표시"
버튼을 누를 수 있어요. 눌린 편지는:

- 카드가 회색으로 페이드
- 본문이 취소선으로 전환
- 헤더가 "사용 완료된 혜택" 으로 변경
- 우상단에 ✓ "사용됨" 뱃지
- 토스트: "사용 완료로 표시했어요"

브랜드 측 집계는 `myRedeemedSentCount` getter 로 노출 (현재는 로컬
디바이스 기준 — 서버 집계는 다음 이정표).

### 🔕 브랜드 음소거 (post-104)

스팸 방지 1차 도구. 편지 읽기 화면 상단의 🔕 아이콘을 누르면 해당
브랜드의 **이후 편지**가 인박스에서 숨겨집니다. 이미 받은 편지는 유지
되므로 지난 쿠폰은 계속 쓸 수 있어요. 🔔 로 다시 켤 수 있고 되돌리기
토스트는 따로 뜨지 않습니다(켤 때만 안내).

### 🏆 레벨 마일스톤 시트 (Build 105)

XP/레벨 시스템(Build 102)이 현재 레벨만 보여줬을 때의 "어디까지 가는
거지?" 질문을 해결합니다. 프로필 XP 바 아래의 🏆 버튼을 누르면 10개
티어가 전부 펼쳐진 바텀시트가 올라와요.

| 레벨 | 티어 |
|------|------|
| 1–4 | 🏠 견습 집배원 |
| 5–9 | 🏡 초보 배송원 |
| 10–14 | 📬 숙련 집배원 |
| 15–19 | 📮 마을 우체장 |
| 20–24 | 🏢 도시 우편장 |
| 25–29 | 🏬 구름 우편국장 |
| 30–34 | 🏙 하늘 기록자 |
| 35–39 | 🛰 천공의 필경사 |
| 40–44 | 🌍 세계의 집배원장 |
| 45–50 | 👑 전설의 편지꾼 |

각 행에 XP 임계값 · 티어 라벨 · 상태 마커(✅ 달성 · 🟡 "지금 여기" 골드
필 · 🔒 미개방)가 함께 표시됩니다.

### 🎯 레벨 보너스 + 포인트 (Build 106)

레벨업이 단순한 뱃지가 아니라 **게임플레이 이득**이 됩니다.

- 레벨마다 **줍기 반경 +10m** (Free/Premium 에만 적용, Brand 고정 1km)
  - Free: 200m → 최대 690m (Lv 50)
  - Premium: 1000m → 최대 1,490m (Lv 50)
- 프로필 XP 카드에 한 줄 안내: "줍기 반경 240m (레벨 보너스 +40m)"
- Lv 50 도달 후에는 **포인트 적립** 모드로 전환. `userPoints` = `(XP -
  120,050) / 50`, 즉 줍기 5번당 1 포인트 누적. XP 카드에 🪙 골드 테두리
  칩 + "구독 시 사용" 힌트가 뜹니다. (실제 구독 전환 로직은 후속 스코프)

### 💰 Brand 전용 정확 좌표 드롭 유료화 (Build 106)

`ExactDropPicker` 가 더 이상 무료가 아닙니다.

- **100통 당 ₩10,000** (현재는 어드민이 수동 부여)
- 브랜드가 크레딧 없이 "정확 좌표 드롭"을 누르면 페이월 다이얼로그가
  뜨고 support@airony.xyz 로의 문의 링크가 열립니다
- 크레딧 차감은 **보내기 실행 시**에만 발생 — 지도만 열고 취소하면
  차감되지 않음
- 레이스 방지: 전송 직전 잔고 체크, 실패 시 에러 스낵바 + `_isSending`
  리셋

어드민 화면(Build 108)에서는 "🎯 ExactDrop 크레딧" 박스가 "시스템 편지
발송" 바로 아래 표시되고 바텀시트에서:

- [+ 100 (₩10,000)] 골드
- [+ 1,000 (₩100,000)] 티일
- [Reset to 0] 아웃라인

3가지 액션으로 잔고를 조정할 수 있어요. 실결제 연동은 후속 작업.

### 🎁 브랜드 프로모 팝업 (Build 106 → 107 리디자인)

로그인 후 홈 화면 첫 프레임(스트릭/레벨업 배너 뒤, 1.2초 후)에 브랜드
쿠폰 편지를 소개하는 팝업이 뜹니다. Build 106 에선 단순 AlertDialog 였고,
Build 107 에서 **실제 쿠폰 티켓처럼 보이는 모달**로 리디자인 됐어요.

- 골드 그라디언트 바디 + 딥골드 타이포
- 좌우 V-notch 절단 (바리어 블랙과 매치돼 "종이가 잘려나간" 느낌)
- 🎟 LIMITED OFFER 상단 리본
- 제목/만료일 사이 점선 디바이더
- 우상단 닫기 아이콘, 하단 "닫기 누르면 오늘은 안 보여요"

콘텐츠는 `AppState.featuredBrandPromo` 가 `_worldLetters` 에서 가장 최근
의 유효(만료 안 된) 브랜드 쿠폰/교환권 편지를 선택합니다. 활성 캠페인이
없으면 팝업은 조용히 스킵됩니다. 만료 남은 시간은:

- < 24h → "12시간 남음"
- ≥ 24h → "3일 남음"
- null → "기간 제한 없음"

Brand 계정에는 뜨지 않고, 닫으면 세션 동안 다시 나타나지 않아요 (콜드
스타트 시 리셋).

### 🧭 온보딩 프로모 중심 재작성 (Build 107)

페이지 3·4·5 의 타이틀·본문을 "펜팔 소셜" → "할인·홍보 편지 헌트" 로
재조정했습니다.

- **페이지 3** — "🗺 편지를 주워요" → **"🎟 할인·홍보 편지를 주워요"**
- **페이지 4** — "🌗 시간대별 화면" → **"🎁 즉시 사용 가능한 혜택"**
  (본문: "주운 편지 안에 할인 코드·URL·매장 안내가 들어있어 바로 쓸
  수 있어요. 브랜드마다 유효 기간이 설정되니 놓치지 마세요.")
- **페이지 5** — 5탭 소개 대신 "지도를 열어 근처의 할인·홍보 편지를
  주워보세요. 받은 편지 안 코드·링크로 바로 혜택을 사용할 수 있어요."

페이지 4의 🌗 이모지는 🎁 로 교체. 14개 언어 모두 재번역.

### ✏️ 작성 화면 재구성 (post-104)

첫 사용자가 스크롤 없이 편지를 쓸 수 있도록 본문 TextField 를 맨 위
가까이로 올렸어요. 순서:

1. STEP 1 · 목적지 선택
2. STEP 2 · 편지 본문 ← TextField 가 destination 바로 아래
3. STEP 3 · 더 많은 옵션 ← ExpansionTile (기본 접힘)

옵션(요일 테마, 퀵픽, SNS 토글, 익명, 브랜드 옵션, 스타일바, 이미지,
행운의 편지, 지난 편지 불러오기, 이달의 도시) 은 전부 `ExpansionTile`
안에 들어갑니다.

> Build 105 에서 추가했던 통합 "🎯 오늘의 영감" 카드는 Build 107 에서
> 헌트 포지셔닝에 맞지 않는다는 판단으로 제거되었습니다. 하위 빌더 함수
> (`_buildDayThemeBanner`, `_buildQuickPickRow`, `_buildCityOfMonthHint`)
> 는 파일에 남아있지만 렌더 트리에서 호출되지 않습니다 — 재사용이 쉬울
> 수 있도록 보존.

### 🧹 잡다 정리 (post-104)

- **체인 규칙(3통 보내야 다음 편지 열기) 완전 제거** — 코드 게이트도
  삭제. `canViewNextLetter` 는 항상 `true`. 인박스 🔒 프로그레스 배너
  약 52줄 제거.
- **편지지 글로우** — 포커스 시 골드 22% alpha / 18px blur 의 `BoxShadow`
  가 은은하게 뜸. 테두리도 0.4 → 0.55 로 강조. 본문 TextField minLines
  8 → 10 으로 "나는 편지를 쓰고 있다" 감각을 첫 페인트에 전달.
- **5가지 시뮬레이터 검증 UI 픽스** — 인박스 페이지 타이틀 "편지함" →
  "수집첩", "(이)가" Korean 조사 이슈 제거, 헌트 필터 빈 상태 CTA를
  "지도에서 찾아보기" 로 교체, 특급 배송 괄호 → · 구분자, "0/3통 · 남은
  3통" 중복 안내 제거.
- **하드코딩 한국어 11개 로컬라이즈** — 인박스 통계 칩 3개 · 설정 고객
  지원 5개 · 회원탈퇴 확인 3개. 14개 언어.
- **인박스 필터별 빈 상태 카피** — `inboxEmptyForFilter(filterName)`
  파라메트릭 함수 도입: "🎟 아직 할인권 편지가 없어요" 등. 14개 언어.

### 🌐 14개 언어 전수 검증 (Build 108)

Build 106/107/108 에서 새로 추가된 모든 `_t({...})` 키와 파라메트릭
switch 를 14개 언어(ko, en, ja, zh, fr, de, es, pt, ru, tr, ar, it,
hi, th) 전부에 대해 일괄 점검했습니다. 누락 없음.

파라메트릭 switch 검증 완료: `inboxEmptyForFilter`, `xpPickupBonusDesc`,
`xpPointsLabel`, `xpMilestoneXpReq`, `xpMilestonesFootnote`. 모든 언어
case + default fallback 모두 존재.

---

## 🇺🇸 English

### 🎟 Coupon redemption loop (post-104 + Build 108)

The "actually use the coupon" flow came together in two stages.

**Stage 1 (post-104, `48c9593`)** — `Letter.redemptionInfo` (max 200
chars). When brands compose with 🎟 Coupon or 🎁 Voucher selected, a
new TextField appears for "how to redeem — code / link / store
instructions." Receivers see it as a teal-gradient 🎁 card between the
letter body and the reply button. Body is `SelectableText` so codes can
be long-pressed and copied.

> Server guard: `redemptionInfo` only persists for `isBrand` callers;
> Free/Premium requests with the param are forced to `null`.

**Stage 2 (Build 108)** — After redeeming, receivers tap "🎫 Mark as
used." The card then:

- Fades to gray, body text gets strikethrough
- Header changes to "Redeemed offer"
- ✓ "Used" badge appears top-right
- Toast: "Marked as used"

Brand-side local count via `myRedeemedSentCount`. Cross-device
aggregation is a follow-up.

### 🔕 Brand mute (post-104)

First-pass spam defense. A 🔕 icon at the top of the letter-read screen
hides future letters from that brand in the inbox. Previously received
letters stay (past coupons remain usable). Reversible via 🔔. Only
muting shows a toast.

### 🏆 Level 1→50 milestones sheet (Build 105)

The XP/Level system from Build 102 showed your current level but not
the ceiling. A new 🏆 button below the XP bar opens a sheet listing all
10 five-level tiers with XP threshold, tier label, and state marker
(✅ passed · 🟡 "You are here" gold pill · 🔒 locked).

### 🎯 Level bonus + points (Build 106)

Levels now give concrete gameplay gain.

- **+10m pickup radius per level** (Free/Premium only; Brand stays at
  1000m flat)
  - Free: 200m → up to 690m at Lv 50
  - Premium: 1000m → up to 1,490m at Lv 50
- Profile XP card shows: "Pickup radius 240m (level bonus +40m)"
- After Lv 50, **points** mode kicks in. `userPoints = (XP - 120,050) /
  50` — 1 point per ~5 pickups. XP card gets a 🪙 gold-border pill with
  "Use on subscription" hint. (Redemption wiring is follow-up scope.)

### 💰 Paid brand ExactDrop (Build 106)

`ExactDropPicker` is no longer free.

- **100 letters per ₩10,000** — admin-granted for now
- Tapping "Exact-coordinate drop" with 0 credits opens a paywall dialog
  with a mailto link to support@airony.xyz
- Credit only consumed **at send time** — opening the map and backing
  out is free
- Race guard: balance re-checked right before send; on 0, error
  snackbar + `_isSending` reset

Admin screen (Build 108) gains a "🎯 ExactDrop credits" box under
"Send system letter" with a bottom sheet:

- [+ 100 (₩10,000)] gold
- [+ 1,000 (₩100,000)] teal
- [Reset to 0] outlined

Real payment wiring is follow-up.

### 🎁 Brand promo popup (Build 106 → 107 redesign)

After login, on the first frame of the home scaffold (1.2s after
streak/level-up banners), a popup introduces brand coupon letters. In
Build 106 this was a plain AlertDialog; Build 107 redesigned it as an
actual coupon-ticket-shaped modal (`_BrandPromoTicket`):

- Gold gradient body with deep-gold typography
- Side V-notches matching the black barrier (looks like paper cut out)
- 🎟 LIMITED OFFER header ribbon
- Dashed divider between title and expiry
- Close icon top-right, "Close = hidden for today" footnote

Content source: `AppState.featuredBrandPromo` picks the most recent
non-expired brand coupon/voucher from `_worldLetters`. If no active
campaign, the popup is silently skipped. Expiry formats:

- <24h → "12 hours left"
- ≥24h → "3 days left"
- null → "No expiration"

Brand accounts never see it; close → session-only dismissal (resets on
cold start).

### 🧭 Onboarding rewrite — promo-first (Build 107)

Pages 3·4·5 retargeted from "pen-pal social" to "discount/promo letter
hunt":

- **Page 3** "🗺 Pick up letters" → **"🎟 Pick up discount / promo
  letters"**
- **Page 4** "🌗 Time-aware UI" → **"🎁 Instantly usable rewards"**
  ("Picked-up letters include discount codes, URLs, or store info you
  can use right away. Brands set their own expiry — don't miss out.")
- **Page 5** 5-tab intro → "Open the map to pick up promo and discount
  letters nearby. Use the code/link inside to redeem on the spot."

Page 4 emoji also changed 🌗 → 🎁. All 14 languages re-translated.

### ✏️ Compose screen restructured (post-104)

First-time users can now write without scrolling past config. New
order:

1. STEP 1 · Destination
2. STEP 2 · Letter body ← TextField right under destination
3. STEP 3 · More options ← ExpansionTile (collapsed by default)

All config (day theme, quick-pick, social, anonymous, brand options,
style bar, photo, lucky letter, recall, city-of-month) moved inside an
`ExpansionTile` with a ⚙️ icon and gold rotation chevron.

> The unified "🎯 Today's inspiration" card added in Build 105 was
> removed in Build 107 as it no longer matched the hunt positioning.
> The builder methods stay in the file (unreferenced) for future reuse.

### 🧹 Cleanup (post-104)

- **Chain rule (send 3 to read next) fully removed** — the inbox 🔒
  progress banner (~52 lines) deleted, `canViewNextLetter` hardcoded to
  `true`, per-card `isLocked` forced `false`.
- **Letter paper glow** — focus adds a soft gold `BoxShadow` (22%
  alpha, 18px blur); border accent 0.4 → 0.55; body TextField minLines
  8 → 10 so the paper dominates first paint.
- **5 simulator-verified UI fixes** — inbox page title "편지함" → "수집첩"
  to match the nav label; Korean particle "(이)가" dropped from empty
  states; hunt-filter empty-state CTA routes to map instead of compose;
  express-delivery parens → ·; quota "remaining" suffix removed.
- **11 hardcoded Korean strings localized** — inbox stat chips ×3,
  settings customer support ×5, account-delete confirmation ×3. All 14
  languages.
- **Filter-aware inbox empty states** — new parametric
  `inboxEmptyForFilter(filterName)` ("🎟 No coupons yet" etc.) in all
  14 languages.

### 🌐 14-language audit (Build 108)

Every `_t({...})` key and parametric switch added in Build 106/107/108
was verified across ko, en, ja, zh, fr, de, es, pt, ru, tr, ar, it, hi,
th. No gaps.

Parametric switches checked: `inboxEmptyForFilter`,
`xpPickupBonusDesc`, `xpPointsLabel`, `xpMilestoneXpReq`,
`xpMilestonesFootnote` — all have per-language branches plus default
fallback.

---

## 🔧 Technical

- Runtime deps unchanged across 105–108 (still reuses existing
  `flutter_map`, `shared_preferences`, `dart:math`)
- `flutter analyze`: 0 issues
- `flutter test`: 35 passing (unchanged — no new test surface since
  Build 104)
- Version: `1.0.0+104` → `1.0.0+108` (Builds 105, 106, 107, 108 each
  bumped; post-104 patch stream stayed at +104)
- 10 commits from `f024ce3..6482f5b` in `scripts/build_*_release.sh`
  invocation
- Android AAB 54 MB · iOS IPA 36 MB, built sequentially (parallel tool
  crash seen earlier), copied to main project `build/`

### Firestore rules — no changes required

Reviewed `firestore.rules` vs. Builds 105–108 data writes. All new
state is **local** (SharedPreferences / in-memory), not Firestore:

| Feature (build) | Storage | Rules impact |
|-----------------|---------|--------------|
| `_redeemedLetterIds` (108) | SharedPreferences `redeemedLetterIds` | none |
| `_brandExactDropCredits` (106) | SharedPreferences `brandExactDropCredits` | none |
| `_mutedBrandIds` (post-104) | SharedPreferences `mutedBrandIds` | none |
| `_promoShownThisSession` (107) | in-memory bool | none |
| Points derivation (106) | pure-derived from XP | none |
| Level bonus radius (106) | pure-derived from XP | none |
| `Letter.redemptionInfo` (post-104) | existing `letters/{id}` doc | covered |
| `Letter.acceptsReplies` (post-104) | existing `letters/{id}` doc | covered |

`lastSeenAt` / `loggedOutAt` (Build 99) remain covered by the existing
`/users/{userId}` write rule. No rule additions needed.

### Sensitive points to preserve on future edits

- `pickupRadiusMeters` in `app_state.dart` now layers **base (200 /
  1000 / 1000) + `(currentLevel - 1) × 10`**. Changing either affects
  gameplay balance. Brand no longer gets a 0m gate.
- Build 104's "Brand = send-only" early-return in `pickUpLetter()` is
  **gone**. Don't reintroduce it without explicit product agreement.
- `Letter.redemptionInfo` and `Letter.acceptsReplies` are both
  isBrand-only at the server guard. Free/Premium forging these is
  blocked server-side — not just UI.
- `_redeemedLetterIds` is one-way (`markLetterRedeemed` only — no
  unmark). Intentional so brand-side counts stay stable.
- Build 105's unified "🎯 오늘의 영감" card is removed but the three
  builder methods (`_buildDayThemeBanner`, `_buildQuickPickRow`,
  `_buildCityOfMonthHint`) are preserved unreferenced — don't delete
  them in a refactor sweep; they're meant to be re-mountable.
- `PenpalStats`, `PenpalTier`, and DM-related models/collections are
  preserved even though their UI is hidden. No cleanup sweep on these
  without explicit product call.

---

## 📋 Post-deploy checklist

**Redemption loop**
1. As a Brand, compose a 🎟 Coupon letter with `redemptionInfo = "CODE25"`.
   Send it.
2. As Free/Premium, pick it up → open → confirm the teal redemption card
   shows `CODE25` with `SelectableText` (long-press copies).
3. Tap "🎫 사용 완료 표시" → card fades to gray, strikethrough body,
   ✓ "사용됨" badge appears, toast "사용 완료로 표시했어요".
4. Re-open the letter → redeemed state persists (no un-mark).

**Level + points**
5. As Free at Lv 1 → profile XP card reads "줍기 반경 200m (레벨 보너스
   +0m)".
6. Pick up several letters to level up → radius string updates with the
   +Xm bonus.
7. (Manual test) Bump a test account to Lv 50 + XP past 120,050 → 🪙
   gold points pill appears with "구독 시 사용" hint.

**Paid ExactDrop**
8. As Brand with 0 credits → tap exact-coordinate drop → paywall dialog
   with "관리자 문의" (mailto) renders.
9. Admin → grant +100 → Brand taps exact drop again → map picker opens,
   credit deducts only after tap send.
10. Open and close the picker without sending → balance unchanged.

**Brand promo ticket**
11. Brand creates a 🎟 Coupon letter with 12h auto-expire → wait 1.2s
    after login → gold ticket modal appears, expiry line reads "12시간
    남음".
12. Close → reopen app (hot restart, not cold) → ticket doesn't
    re-appear.
13. Cold start → ticket re-appears (session-only dismissal, no
    persistent throttle).
14. Active campaign none → popup silently skipped.

**Brand mute**
15. Open a brand letter → tap 🔕 → confirm mute toast.
16. Brand sends another letter → doesn't appear in inbox, but previous
    ones remain visible and usable.
17. Tap 🔔 → unmute silent (no toast), new letters from that brand
    show up again.

**Onboarding**
18. Fresh install → page 3 title "🎟 할인·홍보 편지를 주워요", page 4
    title "🎁 즉시 사용 가능한 혜택", page 5 body mentions
    "근처의 할인·홍보 편지".

**Compose restructure**
19. Open compose → destination → body → options (collapsed). No scroll
    needed to reach body.
20. Expand options → 🎯 "오늘의 영감" card is **absent** (Build 107
    removal).

**Inbox**
21. Inbox page title = "수집첩", not "편지함".
22. Filter chips: 4 visible (전체 · 할인권 · 교환권 · 브랜드).
23. Tab bar: 2 tabs (받은 · 보낸), no DM tab.
24. Empty state for 할인권 filter reads "🎟 아직 할인권 편지가 없어요",
    CTA "지도에서 찾아보기" (routes to `/home`).

**Language check**
25. Switch to en / ja / zh / fr → all new strings above render in the
    chosen language, no Korean bleeding through.

---

## 🚀 Store-submission summary

Builds 105–108 bundle as a single user-facing update: **"redemption loop
lands — pick up, use the code, mark as used."** Secondary stories are
level bonuses (+10m/Lv), the ticket-style brand promo modal, and
onboarding rewritten for the hunt. Store-facing copy lives in
[release-notes-build-108-paste-ready.md](release-notes-build-108-paste-ready.md).
