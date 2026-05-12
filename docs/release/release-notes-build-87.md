# Release Notes — Build 87 (1.0.0+87)

Date: 2026-04-19

이 노트는 Build 82–87 의 누적 변경을 한 번에 정리합니다. 이 세션의 Phase 2
완료 + Phase 3 주요 항목 착수 내역을 포괄합니다.

---

## Korean (한국어)

**주간 챌린지** 🗺️ (Build 82)

- "이번 주에 3개 나라로 편지 보내기" 목표 추가
- 진행 바 + 달성 시 보상 청구 버튼
- ISO 주 번호 기반 자동 리셋

**온보딩 점진 공개** 🎯 (Build 83)

- 신규 사용자 부담 감소 — 복잡 기능 단계별 해금
- newbie → beginner (1통) → casual (5통/1답장) → regular (10통) →
  experienced (20통/14일 스트릭)
- 레벨업 시 축하 배너 "새 기능이 해금됐어요"

**홈 화면 단순화** 🧭 (Build 84)

- 신규 사용자에게 근처 도착 배너 숨김 — 인지 부담 ↓
- experienced 레벨부터 주변 줍기 노출

**편지 희소성** 💎 (Build 85)

- 받은 편지 상세에 "읽은 사람 N/3" 표시
- 마지막 수신자일 때 "당신이 마지막이에요" 강조
- maxReaders 설계를 감정으로 연결

**이번 달의 도시** 🌍 (Build 85)

- 12개월별 도시 큐레이션 (홋카이도, 파리, 제주, 교토 …)
- 프로필에 이번 달 테마 카드 노출
- 카드 탭 → 바로 편지 쓰기 진입

**14개 언어 l10n 전면 적용** 🌐 (Build 86)

- Phase 2/3 에서 추가된 모든 UI 텍스트를 14개 언어로 번역
- 378 개 번역 추가 (27 키 × 14 언어)
- 아랍어 RTL 자동 대응

**편지 개봉 애니메이션 업그레이드** ✨ (Build 87)

- 봉투 개봉 1200ms (이전 700ms) — 더 드라마틱
- 2단계 햅틱 피드백 (light → medium) — 종이 펼치는 촉감
- easeOutCubic 커브로 자연스러운 종료

---

## English

**Weekly Challenge** 🗺️ (Build 82)
- "Send letters to 3 countries this week" goal
- Progress bar + reward claim button
- Auto-reset on ISO week boundary

**Progressive Onboarding** 🎯 (Build 83)
- Reduced cognitive load for new users — features unlock by level
- newbie → beginner → casual → regular → experienced
- Celebration banner "New feature unlocked" on level-up

**Home Simplification** 🧭 (Build 84)
- Nearby arrival banner hidden for new users
- Exposed only at experienced level (20 letters or 14-day streak)

**Letter Scarcity** 💎 (Build 85)
- "Readers: N/3" indicator on letter detail
- "You're the last reader" emphasis
- Connects maxReaders design to emotional hook

**City of the Month** 🌍 (Build 85)
- 12 curated cities by month
- Themed card on profile screen
- Tap to compose letter for that city

**14-Language l10n Rollout** 🌐 (Build 86)
- All Phase 2/3 strings translated to 14 languages
- 378 new translations (27 keys × 14 langs)
- Automatic RTL layout for Arabic

**Letter Opening Animation Upgrade** ✨ (Build 87)
- 1200ms envelope opening (up from 700ms) — more dramatic
- Two-stage haptic feedback (light → medium)
- easeOutCubic curve for natural deceleration

---

## Japanese (日本語)

**週次チャレンジ** (Build 82)
- 「今週3カ国に手紙を送る」目標
- 進捗バー + 達成時の報酬受取ボタン

**段階的オンボーディング** (Build 83)
- 新規ユーザーの負担軽減 — 機能を段階的に解放
- newbie → beginner → casual → regular → experienced

**ホーム画面の簡素化** (Build 84)
- 新規ユーザーには近くの到着バナー非表示

