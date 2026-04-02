#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT_DIR/docs/marketing/screenshots/raw"
READY_DIR="$ROOT_DIR/docs/marketing/screenshots/ready"

mkdir -p "$READY_DIR/ios67" "$READY_DIR/ios65"

convert_size() {
  local src="$1"
  local dst="$2"
  local width="$3"
  local height="$4"
  sips -z "$height" "$width" "$src" --out "$dst" >/dev/null 2>&1
}

# 6.7" set (1290x2796)
convert_size "$RAW_DIR/ios67-onboarding-2026-04-03.png" "$READY_DIR/ios67/01-onboarding-1290x2796.png" 1290 2796
convert_size "$RAW_DIR/ios67-auth-2026-04-03.png" "$READY_DIR/ios67/02-auth-1290x2796.png" 1290 2796
convert_size "$RAW_DIR/ios67-home-2026-04-03.png" "$READY_DIR/ios67/03-home-1290x2796.png" 1290 2796
convert_size "$RAW_DIR/ios67-premium-welcome-2026-04-03.png" "$READY_DIR/ios67/04-premium-1290x2796.png" 1290 2796
convert_size "$RAW_DIR/ios67-splash-2026-04-03.png" "$READY_DIR/ios67/05-splash-1290x2796.png" 1290 2796

# 6.5" set (1284x2778)
convert_size "$RAW_DIR/ios65-onboarding-2026-04-03.png" "$READY_DIR/ios65/01-onboarding-1284x2778.png" 1284 2778
convert_size "$RAW_DIR/ios65-auth-2026-04-03.png" "$READY_DIR/ios65/02-auth-1284x2778.png" 1284 2778
convert_size "$RAW_DIR/ios65-home-2026-04-03.png" "$READY_DIR/ios65/03-home-1284x2778.png" 1284 2778
convert_size "$RAW_DIR/ios65-premium-welcome-2026-04-03.png" "$READY_DIR/ios65/04-premium-1284x2778.png" 1284 2778
convert_size "$RAW_DIR/ios65-splash-2026-04-03.png" "$READY_DIR/ios65/05-splash-1284x2778.png" 1284 2778

echo "[screenshots] ready set generated:"
echo "  - $READY_DIR/ios67"
echo "  - $READY_DIR/ios65"
