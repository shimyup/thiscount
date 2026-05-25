import 'package:flutter/foundation.dart';

/// SharedPreferences / SecureStorage 키 상수 모음
///
/// 여러 파일에서 공유하는 키는 여기에 정의하여 오타·불일치를 방지합니다.
abstract class PrefKeys {
  // ── 구매 상태 (PurchaseService ↔ AppState 공유) ─────────────────────────
  static const String purchaseIsPremium = 'purchase_isPremium';
  static const String purchaseIsBrand = 'purchase_isBrand';
  static const String purchaseNextBillingDate = 'purchase_next_billing_date';
  static const String purchaseGiftExpiry = 'purchase_giftExpiry';
  static const String purchaseScheduledPlanChangeDate =
      'purchase_scheduled_plan_change_date';
  static const String purchaseScheduledPlanChangeTarget =
      'purchase_scheduled_plan_change_target';
  // legacy key (마이그레이션 후 삭제 예정)
  static const String purchaseScheduledDowngradeLegacy =
      'purchase_scheduledDowngrade';

  // ── 유저 프로필 (AppState) ────────────────────────────────────────────────
  static const String brandExtraMonthlyQuota = 'brandExtraMonthlyQuota';
  static const String towerColor = 'towerColor';
  static const String towerAccentEmoji = 'towerAccentEmoji';
  static const String isBrand = 'isBrand';
  static const String brandName = 'brandName';
  static const String profileImagePath = 'profileImagePath';

  // ── 프리미엄 특급 배송 / 친구 초대 리워드 (AppState) ──────────────────────
  static const String dailyPremiumExpressSentCount =
      'dailyPremiumExpressSentCount';
  static const String dailyPremiumExpressDateKey = 'dailyPremiumExpressDateKey';
  static const String inviteRewardCredits = 'inviteRewardCredits';
  static const String inviteAppliedCode = 'inviteAppliedCode';
  static const String inviteRewardAtEpochMs = 'inviteRewardAtEpochMs';
  static const String inviteCode = 'inviteCode';
}

/// DEBUG 전용 상수 (kDebugMode 체크 후에만 사용)
abstract class DebugConstants {
  /// 자동으로 브랜드 계정으로 승급시킬 테스트 이메일.
  /// 디버그 빌드에서만 적용됨. 릴리스 빌드의 관리자 이메일은
  /// dart-define BETA_ADMIN_EMAIL 로 주입 (BetaConstants 참조).
  static const String testBrandEmail = 'ceo@airony.xyz';
}

/// 베타 테스트 기간 전용 상수
///
/// 릴리스 빌드에서도 허용할 관리자 이메일을 dart-define으로 주입.
///   --dart-define=BETA_ADMIN_EMAIL=shimyup@gmail.com
/// 값이 비어 있으면 릴리스 빌드에서 관리자 기능이 모두 차단됨.
/// 정식 출시 전 .env.local 에서 BETA_ADMIN_EMAIL 제거하면 자동으로 잠김.
///
/// Build 207 강화:
///   - `disableInRelease=true` (default) 면 릴리스 빌드에서 코드가 자동 차단.
///     실수로 빌드 스크립트에 BETA_ADMIN_EMAIL 이 남아 있어도 안전.
///   - 정식 출시 후에도 명시적으로 베타 관리자를 켜고 싶으면 빌드 시
///     `--dart-define=BETA_DISABLE_IN_RELEASE=false` 로 override.
abstract class BetaConstants {
  /// Build 272 (P0): 영구 어드민 이메일을 hardcoded → dart-define 으로 변경.
  /// 정식 배포 빌드에서 무단 admin 자동 가입을 차단하기 위함.
  /// 빌드 시 `--dart-define=PERMANENT_ADMIN_EMAIL=ceo@airony.xyz` 로 명시 주입.
  /// 값이 비어 있으면 admin auto-bootstrap 동작 안 함.
  static const String permanentAdminEmail = String.fromEnvironment(
    'PERMANENT_ADMIN_EMAIL',
    defaultValue: '',
  );

  static const String adminEmail = String.fromEnvironment(
    'BETA_ADMIN_EMAIL',
    defaultValue: '',
  );

  /// 정식 출시 빌드에서 베타 관리자/free-premium 기능을 강제 차단할지 여부.
  /// 기본 true — 빌드 스크립트 실수로부터 보호.
  /// 단 `permanentAdminEmail` 은 이 플래그와 무관하게 항상 admin.
  static const bool disableInRelease = bool.fromEnvironment(
    'BETA_DISABLE_IN_RELEASE',
    defaultValue: true,
  );

  /// Build 314: 명시적 TestFlight 베타 빌드 flag.
  /// `BETA_DISABLE_IN_RELEASE=false` 와 무관하게 이 flag 만 true 면 베타
  /// 시뮬레이터 / 가짜 구매 흐름 강제 활성. dart-define 누락 위험에 대한
  /// 이중 안전망. release_to_testflight.sh 가 BETA_TESTFLIGHT_BUILD=true 도
  /// 함께 전달하므로 어느 한 path 라도 통하면 베타 모드 작동.
  static const bool isTestFlightBetaBuild = bool.fromEnvironment(
    'BETA_TESTFLIGHT_BUILD',
    defaultValue: false,
  );

  /// Build 368 (PR-CC1 P0 #5): 출시 production 빌드 명시 opt-in.
  /// release_to_appstore.sh 가 `--dart-define=PRODUCTION_BUILD=true` 주입.
  /// 이 flag 가 true 면 BETA_TESTFLIGHT_BUILD/BETA_FREE_PREMIUM/
  /// BETA_UPGRADE_SIMULATOR 모두 강제 차단 — 빌드 스크립트 실수로 dart-define
  /// 이 새어 들어가도 production 사용자 무료 Premium 우회 차단.
  /// 두 flag 충돌 시 (PRODUCTION_BUILD=true && BETA_TESTFLIGHT_BUILD=true)
  /// PRODUCTION_BUILD 가 우선.
  static const bool isProductionBuild = bool.fromEnvironment(
    'PRODUCTION_BUILD',
    defaultValue: false,
  );

  static bool get isAdminEmailConfigured =>
      permanentAdminEmail.isNotEmpty || adminEmail.isNotEmpty;

  /// 입력된 이메일이 어드민 이메일과 일치하는지 검사 (대소문자 무시).
  /// `permanentAdminEmail` 은 항상 우선 적용 (release 빌드 + disableInRelease=true
  /// 환경에서도 통과). 그 외엔 BETA_ADMIN_EMAIL 일치 여부.
  ///
  /// Build 294 (P2): release 빌드 + disableInRelease=true 면 BETA_ADMIN_EMAIL
  /// 일치 여부와 무관하게 false 반환. 빌드 스크립트 실수로 BETA_ADMIN_EMAIL 이
  /// 남아있어도 production 에서 admin 권한 부여 차단.
  static bool isAdmin(String? email) {
    if (email == null || email.isEmpty) return false;
    final lower = email.toLowerCase();
    // permanentAdminEmail 은 모든 빌드에서 항상 admin 으로 인정.
    if (permanentAdminEmail.isNotEmpty &&
        lower == permanentAdminEmail.toLowerCase()) {
      return true;
    }
    // BETA_ADMIN_EMAIL 은 release + disableInRelease 일 땐 절대 인정 안 함.
    if (disableInRelease && kReleaseMode) return false;
    if (adminEmail.isEmpty) return false;
    return lower == adminEmail.toLowerCase();
  }
}
