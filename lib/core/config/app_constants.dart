// Build 391 (PR-GG4 audit B9): 분산된 magic number 중앙 집중.
//
// 이전엔 _pickupRadiusMeters / _inboxMaxSize / _dailyLimit* / _level50Threshold
// 등이 AppState / various widget 에 흩어져 정의 — 변경 시 grep 추적 필요 +
// 동일 의미 (예: pickup 반경) 가 두 곳에 다른 값으로 분기 위험.
//
// 사용:
//   import 'package:thiscount/core/config/app_constants.dart';
//   final r = AppConstants.pickupRadiusMeters;
//
// 마이그레이션 정책:
//   - 신규 코드는 무조건 AppConstants 사용
//   - 기존 const 는 점진 교체 (PR scope 비대 방지)
//   - 비즈니스 의미 변경 시 (예: 일일 한도 조정) 한 곳만 update

abstract class AppConstants {
  // ── 픽업 / 위치 ─────────────────────────────────────────────────────────
  /// 일반 letter 픽업 반경 (m). 자동 픽업/거리 검증 양쪽 사용.
  static const int pickupRadiusMeters = 200;

  /// Brand letter 픽업 반경 (m) — 일반보다 넓음 (brand 의도된 customer base).
  static const int pickupRadiusBrandMeters = 1000;

  /// 인박스 in-memory cap (이상 시 FIFO trim).
  static const int inboxMaxSize = 500;

  /// `_pickedUpCampaignIds` in-memory cap.
  static const int pickedCampaignIdsCap = 5000;

  // ── 발송 한도 (per day) ─────────────────────────────────────────────────
  static const int dailyLimitFree = 3;
  static const int dailyLimitPremium = 30;
  static const int dailyLimitBrand = 200;

  /// Brand extra quota 1회 구매 추가량.
  static const int brandExtraQuotaPerPurchase = 1000;

  /// Premium 이미지 letter 일일 한도.
  static const int dailyImageLimitPremium = 20;

  /// Premium DM (express) 일일 한도.
  static const int dailyExpressLimitPremium = 5;

  // ── 레벨 / XP ───────────────────────────────────────────────────────────
  /// 레벨 50 도달 XP 임계값. 이후 1 XP / point 단순 가산.
  static const int level50Threshold = 120050;

  /// XP per level point (50+ 구간).
  static const int xpPerPoint = 100;

  // ── 보안 / 만료 ──────────────────────────────────────────────────────────
  /// SecureClipboard 기본 TTL.
  static const Duration secureClipboardTtl = Duration(seconds: 45);

  /// Admin 화면 idle timeout (PR-GG1).
  static const Duration adminIdleTimeout = Duration(minutes: 10);

  /// Redemption pending TTL (코드 reveal 후 자동 markRedeemed).
  static const Duration pendingRedemptionTtl = Duration(hours: 1);

  /// startRedemption race lock stale TTL.
  static const Duration redemptionLockStaleTtl = Duration(minutes: 5);

  /// Login brute-force lockout (5회 실패 후).
  static const int loginMaxAttempts = 5;
  static const Duration loginLockoutDuration = Duration(minutes: 15);

  // ── Trial ───────────────────────────────────────────────────────────────
  /// Welcome trial 일수 (Build 271: 7→3).
  static const int welcomeTrialDays = 3;

  /// Premium gift card 부여 일수.
  static const int premiumGiftDays = 30;

  // ── BrandZone ───────────────────────────────────────────────────────────
  /// Zone radius 최소/최대 (m). Firestore rule 검증과 일치.
  static const double brandZoneRadiusMinMeters = 50.0;
  static const double brandZoneRadiusMaxMeters = 5000.0;

  /// Zone 활성 일수 cap (PR-CC5).
  static const int brandZoneMaxDurationDays = 90;

  /// Zone trigger letter destination offset (random ± m).
  static const double brandZoneDestinationOffsetMeters = 30.0;

  /// Brand zone cache TTL.
  static const Duration brandZoneCacheTtl = Duration(minutes: 5);

  // ── Delivery / sync ─────────────────────────────────────────────────────
  /// _runDeliveryTick 주기.
  static const Duration deliveryTickInterval = Duration(seconds: 30);

  /// Map 사용자 list fetch cooldown.
  static const Duration mapUsersFetchCooldown = Duration(minutes: 15);

  /// Firestore HTTP 기본 timeout.
  static const Duration firestoreHttpTimeout = Duration(seconds: 8);

  /// Firestore retry max attempts (PR-X1).
  static const int firestoreRetryMaxAttempts = 3;
}
