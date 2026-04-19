# Release Notes — Build 81 (1.0.0+81)

Date: 2026-04-19

이 노트는 Build 80 (공유 카드) 과 Build 81 (일일 스트릭) 두 빌드의
변경사항을 함께 담습니다. 한 번에 업로드 가능.

---

## Korean (한국어)

**받은 편지 공유 카드** 🎨 (Build 80)

- 받은 편지 상세 화면에 **공유 버튼** 추가
- 인스타그램 스토리·트위터·카카오톡 등으로 1탭 공유
- 1080×1920 이미지 자동 생성 — 발신국 국기, 여정 경로, 편지 한 줄,
  브랜드 태그라인 포함
- 거리에 따라 운송수단 이모지 자동 선택 (✈️ 장거리 / 🚢 중거리 / 🚚 근거리)
- 오프라인 생성 (서버 호출 없음, 비용 0)

**일일 스트릭** 🔥 (Build 81)

- 연속 접속 일수를 추적하는 **🔥 스트릭** 기능 추가
- 프로필 화면 닉네임 옆에 compact 뱃지로 표시
- 앱 진입 시 하루 1회 자동 체크인
- 마일스톤 달성(3일·7일·14일·30일·100일) 시 축하 스낵바 1회 표시
- Duolingo 스타일 — 재방문 동기 부여

---

## English

**Letter Share Card** 🎨 (Build 80)

- **Share button** added to the letter detail screen
- One-tap share to Instagram Stories, Twitter, WhatsApp, etc.
- Auto-generated 1080×1920 image with sender flag, journey path,
  letter snippet, and brand tagline
- Transport emoji auto-selected by distance
  (✈️ long-haul / 🚢 mid-range / 🚚 short-range)
- Rendered offline — no server, zero cost

**Daily Streak** 🔥 (Build 81)

- Tracks consecutive daily app visits
- Compact 🔥 badge next to username on the profile screen
- Auto check-in on app launch (once per day)
- Celebration snackbar on milestones (3/7/14/30/100 days)
- Duolingo-style retention hook

---

## Japanese (日本語)

**受信手紙の共有カード** 🎨 (Build 80)

- 受信手紙詳細画面に**共有ボタン**追加
- Instagram ストーリー・Twitter・LINE 等にワンタップ共有
- 1080×1920 画像を自動生成（送信国国旗、旅程経路、手紙1行、
  ブランドタグライン含む）
- 距離に応じて輸送手段絵文字を自動選択（✈️ / 🚢 / 🚚）

**デイリーストリーク** 🔥 (Build 81)

- 連続ログイン日数を追跡する **🔥 ストリーク** 機能
- プロフィール画面のニックネーム横にコンパクトバッジ表示
- アプリ起動時に1日1回自動チェックイン
- マイルストーン達成時に祝福スナックバー

---

## Chinese (中文)

**收信分享卡片** 🎨 (Build 80)

- 收信详情页添加**分享按钮**
- 一键分享至 Instagram Stories、Twitter、微信 等
- 自动生成 1080×1920 图片（含发信国国旗、旅程路线、信件摘录、品牌标语）
- 根据距离自动选择运送工具图标（✈️/🚢/🚚）

**每日连续签到** 🔥 (Build 81)

- 追踪连续登录天数的 **🔥 连续签到** 功能
- 个人资料页昵称旁显示紧凑徽章
- 应用启动时每日自动签到一次
- 达成里程碑时显示庆祝提示

---

## Changes in Build 80

### Code
- `lib/features/share/share_card_service.dart` (new):
  - `ShareCardService.shareLetterCard({letter, tagline, brandName})`
  - 1080×1920 PNG rendering using `dart:ui` Canvas
  - Deep navy gradient background with starfield
  - Journey graphic: origin flag → transport emoji (curve) → destination flag
  - Haversine-based distance calculation for transport emoji selection
  - Writes to temp directory then hands to `share_plus` native share sheet

- `lib/features/inbox/widgets/letter_read_screen.dart`:
  - Added share button next to block/report (ios_share icon, teal)
  - Only shown for non-brand senders

## Changes in Build 81

### Code
- `lib/state/app_state.dart`:
  - New fields: `_currentStreak`, `_longestStreak`,
    `_lastStreakCheckinDate`, `_streakJustIncreased`
  - New methods:
    - `registerDailyStreakCheckin()` — idempotent, safe to call repeatedly;
      handles: first visit, consecutive day, skip-day reset, same-day no-op
    - `consumeStreakIncreaseFlag()` — UI one-shot consumption for celebration
  - `setUser()` now triggers `registerDailyStreakCheckin()` automatically
  - `loadFromPrefs` restores all 3 streak fields
  - `_saveToPrefs` persists all 3 streak fields

- `lib/features/streak/streak_badge.dart` (new):
  - `StreakBadge({compact})` — reusable 🔥 N일 badge widget
  - `StreakCelebrationBar.showIfIncreased(context)` — snackbar helper
    with milestone-specific messages

- `lib/features/profile/profile_screen.dart`:
  - Added compact `StreakBadge` next to username + plan badge

- `lib/widgets/main_scaffold.dart`:
  - `initState` → `addPostFrameCallback` → `StreakCelebrationBar.showIfIncreased`
  - Shows celebration snackbar once per streak increase

### Version
- `pubspec.yaml`: 1.0.0+79 → 1.0.0+81 (Build 80 merged inline)

---

## Artifacts

- iOS IPA (signed, 38.0MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- Build logs confirm: RESEND + BETA_FREE_PREMIUM + BETA_ADMIN_EMAIL all injected

---

## 기대 효과

### 공유 카드 (Build 80)
- **바이럴 루프 활성화**: 받은 편지를 스토리에 공유 → 팔로워 유입
- **무료 CAC 감소**: 기존 ₩3,000 목표 → 바이럴 30% 달성 시 실효 ₩2,000 이하
- **브랜드 노출**: Letter Go 로고 + 태그라인 반복 노출로 오가닉 다운로드 증가

### 일일 스트릭 (Build 81)
- **D7 리텐션 ↑**: Duolingo 실증 — 스트릭 도입 시 리텐션 +5~10%p
- **습관 형성**: 3일·7일 마일스톤이 "계속 열어야 할 이유" 제공
- **게이미피케이션 최소 규칙 준수**: 포인트·레벨 대신 1가지 지표만 사용

---

## 남은 Phase 2 항목 (다음 세션)

1. 홈 화면 단순화 (FAB + 지도만) — 1~2일
2. 온보딩 점진 공개 (UserProgress 모델 + feature gating) — 2~3일
3. 주간 챌린지 (스트릭 연계, "5개 대륙 편지") — 3일
4. FCM 푸시 (매일 오전 8시 "오늘의 편지") — 2~3일

상세 스펙은 `docs/release/ux-improvement-roadmap.md` 참조.
