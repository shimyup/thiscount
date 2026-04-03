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

if [[ -n "${REVENUECAT_IOS_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=REVENUECAT_IOS_KEY=${REVENUECAT_IOS_KEY}")
fi

if [[ -n "${REVENUECAT_ANDROID_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=REVENUECAT_ANDROID_KEY=${REVENUECAT_ANDROID_KEY}")
fi

cd "$ROOT_DIR"

DEVICE_ID="${1:-}"
if [[ -n "$DEVICE_ID" ]]; then
  shift
  flutter run -d "$DEVICE_ID" --debug "${DART_DEFINES[@]}" "$@"
else
  flutter run --debug "${DART_DEFINES[@]}" "$@"
fi
