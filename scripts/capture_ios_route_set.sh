#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${1:-5BF13A4D-42FF-462A-9D5C-C560B1F89A97}"
DEVICE_TAG="${2:-ios}"
DATE_TAG="$(date +%F)"
OUT_DIR="$ROOT_DIR/docs/marketing/screenshots/raw"

mkdir -p "$OUT_DIR"

capture_route() {
  local route="$1"
  local label="$2"
  local out_file="$OUT_DIR/${DEVICE_TAG}-${label}-${DATE_TAG}.png"

  echo "[capture-set] route=$route label=$label"
  (
    cd "$ROOT_DIR"
    flutter run -d "$DEVICE_ID" --debug --target lib/main.dart --route "$route" --no-resident >/dev/null
  )
  sleep 2
  xcrun simctl io "$DEVICE_ID" screenshot "$out_file" >/dev/null
  echo "[capture-set] saved: $out_file"
}

capture_route "/onboarding" "onboarding"
capture_route "/auth" "auth"
capture_route "/home" "home"
capture_route "/premium_welcome" "premium-welcome"
capture_route "/splash" "splash"

echo "[capture-set] done"
