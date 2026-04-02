#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT_DIR="$ROOT_DIR/docs/marketing/creative-kit"
OUT_DIR="$KIT_DIR/exports"

mkdir -p "$OUT_DIR"

echo "[marketing] source: $KIT_DIR"
echo "[marketing] output: $OUT_DIR"

convert_with_sips() {
  local src="$1"
  local out="$2"
  sips -s format png "$src" --out "$out" >/dev/null 2>&1
}

convert_with_magick() {
  local src="$1"
  local out="$2"
  magick "$src" "$out"
}

convert_with_qlmanage() {
  local src="$1"
  local expected="$2"
  local tmp
  tmp="$(mktemp -d)"
  qlmanage -t -s 3000 -o "$tmp" "$src" >/dev/null 2>&1 || return 1
  local generated
  generated="$(find "$tmp" -maxdepth 1 -name '*.png' | head -n 1)"
  [[ -n "$generated" ]] || return 1
  cp "$generated" "$expected"
}

for src in "$KIT_DIR"/*.svg; do
  base="$(basename "$src" .svg)"
  out="$OUT_DIR/$base.png"

  if command -v sips >/dev/null 2>&1 && convert_with_sips "$src" "$out"; then
    echo "[marketing] created (sips): $out"
    continue
  fi

  if command -v magick >/dev/null 2>&1 && convert_with_magick "$src" "$out" >/dev/null 2>&1; then
    echo "[marketing] created (magick): $out"
    continue
  fi

  if command -v qlmanage >/dev/null 2>&1 && convert_with_qlmanage "$src" "$out"; then
    echo "[marketing] created (qlmanage): $out"
    continue
  fi

  echo "[marketing] WARN: failed to rasterize $src"
done

echo "[marketing] done"
