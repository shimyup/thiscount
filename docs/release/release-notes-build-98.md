# Release Notes — Build 98 (1.0.0+98)

Date: 2026-04-19

Build 94–98 누적 변경사항. 한 세션 내 5개 빌드가 이어지며 **"첫 주 마찰
제거 + 2주차 이상 리텐션 훅 + 운영팀 관점 감성 디테일"** 을 한 묶음으로
완성했습니다.

- Build 94: 매일 오전 8시 "오늘의 편지" 로컬 리마인더
- Build 95: 온보딩·리텐션 7종 훅
- Build 96: Build 95 버그 2종 수정 + 회귀 테스트
- Build 97: AI 편지 투명화 + 컴포즈 원클릭 목적지 + 사운드 인프라 + 답장 제한 안내
- Build 98: 주간 회고 + 푸시 3단 제어 + Premium 컬렉션 리프레이밍 + 펜팔 뱃지 + 요일 테마

---

## 🇰🇷 Korean (한국어)

### 🔔 알림 (Build 94 · 96)

**매일 오전 8시 "오늘의 편지" 리마인더**
- 설정에서 옵트인 가능 (기본 OFF)
- `zonedSchedule` + 타임존 자동 초기화 (인도 UTC+5:30 등 고정 오프셋 근사)
- 앱 재시작·시간대 변경·DST 시 자동 재예약

**온보딩 프리프롬프트**
- 시스템 권한 팝업 전 "매일 아침 편지함 열어볼까요?" 커스텀 다이얼로그
- 허용 시 매일 리마인더 자동 ON
- 거부해도 일반 알림 권한은 요청 (편지 도착 등)

### 📥 편지 경험 (Build 95 · 97)

**웰컴 편지 시딩**
- 가입 직후 운영팀 큐레이션 편지 1통이 즉시 배송된 상태로 우편함에 도착
- 14개 언어 본문 ("편지는 천천히 여행합니다…")
- 유저당 1회만 시딩 (중복 가드 2중: pref 키 + inbox 체크)

**작성 프롬프트 로테이션**
- 컴포즈 화면 빈 상태에서 매일 바뀌는 "오늘의 영감" 노출
- 7개 프롬프트 주간 로테이션 × 14개 언어 = 98개
- 탭 시 본문에 자동 삽입

**원클릭 목적지 제안**
- 🎲 지구 반대편 · 🌅 지금 아침인 곳 · 🌏 안 가본 대륙 — 3개 버튼
- 경도 기반 타임존 근사 + 대륙 매핑

**AI 편지 투명화**
- 🤖 "문학 봇" 배지 (수신함 + 편지 상세)
- AI 편지는 답장 버튼 대신 "이 편지는 창작물입니다 · 답장은 전달되지 않아요" 카드 노출

**답장 1회 제한 설명**
- 비활성 답장 버튼 탭 시 설명 스낵바
- 버튼 하단에 "한 편지에 한 번만 답장할 수 있어요" 이탤릭 문구

**답장 FOMO 힌트**
- 미답장 인간 편지에 "🕊️ 이 사람은 당신의 답을 기다리고 있을지 몰라요"

**발신자 순간 라인**
- 편지 상세에 "🌙 밤 11시에 쓴 편지" 같은 감성 라인
- 발신자 경도 → 현지 시각 근사

**레터 컨텍스트 배지**
- "당신의 N번째 받은 편지 · 이집트에서 온 첫 편지"

**펜팔 교환 뱃지**
- 같은 발신자로부터 3/5/10회 수신 시 뱃지
- 🌱 Budding (3-4) · 🕊️ Regular (5-9) · 📜 Longtime (10+)

### 📅 리텐션 (Build 95 · 98)

**일일 스트릭 방어권**
- 하루 놓쳐도 스트릭 1회 구제 (30일마다 토큰 1개 자동 충전)
- 방어권 사용 시 "스트릭을 한 번 구해드렸어요!" 스낵바
- 기존 유저 마이그레이션 완료 (Build 96 수정)

