#!/usr/bin/env bash
# Build 324: ExactDrop paywall 화면을 실 iOS Simulator 에서 자동 캡처.
#
# 사용 시점: mockup PNG 대신 진짜 sandbox 캡처가 필요할 때 (ASC 정식 제출 전 권장).
#
# 사전 조건:
#   1. Xcode 설치 + iPhone Simulator 다운로드
#   2. Brand 계정 미리 생성 (이메일·비번 환경변수로 주입 또는 수동 로그인)
#   3. flutter doctor 통과
#
# 사용법:
#   ./scripts/capture_exact_drop_paywall_from_simulator.sh
#   ./scripts/capture_exact_drop_paywall_from_simulator.sh "iPhone 15 Pro Max"
#
# 출력:
#   docs/release/iap_screenshot_guides/exact_drop_100_paywall_simulator.png

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_NAME="${1:-iPhone 15 Pro Max}"
OUT_PATH="$ROOT_DIR/docs/release/iap_screenshot_guides/exact_drop_100_paywall_simulator.png"

echo "── ExactDrop paywall 캡처 ──"
echo "디바이스: $DEVICE_NAME"
echo "출력: $OUT_PATH"
echo ""

# 1. Simulator 부팅
echo "[1/5] Simulator 부팅..."
DEVICE_ID=$(xcrun simctl list devices available -j | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
target = '$DEVICE_NAME'
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['name'] == target and d.get('isAvailable', True):
            print(d['udid'])
            sys.exit(0)
print('NOT_FOUND', file=sys.stderr)
sys.exit(1)
")

if [ -z "$DEVICE_ID" ] || [ "$DEVICE_ID" = "NOT_FOUND" ]; then
  echo "❌ 디바이스 '$DEVICE_NAME' 못 찾음. 사용 가능 목록:"
  xcrun simctl list devices available | grep -E "^\s+iPhone" | head -10
  exit 1
fi

xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
open -a Simulator
sleep 3

# 2. Flutter 앱 빌드 + 설치 + 실행
echo "[2/5] Flutter 앱 빌드 + 설치 (debug)..."
cd "$ROOT_DIR"
flutter run \
  -d "$DEVICE_ID" \
  --debug \
  --target lib/main.dart \
  --dart-define=BETA_TESTFLIGHT_BUILD=true \
  --dart-define=BETA_FREE_PREMIUM=true \
  --no-resident >/dev/null &
FLUTTER_PID=$!

# 앱 실행까지 대기 (Splash → Onboarding → Home 까지 ~30초)
echo "[3/5] 앱 실행 대기 (~30초)..."
sleep 30

# 3. 사용자 가이드 — paywall 까지 수동 진입
echo ""
echo "════════════════════════════════════════════════════════════════"
echo " 🛑 수동 단계: Simulator 에서 다음 흐름으로 paywall 까지 진입"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  1. 가입 화면에서 Brand 계정 만들기"
echo "     (또는 ceo@airony.xyz / 미리 만든 Brand 계정으로 로그인)"
echo "  2. Home (지도) → 중앙 '📣 캠페인' 탭"
echo "  3. compose 화면 → 스크롤 → '🏢 브랜드 옵션' 섹션"
echo "  4. 시나리오 칩 중 '🎯 정확 좌표 단건' 탭"
echo "  5. paywall 다이얼로그가 노출되면 ↓ Enter 키 입력"
echo ""
read -p "준비됐으면 Enter (paywall 화면이 보일 때):"

# 4. 캡처
echo "[4/5] 스크린샷 캡처..."
mkdir -p "$(dirname "$OUT_PATH")"
xcrun simctl io "$DEVICE_ID" screenshot "$OUT_PATH"

# 5. 정리
echo "[5/5] 정리..."
kill "$FLUTTER_PID" 2>/dev/null || true
wait "$FLUTTER_PID" 2>/dev/null || true

echo ""
echo "✅ 완료: $OUT_PATH"
file "$OUT_PATH"
echo ""
echo "다음 단계:"
echo "  - 이 PNG 를 ASC 의 IAP 상품 'App Store 정보' → 스크린샷 업로드"
echo "  - mockup 보다 실 디자인 일치 → reject 위험 0"
