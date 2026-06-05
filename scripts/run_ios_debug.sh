#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"

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

DART_DEFINES=(
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
)

if [[ -n "${STADIA_MAPS_API_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=STADIA_MAPS_API_KEY=${STADIA_MAPS_API_KEY}")
fi

# Build 414 (Auth Phase 3 STEP 1/2): .env.local 에 AUTH_BIND_ENABLED=true 일 때만
#   주입 — 시뮬레이터 debug 로 그림자 바인딩 검증용.
if [[ -n "${AUTH_BIND_ENABLED:-}" ]]; then
  echo "[ios-debug] AUTH_BIND_ENABLED=${AUTH_BIND_ENABLED}"
  DART_DEFINES+=("--dart-define=AUTH_BIND_ENABLED=${AUTH_BIND_ENABLED}")
fi

if [[ -n "${REVENUECAT_IOS_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=REVENUECAT_IOS_KEY=${REVENUECAT_IOS_KEY}")
fi

if [[ -n "${REVENUECAT_ANDROID_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=REVENUECAT_ANDROID_KEY=${REVENUECAT_ANDROID_KEY}")
fi

if [[ -n "${RC_REAL_PURCHASES_IN_DEBUG:-}" ]]; then
  DART_DEFINES+=("--dart-define=RC_REAL_PURCHASES_IN_DEBUG=${RC_REAL_PURCHASES_IN_DEBUG}")
fi

if [[ -n "${PERMANENT_ADMIN_EMAIL:-}" ]]; then
  DART_DEFINES+=("--dart-define=PERMANENT_ADMIN_EMAIL=${PERMANENT_ADMIN_EMAIL}")
fi

if [[ -n "${BETA_ADMIN_EMAIL:-}" ]]; then
  DART_DEFINES+=("--dart-define=BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}")
fi

# Build 414: Cloud Function URL 들 (.env.local 에 있을 때만) — 디버그에서도 실제
#   이메일 relay / AI 쿠폰 생성 테스트 가능하게.
if [[ -n "${AUTH_EMAIL_FN_URL:-}" ]]; then
  echo "[ios-debug] AUTH_EMAIL_FN_URL set"
  DART_DEFINES+=("--dart-define=AUTH_EMAIL_FN_URL=${AUTH_EMAIL_FN_URL}")
fi
if [[ -n "${AUTH_SMS_FN_URL:-}" ]]; then
  DART_DEFINES+=("--dart-define=AUTH_SMS_FN_URL=${AUTH_SMS_FN_URL}")
fi
if [[ -n "${COUPON_AI_FN_URL:-}" ]]; then
  echo "[ios-debug] COUPON_AI_FN_URL set"
  DART_DEFINES+=("--dart-define=COUPON_AI_FN_URL=${COUPON_AI_FN_URL}")
fi

cd "$ROOT_DIR"

DEVICE_ID=""
if [[ $# -gt 0 && "$1" != --* ]]; then
  DEVICE_ID="$1"
  shift
fi
if [[ -n "$DEVICE_ID" ]]; then
  FLUTTER_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --route)
        if [[ $# -lt 2 ]]; then
          echo "[ios-debug] --route requires a route value" >&2
          exit 1
        fi
        DART_DEFINES+=("--dart-define=APP_INITIAL_ROUTE=$2")
        shift 2
        ;;
      --route=*)
        DART_DEFINES+=("--dart-define=APP_INITIAL_ROUTE=${1#--route=}")
        shift
        ;;
      *)
        FLUTTER_ARGS+=("$1")
        shift
        ;;
    esac
  done
  flutter run -d "$DEVICE_ID" --debug "${DART_DEFINES[@]}" "${FLUTTER_ARGS[@]}"
else
  FLUTTER_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --route)
        if [[ $# -lt 2 ]]; then
          echo "[ios-debug] --route requires a route value" >&2
          exit 1
        fi
        DART_DEFINES+=("--dart-define=APP_INITIAL_ROUTE=$2")
        shift 2
        ;;
      --route=*)
        DART_DEFINES+=("--dart-define=APP_INITIAL_ROUTE=${1#--route=}")
        shift
        ;;
      *)
        FLUTTER_ARGS+=("$1")
        shift
        ;;
    esac
  done
  flutter run --debug "${DART_DEFINES[@]}" "${FLUTTER_ARGS[@]}"
fi
