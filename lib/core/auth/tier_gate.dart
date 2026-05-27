import '../../models/user_profile.dart';
import '../services/purchase_service.dart';

/// Build 403 (PR-LL5): tier-based 기능 잠금/노출 단일 진입점.
///
/// 배경: 코드베이스 15+ 화면에 `_currentUser.isPremium / purchase.isBrand`
/// 등이 흩어져 있어 동일 정보가 3+ source 로 분산. tier 정책 변경 시 모든
/// callsite 일일이 찾아 수정해야 했다. 이 enum-driven gate 로 통합한다.
///
/// 사용 예:
/// ```dart
/// if (TierGate.canUse(Feature.exactLocationPicker, user: user, purchase: purchase)) {
///   // 정확한 위치 모달 진입
/// } else {
///   // hide (LL1) 또는 paywall (LL3)
/// }
/// ```
///
/// "hide vs lock" 정책 (LL1):
/// - [Feature.bulkSend], [Feature.exactLocationPicker], [Feature.autoZone],
///   [Feature.brandAnalytics]: **Brand only** — 비-Brand 사용자에게서 hide.
/// - [Feature.expressDelivery], [Feature.unlimitedStorage],
///   [Feature.socialLinkAttach], [Feature.imageAttach]: **Premium+ unlock** —
///   비-Premium 사용자에게 lock + paywall.
/// - [Feature.basicPickup], [Feature.basicCompose]: **모든 tier** — 항상 노출.
enum Feature {
  // ── 모든 tier (always visible) ─────────────────────────────────────
  basicPickup,
  basicCompose,
  basicInbox,

  // ── Premium+ unlock (lock + paywall) ───────────────────────────────
  expressDelivery,
  unlimitedStorage,
  socialLinkAttach,
  imageAttach,

  // ── Brand only (hide for non-Brand) ────────────────────────────────
  bulkSend,
  exactLocationPicker,
  autoZone,
  brandAnalytics,
  brandZoneCreate,
}

/// 단일 tier 분기 entry point. callsite 는 [canUse] / [shouldHide] /
/// [requiresPaywall] 셋 중 하나만 호출.
class TierGate {
  TierGate._();

  /// 사용자가 해당 기능을 실제로 사용 가능한가 (lock 풀린 상태).
  static bool canUse(
    Feature feature, {
    required UserProfile user,
    required PurchaseService purchase,
  }) {
    final isPremium = user.isPremium || purchase.isPremium;
    final isBrand = user.isBrand || purchase.isBrand;
    switch (feature) {
      case Feature.basicPickup:
      case Feature.basicCompose:
      case Feature.basicInbox:
        return true;
      case Feature.expressDelivery:
      case Feature.unlimitedStorage:
      case Feature.socialLinkAttach:
      case Feature.imageAttach:
        return isPremium || isBrand;
      case Feature.bulkSend:
      case Feature.exactLocationPicker:
      case Feature.autoZone:
      case Feature.brandAnalytics:
      case Feature.brandZoneCreate:
        return isBrand;
    }
  }

  /// UI 에서 해당 기능을 완전히 hide 해야 하는가 (Brand-only 기능을
  /// 비-Brand 가 보면 paywall conversion 0% + 인지 부담만 증가).
  static bool shouldHide(
    Feature feature, {
    required UserProfile user,
    required PurchaseService purchase,
  }) {
    final isBrand = user.isBrand || purchase.isBrand;
    switch (feature) {
      case Feature.bulkSend:
      case Feature.exactLocationPicker:
      case Feature.autoZone:
      case Feature.brandAnalytics:
      case Feature.brandZoneCreate:
        return !isBrand;
      default:
        return false; // Premium+ / 모든 tier 기능은 hide 안 함 (lock 으로 노출)
    }
  }

  /// 해당 기능 탭 시 paywall (PremiumGateSheet) 띄워야 하는가.
  /// `canUse=false` 이면서 `shouldHide=false` → 잠금 + paywall.
  static bool requiresPaywall(
    Feature feature, {
    required UserProfile user,
    required PurchaseService purchase,
  }) {
    if (canUse(feature, user: user, purchase: purchase)) return false;
    if (shouldHide(feature, user: user, purchase: purchase)) return false;
    return true;
  }

  /// 사용자 현재 tier 를 일관된 enum 으로 반환 (분기 코드에서 사용).
  ///
  /// 순서: Brand > Premium > Free.
  static TierLevel currentTier({
    required UserProfile user,
    required PurchaseService purchase,
  }) {
    if (user.isBrand || purchase.isBrand) return TierLevel.brand;
    if (user.isPremium || purchase.isPremium) return TierLevel.premium;
    return TierLevel.free;
  }
}

enum TierLevel { free, premium, brand }