**手紙の希少性** (Build 85)
- 「読者数 N/3」表示
- 最後の受取人時の強調

**今月の都市** (Build 85)
- 月ごとの都市キュレーション

**14言語への完全翻訳** (Build 86)
- Phase 2/3 の全ての文字列を14言語対応

**開封アニメーション強化** (Build 87)
- 1200msに拡張、2段階ハプティック

---

## Chinese (中文)

**每周挑战** (Build 82)
- "本周向3个国家寄信"目标
- 进度条 + 达成时领取奖励

**渐进式引导** (Build 83)
- 降低新用户认知负担
- 功能按等级解锁

**主页简化** (Build 84)
- 新用户隐藏附近到达横幅

**信件稀缺性** (Build 85)
- "已读人数 N/3"显示
- 作为最后读者时强调

**本月之城** (Build 85)
- 每月城市策划

**14种语言全面应用** (Build 86)
- 所有 Phase 2/3 文本翻译

**开信动画升级** (Build 87)
- 1200ms延长，2阶段触觉反馈

---

## Changes in Build 82 — Weekly Challenge

### Code
- `lib/state/app_state.dart`:
  - `_weeklyChallengeCountries: Set<String>` — tracks this week's destinations
  - `_weeklyChallengeWeekKey` (ISO `YYYY-Wxx`) — automatic rollover
  - `_weeklyChallengeClaimed` + `_challengeRewardBalance`
  - `weeklyChallengeProgress` / `Goal` / `Achieved` / `RewardPending` getters
  - `claimWeeklyChallengeReward()` / `_recordWeeklyChallengeSend()` /
    `_rolloverWeeklyChallengeIfNeeded()` / `_isoWeekKey()`
  - `sendLetter()` now calls `_recordWeeklyChallengeSend()` (dedup by country)
  - prefs persist 4 new keys

- `lib/features/streak/weekly_challenge_card.dart` (new):
  - 3 state variants: unclaimed / achieved-claimable / claimed
  - Accent color shifts accent → gold → teal
  - "Claim Reward" button triggers snackbar
  - Mounted on profile screen (below 4-stat row)

## Changes in Build 83 — Progressive Onboarding

### Code
- `lib/features/progression/user_level.dart` (new):
  - `UserLevel` enum (newbie/beginner/casual/regular/experienced)
  - `UnlockableFeature` enum (6 features)
  - `FeatureUnlockPolicy` — static mapping
  - Per-level `welcomeMessage` getter

- `lib/features/progression/level_up_banner.dart` (new):
  - `LevelUpBanner.showIfLevelUp(context)` — post-frame snackbar

- `lib/state/app_state.dart`:
  - `userLevel` computed getter (from sentCount/replyCount/streak)
  - `isFeatureUnlocked(UnlockableFeature)`
  - `_previousUserLevel` / `_justLeveledUp`
  - `_detectLevelUp()` called after sendLetter + setUser baseline
  - `consumeLevelUpFlag()` for UI

- `lib/widgets/main_scaffold.dart`:
  - initState → post-frame → streak + levelup banners sequentially
    (400ms gap between)

- `lib/features/profile/profile_screen.dart`:
  - WeeklyChallengeCard gated by `UnlockableFeature.weeklyChallenge`

## Changes in Build 84 — Home Simplification

### Code
- `lib/features/map/screens/world_map_screen.dart`:
  - NearbyAlertBanner gated by `UnlockableFeature.nearbyPickup`
  - Imports `user_level.dart`

## Changes in Build 85 — Scarcity + City of Month

### Code
- `lib/features/inbox/widgets/scarcity_indicator.dart` (new):
  - 3-state card: closed / last-reader / regular count
  - Icons: lock / hourglass / people
  - Colors shift orange → teal based on urgency

- `lib/features/city_of_month/city_of_month.dart` (new):
  - 12 curated cities (Korean source data)
  - `CityMonthData` class: city/country/flag/emoji/headline/description/accent
  - `CityOfMonth.forThisMonth()` / `.forMonth(int)` / `.all()`

