#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"
ANDROID_GOOGLE_SERVICES="$ROOT_DIR/android/app/google-services.json"
PRECHECK_SCRIPT="$ROOT_DIR/scripts/release_preflight.sh"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "[env] missing required variable: $name" >&2
    echo "[env] copy .env.example to .env.local and fill values." >&2
    exit 1
  fi
}

require_var FIREBASE_PROJECT_ID
require_var FIREBASE_API_KEY
require_var FIREBASE_STORAGE_BUCKET
require_var REVENUECAT_ANDROID_KEY
require_var REVENUECAT_IOS_KEY

if [[ -x "$PRECHECK_SCRIPT" ]]; then
  "$PRECHECK_SCRIPT"
else
  echo "[preflight] missing executable: $PRECHECK_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$ANDROID_GOOGLE_SERVICES" ]]; then
  echo "[secrets] android/app/google-services.json is missing."
  echo "[secrets] run: ./scripts/manage_firebase_secrets.sh restore"
fi

DART_DEFINES=(
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
  "--dart-define=REVENUECAT_ANDROID_KEY=${REVENUECAT_ANDROID_KEY}"
  "--dart-define=REVENUECAT_IOS_KEY=${REVENUECAT_IOS_KEY}"
)

if [[ -n "${STADIA_MAPS_API_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=STADIA_MAPS_API_KEY=${STADIA_MAPS_API_KEY}")
fi

# Build 414 (Auth Phase 3 STEP 1): .env.local 에 AUTH_BIND_ENABLED=true 일 때만 주입.
if [[ -n "${AUTH_BIND_ENABLED:-}" ]]; then
  echo "[android] AUTH_BIND_ENABLED=${AUTH_BIND_ENABLED}"
  DART_DEFINES+=("--dart-define=AUTH_BIND_ENABLED=${AUTH_BIND_ENABLED}")
fi

# Build 273 hardening:
# release_preflight.sh 가 BETA_* 플래그를 사전에 차단한다.
# 여기서는 preflight 를 통과한 값만 주입한다.
if [[ "${BETA_FREE_PREMIUM:-false}" == "true" ]]; then
  echo "[android] BETA_FREE_PREMIUM=true — premium will be granted without purchase."
  DART_DEFINES+=("--dart-define=BETA_FREE_PREMIUM=true")
fi

# Build 275 (P0): default true → false. 정식 출시 빌드 매출 손실 방지.
if [[ "${BETA_UPGRADE_SIMULATOR:-false}" == "true" ]]; then
  echo "[android] BETA_UPGRADE_SIMULATOR=true — upgrade will be granted without purchase."
  DART_DEFINES+=("--dart-define=BETA_UPGRADE_SIMULATOR=true")
fi

# Build 313 (BLOCKER fix): BETA_DISABLE_IN_RELEASE 패스스루 (iOS 와 동일).
if [[ -n "${BETA_DISABLE_IN_RELEASE:-}" ]]; then
  echo "[android] BETA_DISABLE_IN_RELEASE=${BETA_DISABLE_IN_RELEASE}"
  DART_DEFINES+=("--dart-define=BETA_DISABLE_IN_RELEASE=${BETA_DISABLE_IN_RELEASE}")
fi

# Build 314 (이중 안전망): 명시적 TestFlight 베타 빌드 flag.
if [[ "${BETA_TESTFLIGHT_BUILD:-false}" == "true" ]]; then
  echo "[android] BETA_TESTFLIGHT_BUILD=true — 명시적 베타 모드"
  DART_DEFINES+=("--dart-define=BETA_TESTFLIGHT_BUILD=true")
fi

# Build 399 (PR-II2 audit A3): PRODUCTION_BUILD layered defense.
if [[ "${PRODUCTION_BUILD:-false}" == "true" ]]; then
  echo "[android] PRODUCTION_BUILD=true — 모든 beta flag 강제 차단"
  DART_DEFINES+=("--dart-define=PRODUCTION_BUILD=true")
fi

# Build 399 (PR-II1 audit B11): APP_VERSION dart-define.
DART_DEFINES+=("--dart-define=APP_VERSION=${APP_VERSION:-dev}")

if [[ -n "${BETA_ADMIN_EMAIL:-}" ]]; then
  echo "[android] BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}"
  DART_DEFINES+=("--dart-define=BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}")
fi

# Build 272 (P0): 영구 어드민 이메일 dart-define 주입.
if [[ -n "${PERMANENT_ADMIN_EMAIL:-}" ]]; then
  echo "[android] PERMANENT_ADMIN_EMAIL=${PERMANENT_ADMIN_EMAIL}"
  DART_DEFINES+=("--dart-define=PERMANENT_ADMIN_EMAIL=${PERMANENT_ADMIN_EMAIL}")
fi

# Build 412 (PII sim CRITICAL fix): 서버급 API 키 클라이언트 주입 제거.
# 메일/SMS 는 Cloud Function relay 가 서버에서 발송, 클라이언트엔 함수 URL 만 주입.
if [[ -n "${AUTH_EMAIL_FN_URL:-}" ]]; then
  echo "[android] AUTH_EMAIL_FN_URL set"
  DART_DEFINES+=("--dart-define=AUTH_EMAIL_FN_URL=${AUTH_EMAIL_FN_URL}")
fi
if [[ -n "${AUTH_SMS_FN_URL:-}" ]]; then
  echo "[android] AUTH_SMS_FN_URL set"
  DART_DEFINES+=("--dart-define=AUTH_SMS_FN_URL=${AUTH_SMS_FN_URL}")
fi

cd "$ROOT_DIR"

echo "[android] building release AAB for Play Internal Test..."
flutter build appbundle --release "${DART_DEFINES[@]}" "$@"

echo "[android] building release APK for direct install QA..."
flutter build apk --release "${DART_DEFINES[@]}" "$@"

echo "[android] artifacts:"
ls -lh \
  "$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab" \
  "$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
