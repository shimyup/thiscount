#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/../.secrets/lettergo}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

fail() {
  echo "[preflight] ERROR: $1" >&2
  exit 1
}

warn() {
  echo "[preflight] WARN: $1"
}

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    fail "missing required variable: $name"
  fi
}

require_not_placeholder() {
  local name="$1"
  local value="${!name:-}"
  local lower
  lower="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower" == *"your_"* ]] || [[ "$lower" == *"placeholder"* ]] || [[ "$lower" == *"xxxx"* ]]; then
    fail "$name looks like a placeholder"
  fi
}

require_release_false() {
  local name="$1"
  local value="${!name:-false}"
  if [[ "$value" == "true" ]]; then
    fail "$name must be false or unset for release builds"
  fi
}

require_release_empty() {
  local name="$1"
  if [[ -n "${!name:-}" ]]; then
    fail "$name must be empty for release builds"
  fi
}

echo "[preflight] validating release environment..."

# Build 282: pubspec 의 build number 가 baseline (+1 같은 placeholder) 인지
# 검증. App Store Connect 가 중복 또는 너무 낮은 번호를 reject 하기 전에
# 빌드 단계에서 차단해서 시간 낭비를 막는다.
PUBSPEC_BUILD="$(grep -E "^version:\s*" "$ROOT_DIR/pubspec.yaml" | sed -E 's/.*\+([0-9]+).*/\1/')"
if [[ -z "$PUBSPEC_BUILD" ]] || ! [[ "$PUBSPEC_BUILD" =~ ^[0-9]+$ ]]; then
  fail "pubspec.yaml version 에서 build number 를 파싱할 수 없습니다 (예: 1.0.0+282)"
fi
if (( PUBSPEC_BUILD < 100 )); then
  fail "pubspec build number ($PUBSPEC_BUILD) 가 너무 낮습니다. 실제 빌드인지 확인 후 적절한 번호로 설정하세요."
fi

require_var FIREBASE_PROJECT_ID
require_var FIREBASE_API_KEY
require_var FIREBASE_STORAGE_BUCKET
require_var REVENUECAT_IOS_KEY
require_var REVENUECAT_ANDROID_KEY

require_not_placeholder FIREBASE_PROJECT_ID
require_not_placeholder FIREBASE_API_KEY
require_not_placeholder FIREBASE_STORAGE_BUCKET
require_not_placeholder REVENUECAT_IOS_KEY
require_not_placeholder REVENUECAT_ANDROID_KEY

# Build 312: 빌드 모드 분기 — 'testflight' = 베타 테스터 결제 시뮬 활성화,
# 'production' = 출시 신청 빌드 (모든 베타 플래그 강제 false).
# env var `RELEASE_TARGET` (default: production) 으로 선택.
RELEASE_TARGET="${RELEASE_TARGET:-production}"
echo "[preflight] RELEASE_TARGET=$RELEASE_TARGET"

if [[ "$RELEASE_TARGET" == "production" ]]; then
  # 출시 신청 빌드 — App Store Review 용. 베타 플래그 절대 활성화 안 됨.
  if [[ "${BETA_DISABLE_IN_RELEASE:-true}" != "true" ]]; then
    fail "BETA_DISABLE_IN_RELEASE must be true for RELEASE_TARGET=production"
  fi
  require_release_false BETA_FREE_PREMIUM
  require_release_false BETA_UPGRADE_SIMULATOR
  # Build 320: BETA_TESTFLIGHT_BUILD 가 production 빌드에 새어들어가지 않도록
  # 다층 방어 — 코드 default false + release_to_production.sh + 이 검증.
  require_release_false BETA_TESTFLIGHT_BUILD
  require_release_empty BETA_ADMIN_EMAIL
  # Build 409 (sim P1.29): PRODUCTION_BUILD=true 강제. BetaConstants.isAdmin 의
  #   비-production admin fallback(Build 408)이 정식 출시에서 차단되려면
  #   isProductionBuild=true 가 보장돼야 함. release_to_production.sh 가 주입
  #   하지만 누락 시 ceo@airony.xyz 가 App Store 빌드에서도 admin 진입 가능 →
  #   preflight 에서 hard-fail 로 안전망.
  if [[ "${PRODUCTION_BUILD:-false}" != "true" ]]; then
    fail "PRODUCTION_BUILD must be true for RELEASE_TARGET=production"
  fi
