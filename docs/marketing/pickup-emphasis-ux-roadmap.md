# 픽업 강조 UI/UX 로드맵

Build 119 기준. 마케팅 기획서 [marketing-brief-build-113.md](marketing-brief-build-113.md)
과 글로벌 차별화 문서 [global-hunt-differentiation.md](global-hunt-differentiation.md)
에서 정의한 "5배 반경 · 6배 빠른 쿨다운 = Premium 의 실제 가치" 를 **구매
결정 이전의 일상 UX 에서 매일 느끼게** 하기 위한 개선 후보 리스트.

Build 119 에선 카피를 모두 픽업-퍼스트로 재정비했고, 아래 항목들은 후속
빌드(120+)에서 **실제 픽업 감각을 시각·햅틱으로 증폭** 하는 UX 구현이다.

---

## ✅ Build 119 적용 완료 (카피 레벨)

| 위치 | 변경 |
|------|------|
| `premiumHeroTitle` | "더 넓은 세계로 편지를 보내보세요" → **"더 넓은 반경으로 쿠폰을 주워보세요"** |
| `onboardingPremiumTitle` | 동일 (페이월과 일관) |
| `onboardingPremiumSubtitle` | "특별한 편지 경험" → **"줍기 반경 1km · 쿨다운 10분 — Free보다 5배 넓고 6배 빠르게"** |
| `onboardingPremiumFeat1–4` | 발송 중심 → **반경(📍) · 쿨다운(⏱) · 발송(✈️) · 꾸미기(🎨)** 순 |
| `onboardingFreeFeat1–4` | 발송 → **반경 200m · 쿨다운 60분** 1순위 노출 |
| `onboarding2Body` (배송 경로) | "보내는 편지가 이동" → **"주운 편지도, 보낸 편지도 지도 위를 이동"** |

모두 14개 언어 (ko/en/ja/zh/fr/de/es/pt/ru/tr/ar/it/hi/th) 커버 완료.

---

## 🕐 Build 120 후속 — 코드 구현 필요 (픽업 감각 증폭)

### 1. **픽업 반경 링 — 지도 상시 표시 (High ROI)**

**목적**: 유저가 지도를 열 때마다 "내가 지금 어디까지 줍을 수 있는지" 한 눈에 본다. Free↔Premium 업그레이드의 시각적 앵커.

**구현**
- 파일: [`lib/features/map/screens/world_map_screen.dart`](lib/features/map/screens/world_map_screen.dart)
- `flutter_map` `CircleLayer` 로 user.location 중심에 `state.pickupRadiusMeters` 반경 링 상시 렌더
- 색상: Free 티일 0.25 alpha, Premium 골드 0.3 alpha, Brand 오렌지 0.3 alpha
- 레벨업 시 링 반경이 부드럽게 확대되는 200ms ease-out 애니메이션
- 설정에서 on/off 토글 (디폴트 on)

**예상 임팩트**: Premium 전환율 +10~20% (실제 "5배 넓은 원" 이 눈으로 보임)

### 2. **레벨업 반경 증폭 토스트 (Medium ROI)**

**목적**: 레벨 올리는 동기를 "레벨 숫자" 가 아니라 "반경 +10m 확대" 라는 게임플레이 상의 실제 혜택으로 바꾼다.

**구현**
- 파일: [`lib/features/progression/level_up_banner.dart`](lib/features/progression/level_up_banner.dart)
- 현재 레벨업 배너에 `"반경 +10m → 이제 {newRadius}m"` 라인 추가
- XP 획득 시 배너 하단에 작은 프로그레스 "{currentXp} / {nextLevelXp} — 다음 레벨까지 {n} XP" 노출
- `FeedbackService.onLevelUp()` 에 `HapticFeedback.heavyImpact()` 추가

**l10n 키 예시**: `levelUpRadiusBonus(int newRadius, int delta)` — "🎯 반경 +{delta}m → 이제 {newRadius}m"

### 3. **프로필 반경 진행바 (Medium ROI)**

**목적**: "내 반경이 얼마나 넓어졌는지" 프로필에서 숫자가 아닌 채움 비율로 본다. 0%(레벨 1) ↔ 100%(레벨 50) 그라디언트 바.

**구현**
- 파일: [`lib/features/hunt_wallet/hunt_wallet_card.dart`](lib/features/hunt_wallet/hunt_wallet_card.dart) — Weekly Quest 바 아래에 추가
- 또는 별도 위젯 `RadiusProgressCard` 로 분리
- 표시: `"🎯 내 반경 {current}m / 최대 {maxForTier}m"` + 그라디언트 바 (현재 비율)
- Free 의 경우 "Premium 전환 시 5× 즉시 확대 →" 골드 텍스트 CTA 추가

