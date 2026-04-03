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

echo "[preflight] validating release environment..."

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