elif [[ "$RELEASE_TARGET" == "testflight" ]]; then
  # TestFlight 베타 빌드 — ASC IAP 미등록 상태에서도 테스터가 결제 흐름 체험.
  # BETA_DISABLE_IN_RELEASE=false + BETA_UPGRADE_SIMULATOR=true 가 정상.
  # BETA_FREE_PREMIUM=true 도 허용 (테스터 자동 Premium).
  echo "[preflight] testflight 빌드 — 베타 플래그 허용:"
  echo "  BETA_DISABLE_IN_RELEASE=${BETA_DISABLE_IN_RELEASE:-true}"
  echo "  BETA_FREE_PREMIUM=${BETA_FREE_PREMIUM:-false}"
  echo "  BETA_UPGRADE_SIMULATOR=${BETA_UPGRADE_SIMULATOR:-false}"
  echo "  BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL:-}"
else
  fail "RELEASE_TARGET must be 'testflight' or 'production' (got: $RELEASE_TARGET)"
fi

if [[ ! -f "$ROOT_DIR/android/app/google-services.json" ]]; then
  if [[ -f "$SECRETS_DIR/android/google-services.json" ]]; then
    fail "missing android/app/google-services.json (vault detected). run: ./scripts/manage_firebase_secrets.sh restore"
  fi
  fail "missing android/app/google-services.json"
fi

if [[ ! -f "$ROOT_DIR/ios/Runner/GoogleService-Info.plist" ]]; then
  if [[ -f "$SECRETS_DIR/ios/GoogleService-Info.plist" ]]; then
    fail "missing ios/Runner/GoogleService-Info.plist (vault detected). run: ./scripts/manage_firebase_secrets.sh restore"
  fi
  fail "missing ios/Runner/GoogleService-Info.plist"
fi

# Firebase app id / package-bundle consistency checks
EXPECTED_ANDROID_PACKAGE="io.thiscount"
EXPECTED_IOS_BUNDLE_ID="io.thiscount"

if ! rg -q "\"package_name\"[[:space:]]*:[[:space:]]*\"$EXPECTED_ANDROID_PACKAGE\"" \
  "$ROOT_DIR/android/app/google-services.json"; then
  fail "android google-services.json does not include package_name=$EXPECTED_ANDROID_PACKAGE"
fi

other_android_packages=$(
  rg -o "\"package_name\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" "$ROOT_DIR/android/app/google-services.json" \
    | sed -E 's/.*"package_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | sort -u \
    | rg -v "^${EXPECTED_ANDROID_PACKAGE}$" || true
)
if [[ -n "$other_android_packages" ]]; then
  warn "android google-services.json contains extra package_name values:"
  while IFS= read -r package_name; do
    [[ -z "$package_name" ]] && continue
    warn " - $package_name"
  done <<< "$other_android_packages"
fi

ios_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" \
  "$ROOT_DIR/ios/Runner/GoogleService-Info.plist" 2>/dev/null || true)
if [[ -z "$ios_bundle_id" ]]; then
  fail "ios GoogleService-Info.plist BUNDLE_ID is missing"
fi
if [[ "$ios_bundle_id" != "$EXPECTED_IOS_BUNDLE_ID" ]]; then
  fail "ios GoogleService-Info.plist BUNDLE_ID mismatch: expected $EXPECTED_IOS_BUNDLE_ID, got $ios_bundle_id"
fi

if [[ -z "${STADIA_MAPS_API_KEY:-}" ]]; then
  warn "STADIA_MAPS_API_KEY is empty: map labels may be mixed local languages."
fi

if ! command -v flutter >/dev/null 2>&1; then
  fail "flutter command not found in PATH"
fi

echo "[preflight] running flutter analyze..."
(
  cd "$ROOT_DIR"
  flutter analyze
)

echo "[preflight] running flutter test..."
(
  cd "$ROOT_DIR"
  flutter test
)

echo "[preflight] PASS"
