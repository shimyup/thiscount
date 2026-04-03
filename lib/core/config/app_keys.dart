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
  /// 자동으로 브랜드 계정으로 승급시킬 테스트 이메일
  static const String testBrandEmail = 'shimyup@gmail.com';
}
