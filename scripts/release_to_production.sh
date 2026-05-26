#!/usr/bin/env bash
# 출시 신청 (App Store Review) 용 빌드.
# 모든 베타 플래그 강제 false — 정식 출시 빌드에 베타 코드가 새어 들어가지 않도록.
#
# 사용:
#   ./scripts/release_to_production.sh
#
# 단계:
#   1. .env.local BETA 플래그 release 모드 강제 (BETA_DISABLE_IN_RELEASE=true 등)
#   2. RELEASE_TARGET=production export (preflight 강제)
#   3. build_ios_release.sh — archive + IPA export
#   4. xcrun altool upload — ASC delivery
#   5. asc_assign_to_internal.py — Internal Testing 그룹 자동 추가 (skip 가능)
#   6. .env.local 원복
#
# 환경변수:
#   SKIP_GROUP_ASSIGN=1 → 그룹 추가 스킵
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.local"
PUBSPEC="$ROOT_DIR/pubspec.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ $ENV_FILE 없음 — release 빌드 불가." >&2
  exit 1
fi

BUILD_NUM=$(grep -E "^version:" "$PUBSPEC" | sed -E 's/.*\+([0-9]+).*/\1/')
echo "==[ Build $BUILD_NUM PRODUCTION 출시 빌드 ]=="

BACKUP="/tmp/env.local.bak.prod.$BUILD_NUM"
cp "$ENV_FILE" "$BACKUP"
echo "[env] backup → $BACKUP"

python3 - <<PY
with open("$ENV_FILE", "r") as f: c = f.read()
import re
# 출시 빌드 — 모든 베타 플래그 강제 false
c = re.sub(r"BETA_DISABLE_IN_RELEASE=.*", "BETA_DISABLE_IN_RELEASE=true", c)
c = re.sub(r"BETA_FREE_PREMIUM=.*", "BETA_FREE_PREMIUM=false", c)
c = re.sub(r"BETA_UPGRADE_SIMULATOR=.*", "BETA_UPGRADE_SIMULATOR=false", c)
c = re.sub(r"BETA_TESTFLIGHT_BUILD=.*", "BETA_TESTFLIGHT_BUILD=false", c)
c = re.sub(r"BETA_ADMIN_EMAIL=.*", "BETA_ADMIN_EMAIL=", c)
# Build 399 (PR-II2 audit A3): PRODUCTION_BUILD=true 명시 주입 — beta flag
#   layered defense 활성화 (BetaConstants.isProductionBuild → 모든 beta flag
#   강제 차단). 빌드 스크립트 실수로 BETA flag 가 새어 들어가도 막힘.
if "PRODUCTION_BUILD=" in c:
    c = re.sub(r"PRODUCTION_BUILD=.*", "PRODUCTION_BUILD=true", c)
else:
    c += "\nPRODUCTION_BUILD=true\n"
with open("$ENV_FILE", "w") as f: f.write(c)
PY
echo "[env] production 모드 적용:"
grep "^BETA_" "$ENV_FILE" | sed 's/^/  /'

export RELEASE_TARGET=production
trap 'cp "$BACKUP" "$ENV_FILE"; echo "[env] 원복 (trap)"' EXIT

EXPORT_PLIST="/tmp/ExportOptions-${BUILD_NUM}.plist"
if [[ ! -f "$EXPORT_PLIST" ]]; then
  TEMPLATE="/tmp/ExportOptions-303.plist"
  [[ -f "$TEMPLATE" ]] || TEMPLATE="$ROOT_DIR/ios/ExportOptions-AppStore.plist"
  if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$EXPORT_PLIST"
  else
    echo "❌ ExportOptions template 없음" >&2
    exit 1
  fi
fi

echo ""
echo "==[ 1/3 IPA 빌드 (production) ]=="
IOS_BUILD_MODE=ipa IOS_EXPORT_OPTIONS_PLIST="$EXPORT_PLIST" \
  "$ROOT_DIR/scripts/build_ios_release.sh"

IPA_PATH="$ROOT_DIR/build/ios/ipa/Thiscount.ipa"
echo ""
echo "==[ 2/3 ASC 업로드 ]=="
ASC_KEY_ID="${ASC_API_KEY_ID:-PPC3B3JS5V}"
ASC_ISSUER_ID="${ASC_API_ISSUER_ID:-1cfdd647-e5d9-4f98-bcd6-fff8299f80ec}"
xcrun altool --upload-app -f "$IPA_PATH" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

if [[ "${SKIP_GROUP_ASSIGN:-0}" != "1" ]]; then
  echo ""
  echo "==[ 3/3 Internal 그룹 자동 추가 (출시 직전 검증용) ]=="
  python3 "$ROOT_DIR/scripts/asc_assign_to_internal.py" "$BUILD_NUM" || true
fi

cp "$BACKUP" "$ENV_FILE"
trap - EXIT
echo ""
echo "==[ ✅ Production 빌드 완료 ]=="
echo "Build $BUILD_NUM → 출시 신청 가능. ASC 콘솔에서 'Submit for Review' 진행."
