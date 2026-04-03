#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${1:-5BF13A4D-42FF-462A-9D5C-C560B1F89A97}"
LABEL="${2:-home}"
DATE_TAG="$(date +%F)"
OUT_DIR="$ROOT_DIR/docs/marketing/screenshots/raw"
OUT_FILE="$OUT_DIR/ios-${LABEL}-${DATE_TAG}.png"

mkdir -p "$OUT_DIR"

echo "[capture] launching app on simulator: $DEVICE_ID"
(
  cd "$ROOT_DIR"
  flutter run -d "$DEVICE_ID" --debug --target lib/main.dart --no-resident >/dev/null
)

echo "[capture] taking screenshot..."
xcrun simctl io "$DEVICE_ID" screenshot "$OUT_FILE" >/dev/null

echo "[capture] saved: $OUT_FILE"
file "$OUT_FILE"