### 4. **근처 편지 카운터 상시 노출 (Low-Medium ROI)**

**목적**: 지도를 안 열어도 "지금 내 반경 안에 X 통" 이 상단 영구 표시 되어 줍기 동기 유지.

**구현**
- 파일: [`lib/widgets/main_scaffold.dart`](lib/widgets/main_scaffold.dart) 앱바 하단 또는 5탭 네비 위
- 작은 teal 필: `"🎟 근처 {state.nearbyLetters.length}통"`
- `state.nearbyLetters.isEmpty` 일 때는 숨김
- 탭 시 탐험 탭으로 이동

### 5. **"근처에 없을 때 — 방향 나침반" 힌트 (High creativity, Medium effort)**

**목적**: 유저가 집에서 앱 열었을 때 "주변에 0통이네" 데드 스페이스를 "북쪽으로 200m 걸으면 쿠폰 1장 있어요" 안내로 변환.

**구현**
- 파일: `lib/features/map/screens/world_map_screen.dart`
- `state.nearbyLetters.isEmpty && state.worldLetters.isNotEmpty` 일 때:
  - 가장 가까운 letter 의 distance · bearing 계산 (Haversine)
  - 지도 하단에 "🧭 {distance}m {direction} 방향에 {category} 편지" 배너
  - direction = 북/남/동/서/북동/북서/남동/남서
- 탭 시 해당 편지 위치로 지도 카메라 이동 (Premium feature 로 제한 가능)

### 6. **첫 픽업 후 "레벨 1 → 2 로드맵" 모달 (Low effort, High retention)**

**목적**: 첫 픽업 축하 (Build 115) 다음 날 방문 시 "이제 반경이 210m 로 넓어졌어요" 2차 축하. 레벨 인지도 조기 각인.

**구현**
- 파일: `lib/state/app_state.dart` + `lib/features/map/screens/world_map_screen.dart`
- `_firstPickupAt` 타임스탬프 추가 (Build 115 에서 flag 만 있음)
- 첫 픽업 이후 방문 + 레벨 2 달성 시 한 번만 "2레벨 축하! 반경 +10m" 토스트
- 5, 10, 25, 50 레벨 마다 마일스톤 축하

### 7. **맵 타워 꾹 눌러 "내 반경" 모드 (Low effort, novelty)**

**목적**: 유저가 본인 타워를 길게 누르면 본인 반경 링이 일시적으로 강조 (2초 펄스). "여기가 내 사냥터" 감각.

**구현**
- 파일: `lib/features/map/screens/world_map_screen.dart` — 유저 위치 핀 onLongPress
- `AnimationController` 로 2초 펄스 (alpha 0.5 → 0 fade)
- 디바이스 진동 `HapticFeedback.selectionClick()`

---

## 🎯 우선순위 추천

**즉시 구현 (Build 120)**:
1. **픽업 반경 링 상시 표시** — 가장 큰 시각적 차별화
2. **레벨업 반경 증폭 토스트** — 레벨 시스템 동기부여 직결

**2차 (Build 121)**:
3. **프로필 반경 진행바** — HuntWalletCard 연장
4. **근처 편지 카운터 (네비 위)** — 상시 노출 재방문 유도

**3차 (Build 122+)**:
5. **방향 나침반 힌트** — Premium-only 로 제한 시 추가 구매 유도
6. **첫 픽업 후 2차 축하 모달**
7. **타워 꾹 눌러 펄스**

---

## ❌ 검토했지만 추천 안 함

- **AR 모드 / 카메라 오버레이** — 포켓몬 GO 스타일. Flutter 에서 AR 구현 복잡, 발열·배터리 소모 큼. 지도 링으로도 목적 달성 가능.
- **3D 타워 렌더링** — 현재 2D 로도 충분히 매력적. 3D 는 유지보수 비용 크고 iOS/Android 일관성 리스크.
- **실시간 다른 유저 커서 공유** — 익명성 차별화 파괴. 심리적 안전 해자 약화.
- **광고 배너** — 유저 경험 붕괴. 수익은 Brand ExactDrop · Premium 구독으로.

---

## 📎 관련 문서

- [marketing-brief-build-113.md](marketing-brief-build-113.md) — 마케팅 기획
- [global-hunt-differentiation.md](global-hunt-differentiation.md) — 글로벌 경쟁 분석
- `AppState.pickupRadiusMeters` — 반경 단일 진입점
- `AppState.nearbyPickupRemainingCooldown` — 쿨다운
- `FeedbackService.onLetterPickUp()` — 픽업 햅틱
