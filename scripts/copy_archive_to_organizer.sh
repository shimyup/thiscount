#!/usr/bin/env bash
# Build 324: build/ios/archive/Runner.xcarchive 를 Xcode Organizer 가 인덱싱
# 하는 위치 (~/Library/Developer/Xcode/Archives/<date>/) 로 복사.
# + ScreenPreventerKit dSYM 누락 자동 fix (Build 213/244 의 반복 이슈).
#
# 사용법:
#   ./scripts/copy_archive_to_organizer.sh
#   ./scripts/copy_archive_to_organizer.sh "Thiscount 5-24-26, 2.54 PM"
#
# 사후:
#   Xcode → Window → Organizer (⌥⌘⇧O) → Archives 탭에서 자동 인식.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/build/ios/archive/Runner.xcarchive"

if [[ ! -d "$SRC" ]]; then
  echo "❌ archive 없음: $SRC" >&2
  echo "   먼저 빌드: ./scripts/build_ios_release.sh ipa" >&2
  exit 1
fi

DATE_DIR=$(date +%F)
DEST_DIR="$HOME/Library/Developer/Xcode/Archives/$DATE_DIR"
DEFAULT_NAME="Thiscount $(date '+%-m-%d-%y, %-I.%M %p').xcarchive"
ARCHIVE_NAME="${1:-$DEFAULT_NAME}"
DEST="$DEST_DIR/$ARCHIVE_NAME"

mkdir -p "$DEST_DIR"

if [[ -d "$DEST" ]]; then
  echo "[copy] 기존 archive 덮어씀: $DEST"
  rm -rf "$DEST"
fi

echo "[copy] $SRC → $DEST"
cp -R "$SRC" "$DEST"

# ScreenPreventerKit dSYM 자동 fix (UUID 9D0A700C 누락 이슈)
SPK_BIN="$DEST/Products/Applications/Runner.app/Frameworks/ScreenPreventerKit.framework/ScreenPreventerKit"
SPK_DSYM="$DEST/dSYMs/ScreenPreventerKit.framework.dSYM"
if [[ -f "$SPK_BIN" && ! -d "$SPK_DSYM" ]]; then
  echo "[dsym] ScreenPreventerKit dSYM 누락 — 생성"
  dsymutil "$SPK_BIN" -o "$SPK_DSYM" 2>&1 | tail -3
fi

echo ""
echo "✅ 완료. Xcode Organizer 에서 다음으로 인식:"
echo "    \"$ARCHIVE_NAME\""
echo ""
echo "다음 단계:"
echo "  1. Xcode 열기 (open -a Xcode)"
echo "  2. Window → Organizer (⌥⌘⇧O)"
echo "  3. Archives 탭에서 위 archive 선택"
echo "  4. Distribute App → App Store Connect → Upload"