**주간 회고 카드**
- 일요일 자동 노출 · 주당 1회 해제 가능
- "이번 주 당신의 편지 N통이 K개 나라 · M개 대륙으로 떠났어요 🌍"
- 가장 먼 편지 거리 추가 표시

**요일 테마 배너**
- 월=동아시아 · 화=유럽 · 수=아프리카 · 목=남미 · 금=오세아니아 · 토=북미 · 일=중동
- 탭 시 해당 대륙 랜덤 국가 자동 선택

### 🎨 감성 디테일 (Build 95 · 97)

**사운드 레이어 (FeedbackService)**
- 개봉: 2단계 햅틱 (heavy → medium) + 시스템 클릭
- 발송: medium 햅틱 + 시스템 클릭
- 수신: 3연속 light 햅틱 ("부드러운 우편함 노크")
- 실제 오디오 파일 주입 지점 인프라 완성 (차후 교체)

**도착 카운트다운 푸시**
- 수신 편지 도착 1시간 전 로컬 알림
- "편지가 1시간 후 도착해요 · 🇫🇷 프랑스에서"
- 단일 슬롯 (항상 가장 임박한 편지 1건만 예약)
- 자기가 보낸 편지 / 100km 초과 편지는 제외

### 🔕 푸시 제어 (Build 98)

**3단 알림 볼륨**
- 🔕 **Quiet**: 하루 1번의 아침 리마인더만
- 🛎 **기본**: 편지 도착·DM·리마인더 (기본값)
- 📣 **전체**: 근처 도착·쿨다운·카운트다운까지 모두
- 게이트가 모든 `show*` / `schedule*` 메서드 상단에 위치해 즉시 적용

### 💎 Premium — Thiscount Premium 컬렉션 (Build 93 · 98)

**감성 리프레이밍** (RevenueCat SKU·결제 흐름 불변)
- 🌌 **Aurora** — 밤의 언어로 쓰는 편지 (야간 편지지 · 이미지 무제한)
- 🌾 **Harvest** — 계절이 지나가는 속도로 (사계절 편지지 · 특급 배송 · 이번 달의 도시 자동 테마)
- 💌 **Postmaster** — 공식 발송인의 권한 (무제한 하늘길 · 답장 우선 · 인증 뱃지 · SNS 링크)

---

## 🇺🇸 English

### 🔔 Notifications (Build 94 · 96)

**Daily 8 AM "Today's Letter" reminder**
- Opt-in via settings (default OFF)
- Uses `zonedSchedule` with fixed-offset timezone approximation
- Auto-reschedules across app restarts, timezone changes, DST

**Onboarding pre-prompt**
- Custom dialog before the system permission popup
- Grants → daily reminder auto-enabled
- Declines → still requests general notification permission

### 📥 Letter Experience (Build 95 · 97)

**Welcome letter seeding**
- A curated letter from "The Letter Go Team" lands in every new mailbox,
  already delivered, ready to read
- Per-user seed pref + inbox check (no duplicates)

**Daily writing prompt rotation**
- 7 prompts × 14 languages = 98 total
- Tap-to-insert into an empty letter body

**Quick-pick destinations**
- 🎲 Other side of the globe · 🌅 Sunrise now · 🌏 New continent
- Longitude-based timezone approximation + continent mapping

**AI letter transparency**
- 🤖 "CURATED" badge on inbox and read screens
- Reply button replaced with a notice: "This letter was written by a
  literary bot — replies won't reach anyone"

**Reply-limit explanation**
- Tapping a disabled reply button now shows a soft snackbar
- "One reply per letter" italic line under the button

**Reply FOMO hint**
- Unanswered human letters show "🕊️ Someone, somewhere, may be
  waiting for your reply"

**Sender moment line**
- "🌙 Written late at night" style line on the read screen
- Sender longitude → approximate local hour

**Letter context badge**
- "Your N-th received letter · first from Egypt"

**Pen-pal tier badge**
- 3-4 letters from same sender → 🌱 budding
- 5-9 → 🕊️ regular
- 10+ → 📜 longtime

