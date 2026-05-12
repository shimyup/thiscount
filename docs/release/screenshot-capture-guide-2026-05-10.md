# Thiscount 스토어 스크린샷 캡처 가이드 (Build 273)

Last updated: 2026-05-10

## 1. 목표 해상도 (App Store 필수)

| 디바이스 | 해상도 | 필수 여부 |
|---------|-------|-----------|
| 6.7" iPhone | 1290 × 2796 | **필수** (6장) |
| 6.5" iPhone | 1284 × 2778 | **필수** (6장) — 6.7" 자동 변환 가능 |
| 5.5" iPhone | 1242 × 2208 | 선택 |
| iPad Pro 12.9" | 2048 × 2732 | iPad 지원 시 필수 |

> **팁**: 6.7" 만 캡처해도 App Store Connect 가 자동으로 6.5" 로 다운스케일 가능. 우선 6.7" 6장만.

---

## 2. 캡처 화면 6장 (Build 273 기준)

| # | 화면 | 캡션 (ko) | 캡션 (en) | 셋업 |
|---|------|-----------|-----------|------|
| 1 | **지도 (탐험)** — 주변 핀 + 반경 원 + 줍기 가능 상태 | 지도 위를 떠도는 쿠폰을 GPS로 줍기 | Pick up coupons floating on the map nearby | Free 사용자, 시뮬레이터 위치 = 서울 강남, 8개 데모 핀 |
| 2 | **인박스 (탐색)** — 메인 4 칩 + 산업군 더보기 + 받은 쿠폰 카드 4-6개 | 식음·카페·뷰티·패션 필터로 빠른 탐색 | Quick filter by food, cafe, beauty, fashion | 받은 쿠폰 5+ 개, "쿠폰" 필터 활성화 상태 |
| 3 | **쿠폰 상세** — 코드/QR + 매장 정보 + redemption 버튼 | 매장에서 바로 사용하는 코드·QR | Redeem instantly with code or QR in-store | 받은 쿠폰 1장 열기 |
| 4 | **Premium 결제** — 가격 카드 + 무료 체험 배너 + 혜택 4개 | Premium 으로 반경 5배 + 쿨다운 6배 빠르게 | Premium: 5× wider pickup, 6× faster cooldown | Free 사용자, Premium 화면 진입 |
| 5 | **Compose (Brand)** — "📣 캠페인 발송" 헤더 (orange) + 위치 지정 + 옵션 | Brand 캠페인 — 정확한 위치에 메시지 배포 | Brand campaigns — drop pins at exact spots | Brand 사용자, compose 진입 |
| 6 | **Profile** — 통계 카드 + Hunt Wallet + 설정 collapse | 받은 혜택을 한 곳에서 관리 | All your rewards in one wallet | 활동 누적이 있는 사용자 |

---

## 3. 캡처 절차

### A. 시뮬레이터 준비
```bash
# iPhone 17 Pro Max (6.7" — 1290×2796) 부팅
xcrun simctl boot "iPhone 17 Pro Max"
open -a Simulator

# 시간을 9:41 로 고정 (App Store 관행)
xcrun simctl status_bar booted override --time "9:41" \
  --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
```

### B. 앱 실행 (Build 273 debug)
```bash
cd "/Users/shimyup/Documents/New project/Lettergo"
ENV_FILE="/Users/shimyup/Documents/New project/Lettergo/.env.local" \
  ./scripts/run_ios_debug.sh "iPhone 17 Pro Max"
```

### C. 화면별 캡처 (각 화면 도달 후 실행)
```bash
SHOT_DIR="/Users/shimyup/Documents/New project/Lettergo/docs/marketing/screenshots/raw"
mkdir -p "$SHOT_DIR"

# 화면별로 액션 후 다음 명령 실행 (각 줄을 1개 화면 도달 후 실행)
xcrun simctl io booted screenshot "$SHOT_DIR/01-map.png"
xcrun simctl io booted screenshot "$SHOT_DIR/02-inbox.png"
xcrun simctl io booted screenshot "$SHOT_DIR/03-coupon-detail.png"
xcrun simctl io booted screenshot "$SHOT_DIR/04-premium.png"
xcrun simctl io booted screenshot "$SHOT_DIR/05-compose-brand.png"
xcrun simctl io booted screenshot "$SHOT_DIR/06-profile.png"
```

### D. 14개 언어 capture (선택)
한국어 + 영어 minimum 으로 시작. 다른 언어는 launch 후 추가:
```bash
# 시뮬레이터의 언어 변경: Settings > General > Language & Region
# 또는 in-app: Profile > Display > Language picker (각 언어 선택 후 다시 캡처)
```

---

## 4. 후처리

### A. 해상도 검증
```bash
# 6.7" 검증 (1290×2796)
sips -g pixelWidth -g pixelHeight "$SHOT_DIR/01-map.png"
```

### B. 캡션 + 프레임 추가 (선택)
- Figma / Sketch / Photoshop 에서 [appstore-67-template-1290x2796.svg](../marketing/creative-kit/appstore-67-template-1290x2796.svg) 사용
- 또는 Apple Marketing Tool: https://www.apple.com/itunes/marketing-on-itunes/identity-guidelines.html

### C. 5.5" / 6.5" 자동 변환
App Store Connect 에 6.7" 만 업로드하면 다른 사이즈 자동 생성. 별도 캡처 불필요.

---

## 5. 캡처 팁

1. **알림 배너 비활성화**: Settings > Notifications 에서 Do Not Disturb
2. **시간 9:41**: 위 status_bar override 명령 사용
3. **상태바 통일**: WiFi 3 bars, 배터리 100%, charged
4. **데이터 시드**: 시뮬레이터 첫 실행 시 자동으로 8개 데모 핀 배치됨 (`[Tutorial] 환영 편지 배치`)
5. **언어 분리**: KR + EN 별로 raw/ko/, raw/en/ 폴더 분리해서 저장 권장

---

## 6. App Store Connect 업로드

1. App Store Connect → Apps → Thiscount → App Store → Localization (한국어/English) 선택
2. iPhone 6.7" 섹션에 6장 드래그&드롭 (순서: 01 → 06)
3. 각 스크린샷 캡션 입력 (위 표 참고)
4. 6.5" 자동 생성 확인 또는 별도 업로드
5. **Save**

---

## 7. 자동 캡처 스크립트 (TODO)

향후 개선: `scripts/capture_ios_route_set.sh` 가 6개 핵심 화면을 자동 navigate + capture.
현재는 Build 273 신규 화면 (Premium trial 배너, Compose Brand 헤더 분리) 기준 manual 캡처 필요.