- `lib/features/city_of_month/city_of_month_card.dart` (new):
  - Month badge + country flag header
  - Large emoji + city name + headline
  - Optional "Write to this city" CTA → `/compose` route

- `lib/features/inbox/widgets/letter_read_screen.dart`:
  - ScarcityIndicator above _buildReactionBar

- `lib/features/profile/profile_screen.dart`:
  - CityOfMonthCard below WeeklyChallengeCard

## Changes in Build 86 — 14-Language l10n Migration

### Code — l10n additions (27 new keys × 14 languages = 378 translations)
- Streak: `streakDayLabel`, `streakMilestone3/7/14/30/100`,
  `streakMilestoneGeneric`, `streakMilestoneMessage` dispatcher
- Weekly Challenge: `weeklyChallengeTitle/AchievedTitle/RewardPendingTitle`,
  `Description`, `Progress`, `Remaining`, `ClaimButton`, `Claimed`,
  `ClaimToast`
- Scarcity: `scarcityClosedTitle/Sub`, `scarcityLastReaderTitle/Sub`,
  `scarcityCountTitle/Sub`
- Level up: `levelUpBannerTitle`, `userLevelNewbie/Beginner/Casual/Regular/
  ExperiencedWelcome`
- City of Month: `cityOfMonthBadge(month)`, `cityOfMonthCta`
- Share card: `shareCardHeader(country)`, `shareCardDistance(km)`
- Misc: `shareAction`

### Widget migrations
- StreakBadge → `AppL10n.of(langCode).streakDayLabel(N)`
- StreakCelebrationBar → `streakMilestoneMessage(N)` dispatcher
- WeeklyChallengeCard → all 9 l10n keys wired
- ScarcityIndicator → all 6 l10n keys wired
- LevelUpBanner → `_localizedWelcome()` switch mapping
- CityOfMonthCard → badge + CTA via l10n
- ShareCardService — new `langCode` parameter, renders headers via l10n
- letter_read_screen share button tooltip → `shareAction`

## Changes in Build 87 — Letter Opening Animation

### Code
- `lib/features/inbox/widgets/letter_read_screen.dart`:
  - AnimationController 700ms → 1200ms
  - Curve `easeOutBack` → `easeOutCubic` (more natural deceleration)
  - Two-phase reveal: 350ms delay → light haptic → 450ms animateTo 0.5 →
    medium haptic → 750ms animateTo 1.0

### Version
- `pubspec.yaml`: 1.0.0+81 → 1.0.0+87

---

## Artifacts

- iOS IPA (signed, ~38MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (~53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (~68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues at every build
- `flutter test`: All tests passed
- RESEND + BETA_FREE_PREMIUM + BETA_ADMIN_EMAIL injected in all builds

---

## 기대 효과

### 리텐션 (주간 챌린지 + 점진 공개 + 희소성)
- D7 리텐션: Duolingo 패턴 적용으로 **+5-10%p** 예상
- 신규 이탈: 점진 공개로 첫 3일 이탈률 **-20%** 예상
- 편지 답장률: 희소성 ("마지막 수신자") FOMO 로 **+15%** 예상

### 국제 확장 (14-lang l10n)
- 아시아·유럽·중동 14개 언어 모두 자연스러운 메시지
- RTL 자동 대응으로 아랍권 진입 가능
- 1개 언어 추가 때마다 MAU 잠재 10-20% 증가

### 감성 품질 (이번 달의 도시 + 개봉 애니메이션)
- 매달 새로운 도시 콘텐츠 → 재방문 동기
- 개봉 감정 밀도 ↑ → 공유 카드 전환율 ↑ → 바이럴 가속

---

## 남은 Phase 3 항목 (다음 세션)

1. FCM 푸시 알림 (매일 오전 8시) — 재방문 핵심 후크
2. Premium → Thiscount Premium 전면 리브랜딩 — 라이프스타일화
3. 연말 회고 (Spotify Wrapped 스타일) — 12월 이벤트
4. 사운드 레이어 — 편지 수신·발송 시 환경음
