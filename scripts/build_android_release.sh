#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"
ANDROID_GOOGLE_SERVICES="$ROOT_DIR/android/app/google-services.json"
PRECHECK_SCRIPT="$ROOT_DIR/scripts/release_preflight.sh"

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
require_var REVENUECAT_ANDROID_KEY
require_var REVENUECAT_IOS_KEY

if [[ -x "$PRECHECK_SCRIPT" ]]; then
  "$PRECHECK_SCRIPT"
else
  echo "[preflight] missing executable: $PRECHECK_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$ANDROID_GOOGLE_SERVICES" ]]; then
  echo "[secrets] android/app/google-services.json is missing."
  echo "[secrets] run: ./scripts/manage_firebase_secrets.sh restore"
fi

DART_DEFINES=(
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
  "--dart-define=REVENUECAT_ANDROID_KEY=${REVENUECAT_ANDROID_KEY}"
  "--dart-define=REVENUECAT_IOS_KEY=${REVENUECAT_IOS_KEY}"
)

if [[ -n "${STADIA_MAPS_API_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=STADIA_MAPS_API_KEY=${STADIA_MAPS_API_KEY}")
fi

# 베타 테스트 기간 동안 RevenueCat/Play 연동 없이 Premium을 무료로 활성화.
# 정식 출시 빌드에서는 .env.local 에서 BETA_FREE_PREMIUM 제거.
if [[ "${BETA_FREE_PREMIUM:-false}" == "true" ]]; then
  echo "[android] BETA_FREE_PREMIUM=true — premium will be granted without purchase."
  DART_DEFINES+=("--dart-define=BETA_FREE_PREMIUM=true")
fi

# 베타 업그레이드 시뮬레이터 (Build 213) — RC/Play 미연동 시에도 업그레이드
# 흐름이 동작하도록 즉시 활성화. 정식 출시 시 명시적으로 `false` 지정.
if [[ "${BETA_UPGRADE_SIMULATOR:-true}" == "true" ]]; then
  echo "[android] BETA_UPGRADE_SIMULATOR=true — upgrade will be granted without purchase."
  DART_DEFINES+=("--dart-define=BETA_UPGRADE_SIMULATOR=true")
fi

# 베타 테스트 관리자 이메일 — 릴리스 빌드에서도 이 이메일만 관리자 패널/브랜드
# 권한 활성. 정식 출시 시 .env.local 에서 BETA_ADMIN_EMAIL 제거하면 자동 잠김.
if [[ -n "${BETA_ADMIN_EMAIL:-}" ]]; then
  echo "[android] BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}"
  DART_DEFINES+=("--dart-define=BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}")
fi

# Build 272 (P0): 영구 어드민 이메일 dart-define 주입.
if [[ -n "${PERMANENT_ADMIN_EMAIL:-}" ]]; then
  echo "[android] PERMANENT_ADMIN_EMAIL=${PERMANENT_ADMIN_EMAIL}"
  DART_DEFINES+=("--dart-define=PERMANENT_ADMIN_EMAIL=${PERMANENT_ADMIN_EMAIL}")
fi

# Resend 이메일 프로바이더 (OTP 실제 발송).
if [[ -n "${RESEND_API_KEY:-}" && -n "${RESEND_FROM_EMAIL:-}" ]]; then
  echo "[android] RESEND configured: ${RESEND_FROM_EMAIL}"
  DART_DEFINES+=("--dart-define=RESEND_API_KEY=${RESEND_API_KEY}")
  DART_DEFINES+=("--dart-define=RESEND_FROM_EMAIL=${RESEND_FROM_EMAIL}")
fi

# SendGrid 이메일 프로바이더 (폴백).
if [[ -n "${SENDGRID_API_KEY:-}" && -n "${SENDGRID_FROM_EMAIL:-}" ]]; then
  echo "[android] SENDGRID configured: ${SENDGRID_FROM_EMAIL}"
  DART_DEFINES+=("--dart-define=SENDGRID_API_KEY=${SENDGRID_API_KEY}")
  DART_DEFINES+=("--dart-define=SENDGRID_FROM_EMAIL=${SENDGRID_FROM_EMAIL}")
fi

cd "$ROOT_DIR"

echo "[android] building release AAB for Play Internal Test..."
flutter build appbundle --release "${DART_DEFINES[@]}" "$@"

echo "[android] building release APK for direct install QA..."
flutter build apk --release "${DART_DEFINES[@]}" "$@"

echo "[android] artifacts:"
ls -lh \
  "$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab" \
  "$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
