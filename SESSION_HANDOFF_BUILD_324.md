# Build 324 세션 핸드오프 — 다음 세션 시작점

> 새 세션에서 이 문서 path 를 첫 prompt 로 보내거나, 아래 "다음 세션 prompt"
> 섹션 복붙. 새 Claude 세션이 이 문서 읽고 현재 상태 + 다음 작업 즉시 파악.

---

## 📌 현재 상태 (2026-05-24)

### Git
- main 최신: **`df7fbdf`** "feat(retention): 핀 ring 단순화 + 만료 daily push (PR-Q3)"
- pubspec: `1.0.0+324`
- 모든 fix PR (#61 외 main 직접 commit 다수) 머지 완료

### 빌드/배포 상태
- ✅ Build 324 archive 존재: `build/ios/archive/Runner.xcarchive` + `~/Library/Developer/Xcode/Archives/2026-05-24/Thiscount 5-24-26, 2.54 PM.xcarchive`
- ✅ ScreenPreventerKit dSYM 수동 생성 (UUID `9D0A700C...`)
- ⏳ **TestFlight 업로드 대기 중** — 사용자가 Xcode → Organizer → "Distribute App" 수동 진행 필요
- ❌ Apple/Google/RC 콘솔 IAP 등록 대기 (ExactDrop 100 패키지)

### 검증
- flutter analyze: clean
- flutter test: 116/116 (1 skipped)

---

## 🎯 Build 324 누적 완료

### 핵심 단순화 (Tier 1-2)
- PR-A: Free 발송 차단 + 메인 = 지도
- PR-B: 카테고리 7→3 그룹 + 지도 핀 색
- PR-C: FOMO 카운트다운 핀
- PR-D: 편지 메타포 retire (14언어)
- PR-E: 온보딩 단축 (delivery_intro 4.2s 제거)
- PR-F: 타워 격리 (4탭→3탭)
- PR-G: 핀 색 통일 (gold + 이모지)
- PR-H: Welcome trial 3일 확인

### Brand 도구 (Y/X 시리즈)
- PR-Y: ExactDrop IAP 즉시 구매 ("관리자 문의" 폐기)
- PR-X3: 본인 sender 청록 ring + 1인1회 OFF 카피

### Premium UX (Z 시리즈)
- PR-Z1a: brandUnique 스낵바 + trial 모달
- PR-Z1b: 카테고리 long-press sub-filter
- PR-Z2: compose 시나리오 칩 3개
- PR-Z3: signUp invite code

### Cold-start (X 시리즈)
- PR-X1: 신규 5 demo letter + 핀 +35%
- PR-X2: AI 추천 이유 칩

### Audit Fix
- AI scoring P0×2 + P1×5 + P2×4
- campaign dedup P0×2 + P1×2 + P2×5
- 5차 audit Tier 1 (trial 모달 타이밍 + demo "체험" 라벨)

### 소비자 혜택 (Q 시리즈 — 가장 최근)
- **PR-Q1**: "사용 진행" 버튼 + 1h auto-complete (`bc11317`)
- **PR-Q2**: 할인율 big text leading (`e93cef2`)
- **PR-Q3**: 핀 ring 단순화 + 만료 daily push (`df7fbdf`)

### 문서 + Tools
- `docs/release/exact-drop-iap-setup.md` (전체 가이드)
- `docs/release/exact-drop-iap-asc-walkthrough.md` (ASC step-by-step 472줄)
- `docs/release/exact-drop-launch-checklist.md` (7 step 체크리스트)
- `scripts/generate_exact_drop_paywall_mockup.py` (14언어 mockup)
- `scripts/generate_exact_drop_promo_1024.py` (1024×1024 promo)
- `scripts/capture_exact_drop_paywall_from_simulator.sh`
- `scripts/copy_archive_to_organizer.sh`

---

## 🔴 다음 세션 권장 우선순위

### 1. 빌드 배포 마무리 (사용자 작업 대기)
- Xcode → Organizer → "Thiscount 5-24-26, 2.54 PM" → Distribute App → ASC Upload
- 또는 `./scripts/release_to_testflight.sh` (Xcode account 먼저 연결)

### 2. 5차 audit 후속 Tier 2/3 (코드)
가장 큰 영향 → 가장 작은 코드:
1. **온보딩 6→3 페이지** — Premium 페이지 제거 (Free 신규 첫 인상 최대 영향)
2. **Letter 카드 5요소 룰** — 현 9요소 → 5개 (sender / 본문 / 거리or만료 / 단일 뱃지 / 상태)
3. **AI 칩 "+1" 보조** — 다신호 letter
4. **gold 색 의미 변별** — AI=violet, FOMO=빨강 단독
5. **ExactDrop 가격 티어** — 50통 ₩6,000 / 500통 ₩40,000
6. **brandInsights 홈 위젯** (2뎁스 진입 해소)
7. **compose 4 토글 → 시나리오 default 내장** (Brand UX -60%)
8. **시간대별 픽업 히트맵** (Brand 자동 zone 효과 측정)

### 3. 매장 QR 인증 (가장 큰 비즈니스 차별점 — 2-3일)
- `qr_flutter` 라이브러리 추가
- 매장 QR 등록 화면 (Brand 전용)
- 사용자 측 letter_read 의 redemption box 안 QR 풀스크린 (기존 _buildRedemptionContent 확장)
- Cloud Function: 매장 직원 스캔 → letterId verification → Firestore `letters/{id}.storeVerifiedAt`
- brandInsights "실 방문 N건" 컬럼 추가

### 4. 운영 (코드 외)
- Brand 영업 → 매주 50+ 시드 letter 보강 (letter 공급 부족 = retention 0 의 근본)
- 포지셔닝 카피: "걷다 보면 쿠폰이 떨어져요" → 마케팅 자료 + 온보딩 카피 통일
- App Store / Play Console 에 ExactDrop IAP 등록 ([guide](docs/release/exact-drop-launch-checklist.md))

---

## 📊 시뮬레이션 결과 (5차)

| 페르소나 | 점수 (4차 → 5차) | 핵심 잔존 |
|---|---|---|
| Free 신규 7일 | 삭제 → **여전히 삭제** | Letter 공급 / 포지셔닝 / 카드 정보 과다 |
| Premium | 4/5 → 5/10 | AI 학습 진척도 / 카드 5요소 / Lv11 onboarding prompt |
| Brand 사장 | 5/10 → 7/10 | 매출 attribution / 가격 티어 / 히트맵 |
| UI/UX 전문가 | first-impression 4/10 | 6페이지 온보딩 / gold 다용도 / 카드 9요소 |

### 가장 큰 잠재력
**포지셔닝 한 문장 변경** — "걷다 보면 쿠폰이 떨어져요" / "검색이 아닌 우연 발견"

---

## 🎨 디자인 자산 (이미 commit 됨)

### Mockup PNG
- `docs/release/iap_screenshot_guides/exact_drop_100_paywall*.png` (14언어)
- `docs/release/iap_screenshot_guides/exact_drop_100_promo_1024*.png` (4언어: ko/en/ja/zh)

### 자동 생성 가능
```bash
# Paywall mockup (1284 × 2778)
python3 scripts/generate_exact_drop_paywall_mockup.py --all

# Promo 1024 (마케팅용)
python3 scripts/generate_exact_drop_promo_1024.py --all
```

---

## 💬 다음 세션 prompt (복붙)

```
/Users/shimyup/Documents/New project/Lettergo/SESSION_HANDOFF_BUILD_324.md
파일 읽고 현재 상태 파악 후, 5차 audit 의 Tier 2 항목들 (온보딩 6→3 페이지 /
Letter 카드 5요소 룰 / AI 칩 +1 보조 / gold 색 의미 변별 / ExactDrop 가격
티어 / brandInsights 홈 위젯) 중 가장 큰 영향 + 작은 코드 변경 우선순위로
순차 진행. 매 PR 마다 commit + push.
```

---

## 📁 핵심 파일 위치

### 코드
- `lib/state/app_state.dart` — 모든 상태 (8000+줄)
- `lib/features/inbox/widgets/letter_read_screen.dart` — redemption box
- `lib/features/inbox/screens/inbox_screen.dart` — letter card + filter
- `lib/features/compose/screens/compose_screen.dart` — Brand compose
- `lib/features/map/screens/world_map_screen.dart` — 지도 + 핀
- `lib/widgets/main_scaffold.dart` — nav + trial 모달
- `lib/core/services/recommendation_service.dart` — AI 추천
- `lib/core/services/notification_service.dart` — push (daily digest 포함)
- `lib/core/services/purchase_service.dart` — IAP

### i18n
- `lib/core/localization/app_localizations.dart` (30000+줄, 14언어)

### 문서
- `docs/release/` — IAP setup / walkthrough / checklist
- `~/.claude/projects/.../memory/MEMORY.md` — session handoff 인덱스
