#!/usr/bin/env bash
# Build 413 (Auth Phase 2 실기기 테스트용):
#   AUTH_BIND_ENABLED=true 를 포함한 dart-define 을 iOS Xcode 빌드 설정에 주입.
#   이후 Xcode 에서 Runner 를 실기기로 Run 하면 정식 Firebase Auth 바인딩이 켜짐.
#
# 사용:
#   ./scripts/configure_ios_authtest.sh
#   open ios/Runner.xcworkspace   # Xcode 에서 디바이스 선택 후 Run
#
# 주의: --config-only 라 컴파일/서명 없이 설정만 갱신. 실제 빌드/배포는 Xcode 가 수행.
#   AUTH_EMAIL_FN_URL 미설정이면 이메일 OTP 는 on-screen fallback (바인딩 테스트엔 무관).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"

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
    exit 1
  fi
}
require_var FIREBASE_PROJECT_ID
require_var FIREBASE_API_KEY
require_var FIREBASE_STORAGE_BUCKET

DART_DEFINES=(
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
  # ★ Phase 2 테스트 플래그 — 정식 Firebase Auth 바인딩 활성.
  "--dart-define=AUTH_BIND_ENABLED=true"
)
[[ -n "${REVENUECAT_IOS_KEY:-}" ]] && DART_DEFINES+=("--dart-define=REVENUECAT_IOS_KEY=${REVENUECAT_IOS_KEY}")
[[ -n "${REVENUECAT_ANDROID_KEY:-}" ]] && DART_DEFINES+=("--dart-define=REVENUECAT_ANDROID_KEY=${REVENUECAT_ANDROID_KEY}")
[[ -n "${STADIA_MAPS_API_KEY:-}" ]] && DART_DEFINES+=("--dart-define=STADIA_MAPS_API_KEY=${STADIA_MAPS_API_KEY}")
[[ -n "${PERMANENT_ADMIN_EMAIL:-}" ]] && DART_DEFINES+=("--dart-define=PERMANENT_ADMIN_EMAIL=${PERMANENT_ADMIN_EMAIL}")
[[ -n "${BETA_ADMIN_EMAIL:-}" ]] && DART_DEFINES+=("--dart-define=BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}")
[[ -n "${AUTH_EMAIL_FN_URL:-}" ]] && DART_DEFINES+=("--dart-define=AUTH_EMAIL_FN_URL=${AUTH_EMAIL_FN_URL}")
[[ -n "${AUTH_SMS_FN_URL:-}" ]] && DART_DEFINES+=("--dart-define=AUTH_SMS_FN_URL=${AUTH_SMS_FN_URL}")

cd "$ROOT_DIR"
echo "[authtest] dart-defines:"
printf '  %s\n' "${DART_DEFINES[@]}"
echo "[authtest] flutter build ios --debug --config-only ..."
flutter build ios --debug --config-only "${DART_DEFINES[@]}"

echo ""
echo "✅ Xcode 설정 갱신 완료 (AUTH_BIND_ENABLED=true)."
echo "   1) open ios/Runner.xcworkspace"
echo "   2) 실기기 선택 → Run (▶)"
echo "   3) 테스트: 신규가입 / 기존로그인 / 앱 강제종료 후 재실행(세션 유지) /"
echo "      다기기 / 비번재설정 / 로그아웃. Firebase 콘솔 Authentication '사용자'"
echo "      탭에서 이메일 계정이 생기는지 + Firestore users/<id>.authUid 기록 확인."
