#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/../.secrets/lettergo}"

ANDROID_SRC="$ROOT_DIR/android/app/google-services.json"
IOS_SRC="$ROOT_DIR/ios/Runner/GoogleService-Info.plist"

ANDROID_DST="$SECRETS_DIR/android/google-services.json"
IOS_DST="$SECRETS_DIR/ios/GoogleService-Info.plist"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/manage_firebase_secrets.sh status
  ./scripts/manage_firebase_secrets.sh store
  ./scripts/manage_firebase_secrets.sh restore

Environment:
  SECRETS_DIR  External secrets directory
               (default: ../.secrets/lettergo)
USAGE
}

ensure_secret_dirs() {
  mkdir -p "$(dirname "$ANDROID_DST")" "$(dirname "$IOS_DST")"
}

print_status() {
  echo "[secrets] project android: $([[ -f "$ANDROID_SRC" ]] && echo present || echo missing)"
  echo "[secrets] project ios:     $([[ -f "$IOS_SRC" ]] && echo present || echo missing)"
  echo "[secrets] vault android:   $([[ -f "$ANDROID_DST" ]] && echo present || echo missing)"
  echo "[secrets] vault ios:       $([[ -f "$IOS_DST" ]] && echo present || echo missing)"
  echo "[secrets] vault path:      $SECRETS_DIR"
}

store_files() {
  ensure_secret_dirs
  if [[ -f "$ANDROID_SRC" ]]; then
    mv "$ANDROID_SRC" "$ANDROID_DST"
    chmod 600 "$ANDROID_DST" || true
    echo "[secrets] moved android google-services.json -> vault"
  else
    echo "[secrets] android google-services.json not found in project"
  fi

  if [[ -f "$IOS_SRC" ]]; then
    mv "$IOS_SRC" "$IOS_DST"
    chmod 600 "$IOS_DST" || true
    echo "[secrets] moved iOS GoogleService-Info.plist -> vault"
  else
    echo "[secrets] iOS GoogleService-Info.plist not found in project"
  fi
}

restore_files() {
  if [[ -f "$ANDROID_DST" ]]; then
    mkdir -p "$(dirname "$ANDROID_SRC")"
    cp "$ANDROID_DST" "$ANDROID_SRC"
    echo "[secrets] restored android google-services.json from vault"
  else
    echo "[secrets] vault android file missing: $ANDROID_DST"
  fi

  if [[ -f "$IOS_DST" ]]; then
    mkdir -p "$(dirname "$IOS_SRC")"
    cp "$IOS_DST" "$IOS_SRC"
    echo "[secrets] restored iOS GoogleService-Info.plist from vault"
  else
    echo "[secrets] vault iOS file missing: $IOS_DST"
  fi
}

main() {
  local cmd="${1:-status}"
  case "$cmd" in
    status) print_status ;;
    store) store_files ;;
    restore) restore_files ;;
    -h|--help|help) usage ;;
    *)
      echo "[secrets] unknown command: $cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
