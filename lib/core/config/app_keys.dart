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
abstract class BetaConstants {
  static const String adminEmail = String.fromEnvironment(
    'BETA_ADMIN_EMAIL',
    defaultValue: '',
  );

  static bool get isAdminEmailConfigured => adminEmail.isNotEmpty;

  /// 입력된 이메일이 베타 관리자 이메일과 일치하는지 검사.
  /// 대소문자 무시. BETA_ADMIN_EMAIL 이 비어 있으면 항상 false.
  static bool isAdmin(String? email) {
    if (!isAdminEmailConfigured) return false;
    if (email == null || email.isEmpty) return false;
    return email.toLowerCase() == adminEmail.toLowerCase();
  }
}