### 📅 Retention (Build 95 · 98)

**Streak freeze**
- One-token-per-30-days save if yesterday was missed
- "We saved your streak once!" snackbar on use
- Existing-user migration fixed in Build 96

**Weekly reflection card**
- Surfaces on Sundays only, dismissible per week
- "This week, N of your letters traveled to K countries across M continents 🌍"
- Plus the farthest letter's km

**Day-of-week theme banner**
- Monday=East Asia, Tuesday=Europe, through Sunday=Middle East
- One-tap to pick a random country from the region

### 🎨 Sensory details (Build 95 · 97)

**Sound layer (FeedbackService)**
- Open: 2-stage haptic + system click
- Send: medium haptic + system click
- Arrive: 3-tap light haptic ("soft mailbox knock")
- Infrastructure ready for real audio files

**Arrival countdown push**
- Local notification 1 hour before a letter arrives
- Single-slot (always the soonest future arrival)
- Excludes self-sent and >100km destinations

### 🔕 Push control (Build 98)

**3-mode segmented picker**
- 🔕 **Quiet**: morning nudge only
- 🛎 **Standard**: arrivals, DMs, reminder (default)
- 📣 **Everything**: nearby, cooldown, countdown — all of it
- Gate sits at the top of every show/schedule method — takes effect
  immediately when the mode changes

### 💎 Premium — Thiscount Premium Collections (Build 93 · 98)

Emotional reframing (RevenueCat SKU and payment flow unchanged)
- 🌌 **Aurora** — letters in the language of the night
- 🌾 **Harvest** — paced by the seasons
- 💌 **Postmaster** — the Official Sender tier

---

## 🔧 Technical

- Zero new runtime dependencies across Builds 94–98 (reused `timezone 0.9.4`,
  `flutter_local_notifications 17.x`, `shared_preferences`)
- `flutter analyze`: 0 issues
- `flutter test`: 11 passing (was 1 at Build 93) — added unit tests for
  `composeDailyPrompt`, `buildWelcomeLetter`
- Firebase / Firestore / RevenueCat integrations untouched
- 14-language localization: ~450 new string entries across Builds 94–98
- All new UI respects the existing `Directionality` wrapper (RTL safe)

---

## 🐛 Bug fixes (Build 96)

**Streak freeze migration**
- Existing users upgrading from Build 94 were never granted their initial
  freeze token due to an early-return in `_maybeRefillStreakFreeze`. Fixed
  to mint the first token for any account with an empty `lastRefill`.

**Self-sent arrival countdown**
- `_rescheduleArrivalCountdown` could pick up user's own domestic letters
  (e.g., Seoul→Incheon within 100km) and push "your letter is arriving".
  Added explicit `senderId == currentUser.id` skip.

---

## 📊 KPI 기대치

| 지표 | Build 93 | Build 98 목표 |
|------|----------|--------------|
| 신규 첫 발송률 | ~55% | 70%+ (원클릭 목적지 · 프롬프트) |
| D1 리텐션 | ~45% | 55%+ (매일 리마인더 · 웰컴 편지) |
| D7 리텐션 | ~25% | 30%+ (스트릭 방어권 · 주간 회고) |
| 답장률 | 현재 측정 중 | +15% (FOMO 힌트) |
| Premium 전환 | ~1.2% | 2% (컬렉션 리프레이밍) |
| 알림 OFF 비율 | ~18% | <10% (3단 푸시 제어) |

---

## 🚀 다음 단계

1. **FCM 서버 푸시** — 폴링 제거 + 서버발 알림 (-Firestore 비용 90%)
2. **스크린샷·Preview 비디오** — 앱 스토어 Featured 피치 대비
3. **공식 오디오 파일** — FeedbackService 인프라에 주입
4. **연말 Wrapped** — 12월 이벤트 준비 (인프라 이미 있음)
5. **펜팔 교환 카운트 서버 동기화** — 현재는 로컬 inbox만 집계
