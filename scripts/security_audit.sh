#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[security] checking tracked secret files..."

tracked_violations=()
while IFS= read -r file; do
  case "$file" in
    *.p8|android/app/google-services.json|ios/Runner/GoogleService-Info.plist)
      tracked_violations+=("$file")
      ;;
  esac
done < <(git ls-files)

if ((${#tracked_violations[@]} > 0)); then
  echo "[security] FAIL: secret-like files are tracked by git:"
  for file in "${tracked_violations[@]}"; do
    echo "  - $file"
  done
  echo "[security] remove from tracking and rotate leaked keys before release."
  exit 1
fi

echo "[security] checking local sensitive files..."

local_warnings=()
for f in AuthKey_*.p8 SubscriptionKey_*.p8 android/app/google-services.json ios/Runner/GoogleService-Info.plist; do
  if compgen -G "$f" >/dev/null; then
    local_warnings+=("$f")
  fi
done

if ((${#local_warnings[@]} > 0)); then
  echo "[security] WARN: local sensitive files are present in repo directory:"
  for file in "${local_warnings[@]}"; do
    echo "  - $file"
  done
  echo "[security] keep them untracked and store long-term secrets outside the repo."
  echo "[security] run: ./scripts/manage_firebase_secrets.sh store"
fi

echo "[security] PASS"
