#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v flutter >/dev/null 2>&1; then
  echo "[clean] running flutter clean..."
  if ! flutter clean; then
    echo "[clean] flutter clean failed, fallback to local directory cleanup."
  fi
else
  echo "[clean] flutter not found, fallback to local directory cleanup."
fi

for target in build .dart_tool; do
  if [[ -d "$target" ]]; then
    rm -rf "$target"
    echo "[clean] removed ./$target"
  fi
done

echo "[clean] done."
du -sh build .dart_tool 2>/dev/null || true
