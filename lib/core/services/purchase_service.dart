import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/app_state.dart';
import '../config/app_keys.dart';
import 'secure_clock.dart';

enum ScheduledPlanTarget { free, brand }

enum PurchaseOperation {
  premium,
  brand,
  giftCard,
  brandExtra,
  // Build 324: ExactDrop 100통 패키지 IAP — 이전 "관리자에게 문의" 흐름 제거.
  exactDrop100,
  // Build 325 (T4): 50통 / 500통 가격 티어 추가 — 시범 운영 vs 정착 사장 양극화
  //   대응. 50 = ₩6,000 / 500 = ₩40,000 (100통 대비 unit 가 각 +20% / -20%).
  exactDrop50,
  exactDrop500,
  restore,
}

// ── RevenueCat API Keys ─────────────────────────────────────────────────────
// 빌드 시 dart-define 으로 주입:
//   flutter run \
//     --dart-define=REVENUECAT_IOS_KEY=appl_xxxx \
//     --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxx
//
class _RcKeys {
  static const String ios = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const String android = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );
}

// ── RevenueCat Entitlement IDs ──────────────────────────────────────────────
// RevenueCat 대시보드 → Entitlements 에서 동일하게 생성 필요
class _RcEntitlements {
  static const String premium = 'premium'; // Premium 구독
  static const String brand = 'brand'; // Brand / Creator 구독
}

// ── 상품 ID (App Store Connect / Play Console 에 동일하게 등록 필요) ──────────
class PurchaseProductIds {
  // Legacy (초기 콘솔 설정)
  static const String _premiumMonthlyLegacy = 'letter_go_premium_monthly';
  static const String _brandMonthlyLegacy = 'letter_go_brand_monthly';
  static const String _giftCardLegacy = 'letter_go_gift_1month';
  static const String _brandExtra1000Legacy = 'letter_go_brand_extra_1000';
  // Build 324: ExactDrop 100통 패키지 (₩10,000) — Legacy 형태 ID.
  static const String _exactDrop100Legacy = 'letter_go_exact_drop_100';
  // Build 325 (T4): 50통 (₩6,000) / 500통 (₩40,000) 가격 티어.
  static const String _exactDrop50Legacy = 'letter_go_exact_drop_50';
  static const String _exactDrop500Legacy = 'letter_go_exact_drop_500';
  // Build 429 (device): 1000통 대용량 티어 (₩10,000) — 기존 100통 슬롯 대체.
  //   🔴 ASC 등록 필요: thiscount_exact_drop_1000_ios (소모성, ₩10,000).
  static const String _exactDrop1000Legacy = 'letter_go_exact_drop_1000';

  // iOS (App Store Connect)
  static const String _premiumMonthlyIos = 'thiscount_premium_monthly_ios';
  static const String _brandMonthlyIos = 'thiscount_brand_monthly_ios';
  static const String _giftCardIos = 'thiscount_gift_1month_ios';
  static const String _brandExtra1000Ios = 'thiscount_brand_extra_1000_ios';
  static const String _exactDrop100Ios = 'thiscount_exact_drop_100_ios';
  static const String _exactDrop50Ios = 'thiscount_exact_drop_50_ios';
  static const String _exactDrop500Ios = 'thiscount_exact_drop_500_ios';
  static const String _exactDrop1000Ios = 'thiscount_exact_drop_1000_ios';

  // Android (Google Play Billing / RevenueCat import 결과)
  static const String _premiumMonthlyAndroid =
      'letter_go_premium_monthly:monthly';
  static const String _brandMonthlyAndroid = 'letter_go_brand_monthly:monthly';
  static const String _giftCardAndroid = _giftCardLegacy;
  static const String _brandExtra1000Android = _brandExtra1000Legacy;
  static const String _exactDrop100Android = _exactDrop100Legacy;
  static const String _exactDrop50Android = _exactDrop50Legacy;
  static const String _exactDrop500Android = _exactDrop500Legacy;
  static const String _exactDrop1000Android = _exactDrop1000Legacy;

  static String _forPlatform({
    required String ios,
    required String android,
    required String fallback,
  }) {
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    return fallback;
  }

  static List<String> _orderedUnique(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      if (seen.add(value)) result.add(value);
    }
    return result;
  }

  static String get premiumMonthly => _forPlatform(
    ios: _premiumMonthlyIos,
    android: _premiumMonthlyAndroid,
    fallback: _premiumMonthlyLegacy,
  );
  static String get brandMonthly => _forPlatform(
    ios: _brandMonthlyIos,
    android: _brandMonthlyAndroid,
    fallback: _brandMonthlyLegacy,
  );
  static String get giftCard => _forPlatform(
    ios: _giftCardIos,
    android: _giftCardAndroid,
    fallback: _giftCardLegacy,
  );
  static String get brandExtra1000 => _forPlatform(
    ios: _brandExtra1000Ios,
    android: _brandExtra1000Android,
    fallback: _brandExtra1000Legacy,
  );
  static String get exactDrop100 => _forPlatform(
    ios: _exactDrop100Ios,
    android: _exactDrop100Android,
    fallback: _exactDrop100Legacy,
  );
  static String get exactDrop50 => _forPlatform(
    ios: _exactDrop50Ios,
    android: _exactDrop50Android,
    fallback: _exactDrop50Legacy,
  );
  static String get exactDrop500 => _forPlatform(
    ios: _exactDrop500Ios,
    android: _exactDrop500Android,
    fallback: _exactDrop500Legacy,
  );
  static String get exactDrop1000 => _forPlatform(
    ios: _exactDrop1000Ios,
    android: _exactDrop1000Android,
    fallback: _exactDrop1000Legacy,
  );

  static List<String> premiumMonthlyCandidates() => _orderedUnique([
    premiumMonthly,
    _premiumMonthlyIos,
    _premiumMonthlyAndroid,
    _premiumMonthlyLegacy,
  ]);

  static List<String> brandMonthlyCandidates() => _orderedUnique([
    brandMonthly,
    _brandMonthlyIos,
    _brandMonthlyAndroid,
    _brandMonthlyLegacy,
  ]);

  static List<String> giftCardCandidates() => _orderedUnique([
    giftCard,
    _giftCardIos,
    _giftCardAndroid,
    _giftCardLegacy,
  ]);

  static List<String> brandExtra1000Candidates() => _orderedUnique([
    brandExtra1000,
    _brandExtra1000Ios,
    _brandExtra1000Android,
    _brandExtra1000Legacy,
  ]);

  static List<String> exactDrop100Candidates() => _orderedUnique([
    exactDrop100,
    _exactDrop100Ios,
    _exactDrop100Android,
    _exactDrop100Legacy,
  ]);
  static List<String> exactDrop50Candidates() => _orderedUnique([
    exactDrop50,
    _exactDrop50Ios,
    _exactDrop50Android,
    _exactDrop50Legacy,
  ]);
  static List<String> exactDrop500Candidates() => _orderedUnique([
    exactDrop500,
    _exactDrop500Ios,
    _exactDrop500Android,
    _exactDrop500Legacy,
  ]);
  static List<String> exactDrop1000Candidates() => _orderedUnique([
    exactDrop1000,
    _exactDrop1000Ios,
    _exactDrop1000Android,
    _exactDrop1000Legacy,
  ]);

  /// Build 325/429: 패키지 수량별 candidates (50 / 500 / 1000, 기본 100).
  static List<String> exactDropCandidates(int qty) {
    if (qty == 50) return exactDrop50Candidates();
    if (qty == 500) return exactDrop500Candidates();
    if (qty == 1000) return exactDrop1000Candidates();
    return exactDrop100Candidates();
  }

  /// Build 325/429: 로그/에러 메시지용 대표 ID.
  static String exactDropProductId(int qty) {
    if (qty == 50) return exactDrop50;
    if (qty == 500) return exactDrop500;
    if (qty == 1000) return exactDrop1000;
    return exactDrop100;
  }
}

// ── RevenueCat Offering/Package 식별자 ─────────────────────────────────────
class _RcOfferings {
  static const String defaultOffering = 'default';
}

/// UI 표시용 상품 정보
class ProductInfo {
  final String id;
  final String title;
  final String price; // 로컬 통화 가격 문자열 (RevenueCat에서 로드되면 업데이트)
  final String description;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
  });
}

// ── 구매 서비스 (RevenueCat 기반) ───────────────────────────────────────────
class PurchaseService extends ChangeNotifier with WidgetsBindingObserver {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._() {
    // Build 299 (MED audit): trial 만료를 foreground 복귀 시점에도 재평가.
    // _loadFromPrefs 가 cold-start 에서만 호출되어 사용자가 day 3 경계를
    // foreground 로 넘기면 Premium 이 풀리지 않던 회귀 차단.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // fire-and-forget — 결과는 notifyListeners 로 UI 전파.
      reevaluateTrialExpiry();
      // Build 302 (MED audit): RC customerInfo 도 refresh — 환불/외부 취소가
      // RC 서버에서 발생해도 사용자가 백그라운드 → 포어그라운드 복귀 시
      // 즉시 entitlement 동기화. 이전엔 cold-start 까지 stale Premium 유지.
      _refreshCustomerInfoIfReady();
    }
  }

  Future<void> _refreshCustomerInfoIfReady() async {
    if (_isTestMode || _isBetaFreePremium || _isBetaUpgradeSimulator) return;
    if (!_isRcKeyConfiguredForCurrentPlatform) return;
    try {
      final info = await Purchases.getCustomerInfo();
      // Build 414 (sim100 #37): _applyCustomerInfo 단독은 notifyListeners/
      //   schedule 재적용을 안 해, 포어그라운드 복귀 시 환불·외부취소가
      //   반영돼도 UI 가 stale Premium 을 유지했다. 정식 콜백 경로로 통일.
      _onCustomerInfoUpdated(info);
    } catch (_) {
      // 무시 — 다음 resumed 또는 cold-start 에 다시 시도.
    }
  }

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _isBrand = false;
  bool get isBrand => _isBrand;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _initialized = false;

  /// Build 215: 화면 진입 시 stale errorMessage 클리어용 public API.
  /// 이전 buy 시도가 실패했더라도 다시 들어오면 깨끗한 상태로.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void>? _initializationFuture;
  bool _isRevenueCatConfigured = false;
  bool _customerInfoListenerAttached = false;
  String? _activeAppUserId;
  SharedPreferences? _prefs; // 캐시 — getInstance() 반복 호출 방지
  PurchaseOperation? _activeOperation;
  String _preferredLanguageCode = '';

  PurchaseOperation? get activeOperation => _activeOperation;
  bool isOperationInProgress(PurchaseOperation operation) =>
      _loading && _activeOperation == operation;

  void setPreferredLanguageCode(String? languageCode) {
    final normalized = (languageCode ?? '').trim().toLowerCase();
    if (_preferredLanguageCode == normalized) return;
    _preferredLanguageCode = normalized;
  }

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // 베타 빌드에서 Premium을 부여했는지 여부를 표시하는 마커.
  // 마커가 '1' 인데 현재 빌드에 BETA_FREE_PREMIUM 이 꺼져 있으면
  // → "베타로 받은 무료 Premium" 이므로 정식 빌드에서는 무효 처리해야 함.
  static const String _kBetaGrantedKey = 'ps_beta_granted';

  Future<void> _saveSecurePremiumState({
    required bool isPremium,
    required bool isBrand,
  }) async {
    await _secure.write(key: 'ps_isPremium', value: isPremium ? '1' : '0');
    await _secure.write(key: 'ps_isBrand', value: isBrand ? '1' : '0');
    // Premium 을 부여할 때만 베타 플래그 상태를 마킹. 해제 시에는 마커 유지
    // 하여 "예전에 베타로 받았음" 기록을 남김 → 뒤에 정식 빌드에서 청소.
    if (isPremium && _isBetaFreePremium) {
      await _secure.write(key: _kBetaGrantedKey, value: '1');
    }
  }

  Future<void> _loadSecurePremiumState() async {
    _isPremium = (await _secure.read(key: 'ps_isPremium')) == '1';
    _isBrand = (await _secure.read(key: 'ps_isBrand')) == '1';

    // ── 베타→정식 전환 안전장치 ───────────────────────────────────────────
    // 이전에 BETA_FREE_PREMIUM 로 받은 Premium 이 정식 빌드까지 유지되는
    // 것을 방지. 현재 빌드가 BETA 가 아닌데 과거에 베타 마커가 찍혀 있으면
    // 로컬 상태를 전부 무효화하고 RevenueCat 재검증을 유도.
    final betaGranted = (await _secure.read(key: _kBetaGrantedKey)) == '1';
    if (betaGranted && !_isBetaFreePremium) {
      _isPremium = false;
      _isBrand = false;
      await _secure.delete(key: 'ps_isPremium');
      await _secure.delete(key: 'ps_isBrand');
      await _secure.delete(key: _kBetaGrantedKey);
      if (kDebugMode) {
        debugPrint(
          '[PurchaseService] beta-granted premium cleared on non-beta build',
        );
      }
    }
  }

  Future<void> _clearSecurePremiumState() async {
    await _secure.delete(key: 'ps_isPremium');
    await _secure.delete(key: 'ps_isBrand');
    await _secure.delete(key: _kBetaGrantedKey);
  }

  /// Build 307: 로그아웃 시 즉시 호출. secure storage 삭제 + 메모리 필드
  /// 동시 reset → 다음 사용자가 같은 디바이스로 로그인했을 때 이전 사용자의
  /// Premium 상태가 잠시라도 노출되지 않도록. RevenueCat sync 가 늦어도 UI
  /// 는 안전한 default 부터 시작.
  Future<void> resetForLogout() async {
    _isPremium = false;
    _isBrand = false;
    _trialExpiry = null;
    _scheduledPlanChangeDate = null;
    _scheduledPlanTarget = null;
    await _clearSecurePremiumState();
    notifyListeners();
  }

  // 플랜 변경 예약 (다음 결제일부터 반영)
  DateTime? _scheduledPlanChangeDate;
  ScheduledPlanTarget? _scheduledPlanTarget;
  DateTime? get scheduledPlanChangeDate => _scheduledPlanChangeDate;
  ScheduledPlanTarget? get scheduledPlanTarget => _scheduledPlanTarget;

  // Build 409 (sim P1.17): 예약 다운그레이드 발효 시 1회 set 되는 '확정 강등'
  //   플래그. AppState 리스너가 consume 해서 authoritative sync (OR-fallback
  //   우회) 를 트리거. 일회성이라 신규 Brand 가입의 transient false 와 구분.
  bool _pendingAuthoritativeDowngrade = false;
  bool consumePendingAuthoritativeDowngrade() {
    if (!_pendingAuthoritativeDowngrade) return false;
    _pendingAuthoritativeDowngrade = false;
    return true;
  }
  bool get isPendingPlanChange =>
      _scheduledPlanChangeDate != null && _scheduledPlanTarget != null;
  bool get isPendingDowngrade =>
      isPendingPlanChange && _scheduledPlanTarget == ScheduledPlanTarget.free;
  DateTime? get scheduledDowngradeDate =>
      _scheduledPlanTarget == ScheduledPlanTarget.free
      ? _scheduledPlanChangeDate
      : null;

  // RevenueCat Offering (실제 가격 포함)
  Offerings? _offerings;
  final Map<String, StoreProduct> _storeProductsById = {};
  DateTime? _nextBillingDate;
  DateTime? get nextBillingDate => _nextBillingDate;

  // Build 271: trial 만료 시각 — grantWelcomeTrial 시 설정. UI 노출용.
  DateTime? _trialExpiry;
  DateTime? get trialExpiry => _trialExpiry;
  // Build 304: SecureClock.now() 로 시계 되돌리기 우회 차단. 사용자가
  // 디바이스 시각을 과거로 되돌려도 trial 이 영원히 활성화되지 않는다.
  bool get isTrialActive =>
      _trialExpiry != null && SecureClock.now().isBefore(_trialExpiry!);
  int get trialHoursRemaining {
    if (_trialExpiry == null) return 0;
    final diff = _trialExpiry!.difference(SecureClock.now());
    return diff.isNegative ? 0 : diff.inHours;
  }

  // UI 표시용 기본 상품 목록 (Offering 로드 전 fallback)
  List<ProductInfo> get products => [
    ProductInfo(
      id: PurchaseProductIds.premiumMonthly,
      title: 'Premium',
      price: '₩4,900',
      // Build 426: Premium 발송 제거 → 줍기 부스터·DM·커스터마이즈로 정정.
      description: '줍기 반경 1km · 쿨다운 없음 · 1:1 채팅(DM) · 타워 커스텀',
    ),
    ProductInfo(
      id: PurchaseProductIds.brandMonthly,
      title: 'Brand / Creator',
      price: '₩99,000',
      description: '인증 배지 · 월 10,000통 · 대량 발송 · Premium 포함',
    ),
    ProductInfo(
      id: PurchaseProductIds.giftCard,
      title: '1개월 선물권',
      price: '₩3,900',
      description: '친구에게 1개월 프리미엄 선물',
    ),
  ];

  // ── 테스트 모드 여부 (디버그 전용) ────────────────────────────────────────
  /// UI에서 테스트 모드 여부를 확인할 때 사용
  bool get isTestMode => _isTestMode;
  static const bool _allowRealPurchasesInDebug = bool.fromEnvironment(
    'RC_REAL_PURCHASES_IN_DEBUG',
    defaultValue: false,
  );

  static bool get _isTestMode {
    if (!kDebugMode) return false;
    if (_allowRealPurchasesInDebug) return false;
    return true;
  }

  // ── 베타 무료 프리미엄 모드 (TestFlight / 내부 테스트용) ──────────────────
  // 빌드 시 --dart-define=BETA_FREE_PREMIUM=true 로 활성화.
  // 릴리스 빌드에서도 Premium 구독을 무료로 즉시 활성화.
  // Brand 구독은 베타 기간 중 불가.
  //
  // Build 207: BETA_DISABLE_IN_RELEASE (default true) 가 켜져 있으면 릴리스
  // 빌드에서는 dart-define 으로 BETA_FREE_PREMIUM=true 를 줘도 무시. 정식 출시
  // 빌드에 베타 플래그가 새어 들어가는 사고를 차단.
  static const bool _isBetaFreePremiumRaw = bool.fromEnvironment(
    'BETA_FREE_PREMIUM',
    defaultValue: false,
  );
  static bool get _isBetaFreePremium {
    // Build 368 (PR-CC1 P0 #5): production 빌드 강제 차단 — 빌드 스크립트
    //   실수로 BETA_TESTFLIGHT_BUILD/BETA_FREE_PREMIUM 가 새어 들어가도
    //   PRODUCTION_BUILD=true 면 어떤 beta flag 도 무력화.
    if (BetaConstants.isProductionBuild) return false;
    // Build 319 (단순화): BETA_TESTFLIGHT_BUILD=true 면 무조건 활성.
    // BETA_FREE_PREMIUM dart-define 은 deprecate — TestFlight flag 만 사용.
    if (BetaConstants.isTestFlightBetaBuild) return true;
    if (BetaConstants.disableInRelease && kReleaseMode) return false;
    return _isBetaFreePremiumRaw;
  }

  /// UI에서 베타 무료 프리미엄 모드 여부를 확인할 때 사용
  bool get isBetaFreePremium => _isBetaFreePremium;

  // ── 베타 업그레이드 시뮬레이터 (TestFlight/베타 전용) ────────────────────────
  // RevenueCat 상품이 App Store Connect 에 아직 미등록 / 미승인 상태에서도
  // 베타 테스터가 업그레이드 흐름을 끝까지 체험할 수 있도록 가짜 구매로 처리.
  // 빌드 시 --dart-define=BETA_UPGRADE_SIMULATOR=true 로 활성화.
  // Build 273 hardening: release + BETA_DISABLE_IN_RELEASE=true 이면
  // 실수로 dart-define 이 남아 있어도 자동으로 비활성화.
  static const bool _isBetaUpgradeSimulatorRaw = bool.fromEnvironment(
    'BETA_UPGRADE_SIMULATOR',
    defaultValue: false,
  );

  static bool get _isBetaUpgradeSimulator {
    // Build 368 (PR-CC1 P0 #5): production 빌드 강제 차단.
    if (BetaConstants.isProductionBuild) return false;
    // Build 319 (단순화): BETA_TESTFLIGHT_BUILD=true 면 무조건 활성.
    // 가짜 결제 흐름은 TestFlight 베타 빌드에서 항상 동작 (ASC IAP 미등록 대비).
    if (BetaConstants.isTestFlightBetaBuild) return true;
    if (BetaConstants.disableInRelease && kReleaseMode) return false;
    return _isBetaUpgradeSimulatorRaw;
  }

  /// UI 에서 베타 시뮬레이터 모드 노출용.
  bool get isBetaUpgradeSimulator => _isBetaUpgradeSimulator;

  static bool get _isRcKeyConfiguredForCurrentPlatform {
    final iosReady = _isValidRevenueCatKey(_RcKeys.ios, isAndroid: false);
    final androidReady = _isValidRevenueCatKey(
      _RcKeys.android,
      isAndroid: true,
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosReady;
    if (defaultTargetPlatform == TargetPlatform.android) return androidReady;
    return false;
  }

  static bool _isValidRevenueCatKey(String rawKey, {required bool isAndroid}) {
    final key = rawKey.trim();
    if (key.isEmpty) return false;

    final expectedPrefix = isAndroid ? 'goog_' : 'appl_';
    if (!key.startsWith(expectedPrefix)) return false;

    final suffix = key.substring(expectedPrefix.length);
    if (suffix.length < 12) return false;

    final normalized = suffix.toLowerCase();
    // .env.example의 placeholder(appl_xxxxx..., goog_xxxxx...) 방지
    if (RegExp(r'^x+$').hasMatch(normalized)) return false;
    if (normalized.contains('placeholder') || normalized.contains('your_')) {
      return false;
    }
    return true;
  }

  // ── 초기화 ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 디버그 빌드에서는 SharedPreferences 폴백 (개발/테스트용)
    if (_isTestMode) {
      await _initFromPrefs();
      return;
    }

    // 베타 무료 프리미엄 모드: RevenueCat 완전 우회, 로컬 상태만 사용
    if (_isBetaFreePremium) {
      await _initFromPrefs();
      return;
    }

    if (!_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return;
    }

    try {
      await _ensureRevenueCatConfigured();
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] RC 초기화 실패: $e');
      await _initFromPrefs(); // 폴백
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] RC 초기화 실패(unknown): $e');
      await _initFromPrefs(); // 폴백
    }
  }

  Future<bool> _ensureRevenueCatConfigured() async {
    if (_isTestMode) return true;
    if (_isRevenueCatConfigured) return true;
    if (!_isRcKeyConfiguredForCurrentPlatform) return false;

    if (_initializationFuture != null) {
      await _initializationFuture!;
      return _isRevenueCatConfigured;
    }

    _initializationFuture = _configureRevenueCatInternal();
    try {
      await _initializationFuture!;
    } finally {
      _initializationFuture = null;
    }

    return _isRevenueCatConfigured;
  }

  Future<void> _configureRevenueCatInternal() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    final config = PurchasesConfiguration(
      defaultTargetPlatform == TargetPlatform.android
          ? _RcKeys.android
          : _RcKeys.ios,
    );
    try {
      await Purchases.configure(config);
    } on PlatformException catch (e) {
      final msg = (e.message ?? '').toLowerCase();
      if (!msg.contains('already configured')) rethrow;
    }

    if (!_customerInfoListenerAttached) {
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      _customerInfoListenerAttached = true;
    }

    final info = await Purchases.getCustomerInfo();
    _applyCustomerInfo(info);
    await _persistBillingDateToPrefs();
    final prefs = await _getPrefs();
    // Build 441 (sim100 P1): production cold-start 는 _applyCustomerInfo(RC
    //   entitlement 기반)만 타서 로컬 grant trial(gift)을 _isPremium=false 로
    //   덮고 secure 까지 오염 → trial 이 1세션만 동작하던 회귀(베타 경로는
    //   _initFromPrefs 가 giftExpiry 평가해 정상이라 베타 QA 에서 미검출).
    //   여기서 giftExpiry 를 평가해 미만료 trial 이면 Premium OR-병합 + secure
    //   복구. 매 cold-start 복원이라 _applyCustomerInfo 의 secure(false) write 와
    //   race 가 나도 다음 cold-start 에서 self-heal.
    await _evaluateGiftExpiryFromPrefs(prefs);
    if (_trialExpiry != null && !_isBrand && !_isPremium) {
      _isPremium = true;
      await _saveSecurePremiumState(isPremium: true, isBrand: _isBrand);
    }
    await _loadAndApplyScheduledPlanChange(prefs);

    try {
      _offerings = await Purchases.getOfferings();
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] Offering 로드 실패: $e');
    }
    _isRevenueCatConfigured = true;
  }

  // Build 285: premium_screen 진입 시 호출 — offerings 가 null 이거나 stale
  // 일 때 즉시 refresh. 사용자가 plan 변경하려고 화면 열면 항상 최신 상품
  // 정보를 보여주기 위함.
  Future<bool> refreshOfferings() async {
    if (_isTestMode || _isBetaFreePremium || _isBetaUpgradeSimulator) {
      return true;
    }
    if (!_isRcKeyConfiguredForCurrentPlatform) return false;
    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) return false;
      _offerings = await Purchases.getOfferings();
      notifyListeners();
      return true;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] offering refresh 실패: $e');
      return false;
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _applyCustomerInfo(info);
    unawaited(_persistBillingDateToPrefs());
    // 예약된 플랜 변경이 효력 발생일을 지났으면 로컬 상태를 재적용
    // (RevenueCat entitlement가 아직 활성 상태여도 로컬 다운그레이드 우선)
    _reapplyScheduledPlanChangeIfDue();
    notifyListeners();
  }

  void _reapplyScheduledPlanChangeIfDue() {
    if (_scheduledPlanChangeDate == null || _scheduledPlanTarget == null)
      return;
    // Build 306: SecureClock — 시계 되돌리기로 plan downgrade 우회 차단.
    if (!SecureClock.now().isAfter(_scheduledPlanChangeDate!)) return;

    if (_scheduledPlanTarget == ScheduledPlanTarget.free) {
      _isPremium = false;
      _isBrand = false;
      // Build 409 (sim P1.17): 예약 다운그레이드가 실제 발효된 '확정 강등'
      //   신호. AppState.syncPremiumStatus 의 OR-fallback(한 번 Brand 면 유지)을
      //   이 경우엔 우회해야 isBrand 가 실제로 꺼짐. 일회성 flag 로 표시 —
      //   transient RC notify 와 구분 (신규 Brand 가입 보존은 그대로).
      _pendingAuthoritativeDowngrade = true;
      unawaited(_saveSecurePremiumState(isPremium: false, isBrand: false));
      // Build 414 (sim100 #36): 발효된 free 다운그레이드 schedule 은 1회성 —
      //   클리어하지 않으면 이후 재구독해도 매 customerInfo 갱신마다 재적용돼
      //   Premium 이 즉시 회수된다(결제 후 무권한). brand 분기와 동일하게 정리.
      _scheduledPlanChangeDate = null;
      _scheduledPlanTarget = null;
      unawaited(() async {
        final prefs = await _getPrefs();
        await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
        await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
      }());
    }
    // Build 368 (PR-CC1 P0 #1): scheduled Brand 자동 flip 제거.
    //   이전엔 schedule date 도달만으로 _isBrand=true → 사용자가 ₩99,000 IAP
    //   없이 Brand 권한 부여되던 critical 회귀. Brand 전환은 반드시 RC IAP 를
    //   통해서만 — buyBrand() / _applyCustomerInfo(entitlement) 경로만 허용.
    //   schedule.brand 호출 자체는 noop (deprecate). UI 호출처 (premium_screen
    //   2922) 도 buyBrand 로 교체.
    // 만약 _scheduledPlanTarget == brand 인 잔존 schedule 이 있으면 clear.
    if (_scheduledPlanTarget == ScheduledPlanTarget.brand) {
      _scheduledPlanTarget = null;
      _scheduledPlanChangeDate = null;
      unawaited(() async {
        final prefs = await _getPrefs();
        await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
        await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
      }());
    }
  }

  void _applyCustomerInfo(CustomerInfo info) {
    _isBrand = info.entitlements.active.containsKey(_RcEntitlements.brand);
    _isPremium =
        _isBrand ||
        info.entitlements.active.containsKey(_RcEntitlements.premium);
    _nextBillingDate = _parseRevenueCatDate(info.latestExpirationDate);
    // Build 309: 결제/복원/환불 등 모든 entitlement 변화를 secure storage 에
    // 즉시 persist. 이전엔 호출처가 명시적으로 _saveSecurePremiumState 를
    // 불러야 했고 5+ 호출처 중 일부 누락 → 강제 종료 / crash 시 다음 cold-start
    // 에 stale secure state 로딩 → Premium 사용자가 잠시 Free 로 보이는 회귀.
    // fire-and-forget — UI 차단 안 함.
    unawaited(_saveSecurePremiumState(isPremium: _isPremium, isBrand: _isBrand));
  }

  DateTime? _parseRevenueCatDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> _persistBillingDateToPrefs() async {
    final prefs = await _getPrefs();
    final date = _nextBillingDate;
    if (date == null) {
      await prefs.remove(PrefKeys.purchaseNextBillingDate);
      return;
    }
    await prefs.setInt(
      PrefKeys.purchaseNextBillingDate,
      date.millisecondsSinceEpoch,
    );
  }

  // SharedPreferences 폴백 (RevenueCat 미연동 시)
  Future<void> _initFromPrefs() async {
    final prefs = await _getPrefs();
    await _loadSecurePremiumState();
    // SharedPrefs에 기존 값이 있으면 마이그레이션 후 삭제
    final legacyPremium = prefs.getBool(PrefKeys.purchaseIsPremium);
    final legacyBrand = prefs.getBool(PrefKeys.purchaseIsBrand);
    if (legacyPremium != null || legacyBrand != null) {
      _isPremium = legacyPremium ?? _isPremium;
      _isBrand = legacyBrand ?? _isBrand;
      await _saveSecurePremiumState(isPremium: _isPremium, isBrand: _isBrand);
      await prefs.remove(PrefKeys.purchaseIsPremium);
      await prefs.remove(PrefKeys.purchaseIsBrand);
    }

    await _evaluateGiftExpiryFromPrefs(prefs);

    if (_trialExpiry == null && _isPremium && !_isBrand &&
        _nextBillingDate == null) {
      // Build 290 (P0): secure storage 에 _isPremium=true 인데 giftExpiry 도
      // billingDate 도 없으면 무결성 위반 → trial 부여 시 prefs write 실패한
      // 케이스 의심. _isPremium 을 false 로 reset → 영구 무료 Premium 회귀 차단.
      // (실제 결제 사용자는 _nextBillingDate 가 있으므로 영향 없음.)
      _isPremium = false;
      await _saveSecurePremiumState(isPremium: false, isBrand: _isBrand);
    }

    _nextBillingDate = _loadDateFromPrefs(
      prefs,
      PrefKeys.purchaseNextBillingDate,
    );
    await _loadAndApplyScheduledPlanChange(prefs);
    notifyListeners();
  }

  // Build 299 (MED audit): gift trial 만료를 prefs 기반으로 평가하는 helper.
  // _loadFromPrefs 가 cold-start 에서만 호출되어 사용자가 day 3 경계를
  // foreground 로 넘기면 Premium 이 풀리지 않던 회귀를 차단하려고 분리.
  Future<void> _evaluateGiftExpiryFromPrefs(SharedPreferences prefs) async {
    final giftExpiry = prefs.getInt(PrefKeys.purchaseGiftExpiry) ?? 0;
    if (giftExpiry > 0) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(giftExpiry);
      // Build 306: SecureClock — Build 304 에서 isTrialActive 만 적용했고
      // 실제 만료 처리 (prefs reset + _isPremium=false) 는 누락. 시계 되돌리기로
      // trial 영구화 가능했던 회귀 차단.
      if (SecureClock.now().isAfter(expiry)) {
        if (!_isBrand) {
          _isPremium = false;
          await _saveSecurePremiumState(isPremium: false, isBrand: _isBrand);
        }
        await prefs.remove(PrefKeys.purchaseGiftExpiry);
        _trialExpiry = null;
      } else {
        _trialExpiry = expiry;
      }
    } else {
      _trialExpiry = null;
    }
  }

  /// Build 299 (MED audit): AppLifecycleState.resumed 에서 호출해 trial 만료를
  /// 즉시 재평가. cold-start 외 foreground 복귀 시점도 보장.
  Future<void> reevaluateTrialExpiry() async {
    final prefs = await _getPrefs();
    final prevPremium = _isPremium;
    await _evaluateGiftExpiryFromPrefs(prefs);
    if (prevPremium != _isPremium) notifyListeners();
  }

  DateTime? _loadDateFromPrefs(SharedPreferences prefs, String key) {
    final ts = prefs.getInt(key) ?? 0;
    if (ts <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> _loadAndApplyScheduledPlanChange(SharedPreferences prefs) async {
    // legacy migration: purchase_scheduledDowngrade -> free
    final legacyTs =
        prefs.getInt(PrefKeys.purchaseScheduledDowngradeLegacy) ?? 0;
    final savedTs = prefs.getInt(PrefKeys.purchaseScheduledPlanChangeDate) ?? 0;
    final savedTarget =
        prefs.getString(PrefKeys.purchaseScheduledPlanChangeTarget) ?? '';

    DateTime? date;
    ScheduledPlanTarget? target;

    if (savedTs > 0 && savedTarget.isNotEmpty) {
      date = DateTime.fromMillisecondsSinceEpoch(savedTs);
      target = savedTarget == 'brand'
          ? ScheduledPlanTarget.brand
          : ScheduledPlanTarget.free;
    } else if (legacyTs > 0) {
      date = DateTime.fromMillisecondsSinceEpoch(legacyTs);
      target = ScheduledPlanTarget.free;
      await prefs.setInt(PrefKeys.purchaseScheduledPlanChangeDate, legacyTs);
      await prefs.setString(PrefKeys.purchaseScheduledPlanChangeTarget, 'free');
      await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    }

    if (date == null || target == null) {
      _scheduledPlanChangeDate = null;
      _scheduledPlanTarget = null;
      return;
    }

    // Build 306: SecureClock — scheduled downgrade 도 시계 우회 차단.
    if (SecureClock.now().isAfter(date)) {
      if (target == ScheduledPlanTarget.free) {
        _isPremium = false;
        _isBrand = false;
        await _saveSecurePremiumState(isPremium: false, isBrand: false);
      } else if (target == ScheduledPlanTarget.brand &&
          _isPremium &&
          !_isBrand) {
        _isPremium = true;
        _isBrand = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
      }
      _scheduledPlanChangeDate = null;
      _scheduledPlanTarget = null;
      await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
      await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
      return;
    }

    _scheduledPlanChangeDate = date;
    _scheduledPlanTarget = target;
  }

  // ── 신규 가입 3일 무료 Premium (Build 271: 7→3 단축) ─────────────────
  /// 신규 가입 사용자에게 3일간 Premium 자동 부여. signUp 성공 직후 1회 호출.
  /// 이미 Premium·Brand 인 사용자는 no-op (덮어쓰지 않음).
  /// 3일 후 `purchaseGiftExpiry` 체크에서 자동 만료 → Free 복귀.
  /// 영구 어드민(ceo@airony.xyz) 은 평생 Premium 이라 별도 처리 불필요.
  Future<void> grantWelcomeTrial({int days = 3}) async {
    if (_isPremium || _isBrand) return; // 이미 보유 → no-op
    final prefs = await _getPrefs();
    // Build 421 (sim-fresh P2): trial 평가가 SecureClock.now() 이므로 부여
    //   expiry 도 SecureClock 기준 — monotonic clock 보다 뒤로 안 가게 정렬.
    final expiry = SecureClock.now().add(Duration(days: days));
    // Build 304: trial 부여 시각을 SecureClock watermark 에 박는다.
    // 이후 클럭 되돌리기 시 isTrialActive 가 expiry 보다 앞을 절대 안 봄.
    SecureClock.touch();
    // Build 290 (P0): 영구 Premium 노출 방지 — prefs 부터 쓰고 (failure surface
    // 가 큰 쪽) 그 다음 secure storage 에 쓴다. 만약 prefs 가 실패하면 secure
    // storage 도 안 쓰여서 다음 launch 에 _isPremium=false 유지 → 영구 unlimited
    // trial 회귀 차단.
    final ok = await prefs.setInt(
      PrefKeys.purchaseGiftExpiry,
      expiry.millisecondsSinceEpoch,
    );
    if (!ok) {
      // prefs write 실패 → trial 부여 자체를 포기.
      return;
    }
    _isPremium = true;
    _trialExpiry = expiry;
    await _saveSecurePremiumState(isPremium: true, isBrand: false);
    notifyListeners();
  }

  // ── Premium 구매 ────────────────────────────────────────────────────────
  Future<bool> buyPremium() async {
    if (!_startLoading(PurchaseOperation.premium)) return false;
    if (!_isTestMode &&
        !_isBetaFreePremium &&
        !_isBetaUpgradeSimulator &&
        !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 디버그 빌드 or RevenueCat 미연동 or 베타 무료 프리미엄 or 시뮬레이터 → 로컬 활성화
    if (_isTestMode || _isBetaFreePremium || _isBetaUpgradeSimulator) {
      return await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isPremium = true;
        _isBrand = false;
        await _saveSecurePremiumState(isPremium: true, isBrand: false);
        await _markBillingCycleRefreshed(prefs);
        // Build 414 (sim100 #26): 베타/시뮬레이터 결제도 RC 경로(922-928)와 동일
        //   하게 trial 잔여(giftExpiry) 클리어 — 안 하면 trial 만료 시점에
        //   _evaluateGiftExpiryFromPrefs 가 결제한 Premium 을 회수 + 오인 배너.
        _trialExpiry = null;
        await prefs.remove(PrefKeys.purchaseGiftExpiry);
      });
    }

    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) {
        _setError('결제 서비스 연결 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final result = await _purchaseByPackageOrStoreProduct(
        PurchaseProductIds.premiumMonthlyCandidates(),
        preferNonSubscription: false,
      );
      if (result == null) {
        _setProductResolveError(PurchaseProductIds.premiumMonthly);
        return false;
      }
      _applyCustomerInfo(result);
      final prefs = await _getPrefs();
      await _persistBillingDateToPrefs();
      await _clearScheduledPlanChange(prefs);
      // Build 347 (PR-U2 시뮬레이션 P1): trial 활성 중 정식 결제 → trial 잔여
      //   시각이 _isPremium=true 와 공존해 isTrialActive 가 여전히 true 로 보이는
      //   ambiguous state. 정식 결제 성공 후 trial expiry clear.
      if (_isPremium) {
        _trialExpiry = null;
        // Build 368 (PR-CC1 P0 #4): trial expiry 는 secure storage 가 아닌
        //   prefs(`purchase_giftExpiry`) 에 저장됨. _secure.delete 는 no-op 였음
        //   → 다음 cold-start _evaluateGiftExpiryFromPrefs 가 만료 시점 진입
        //   → 실 결제 사용자 Premium 박탈 회귀. 올바른 key 로 prefs.remove.
        await prefs.remove(PrefKeys.purchaseGiftExpiry);
      }
      _stopLoading();
      return _isPremium;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── Brand 구매 ──────────────────────────────────────────────────────────
  Future<bool> buyBrand() async {
    if (!_startLoading(PurchaseOperation.brand)) return false;

    // 베타 무료 프리미엄 모드에서는 Brand 구독 불가
    if (_isBetaFreePremium) {
      _setError('베타 테스트 기간에는 Brand 구독을 이용할 수 없습니다. 정식 출시 후 이용해주세요.');
      return false;
    }

    if (!_isTestMode &&
        !_isBetaUpgradeSimulator &&
        !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 베타 시뮬레이터에서는 Brand 도 즉시 활성화 (캠페인 기능 체험용).
    if (_isTestMode || _isBetaUpgradeSimulator) {
      return await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isBrand = true;
        _isPremium = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
        await _markBillingCycleRefreshed(prefs);
      });
    }

    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) {
        _setError('결제 서비스 연결 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final result = await _purchaseByPackageOrStoreProduct(
        PurchaseProductIds.brandMonthlyCandidates(),
        preferNonSubscription: false,
      );
      if (result == null) {
        _setProductResolveError(PurchaseProductIds.brandMonthly);
        return false;
      }
      _applyCustomerInfo(result);
      final prefs = await _getPrefs();
      await _persistBillingDateToPrefs();
      await _clearScheduledPlanChange(prefs);
      _stopLoading();
      return _isBrand;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── 선물권 구매 ─────────────────────────────────────────────────────────
  // 실제 결제는 구매자가 처리하고, 코드를 받아서 수신자가 사용하는 형태
  // 테스트 모드에서는 구매자 자신의 계정에 영향 없이 코드만 생성
  Future<bool> buyGiftCard() async {
    // Build 368 (PR-CC1 P0 #2 #3): gift card 출시 차단.
    //   1. 클라이언트가 로컬 코드만 생성 (`LTGO-xxx-PREM`) — 서버 등록 / redeem
    //      흐름 0건 → 구매자 ₩8,910 지불 후 친구가 코드 입력해도 사용 불가
    //      (코드 입력 화면 자체 없음). 결제 자산 환상.
    //   2. _applyCustomerInfo(result) 호출이 RC entitlement mapping 에 따라
    //      buyer 까지 Premium flip 가능 — 주석의 의도("구매자 entitlement
    //      활성화 안함") 와 정반대.
    // 출시 차단 — 서버 redemption 흐름 (Firestore gift_codes/{code} +
    //   redeem UI) 완성될 때까지 기능 비활성. UI 호출처는 false 받고 자동
    //   에러 메시지 표시. 베타/테스트 모드도 차단 (UI 가 우회 노출되지 않도록).
    // Build 399 (PR-II2): i18n 안내 키 사용. 14언어 사용자 한글 노출 차단.
    //   _setError 는 String 직접 받음 → 호출자가 l10n 키 자체를 넘겨야 하지만
    //   현재 PurchaseService 는 BuildContext 미보유 → ko 기본 + (en) 병기.
    //   진정한 i18n 은 호출 site (premium_screen) 에서 처리 권장 (deferred).
    _setError('선물권 기능 준비 중 / Gift card feature coming soon');
    return false;
  }

  // ── 브랜드 추가 발송권 구매 (소모성 상품 1,000통 ₩15,000) ──────────────────
  Future<bool> buyBrandExtra(AppState appState) async {
    // UI는 PurchaseService/AppState를 함께 참조하므로,
    // 구매 시점에는 두 상태가 잠깐 어긋날 수 있다.
    // PurchaseService 기준으로 브랜드가 확인되면 AppState를 보정해 진행한다.
    final canBuyAsBrand = appState.isBrandMember || _isBrand;
    if (!canBuyAsBrand) {
      _setError('브랜드 계정에서만 추가 발송권을 구매할 수 있어요.');
      return false;
    }
    if (!appState.isBrandMember && _isBrand) {
      appState.syncPremiumStatus(isPremium: true, isBrand: true);
    }
    if (!_startLoading(PurchaseOperation.brandExtra)) return false;
    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }
    if (!_isTestMode && !appState.isBrandExtraServerVerificationReady) {
      _setError(appState.brandExtraServerVerificationUnavailableMessage);
      return false;
    }

    // 디버그 빌드 or RevenueCat 미연동 → 테스트 모드
    if (_isTestMode) {
      return await _fakePurchase(() async {
        await appState.grantBrandExtraQuotaLocally(quotaAmount: 1000);
      });
    }

    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) {
        _setError('결제 서비스 연결 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final purchaseInfo = await _purchaseByPackageOrStoreProduct(
        PurchaseProductIds.brandExtra1000Candidates(),
        preferNonSubscription: true,
      );
      if (purchaseInfo == null) {
        _setProductResolveError(PurchaseProductIds.brandExtra1000);
        return false;
      }
      final triedTransactionIds = <String>{};

      Future<bool> tryVerifyFrom(CustomerInfo info) async {
        final txCandidates = _brandExtraTransactionsNewestFirst(
          info,
          excludeTransactionIds: triedTransactionIds,
        );
        if (txCandidates.isEmpty) return false;

        for (final tx in txCandidates) {
          triedTransactionIds.add(tx.transactionIdentifier);
          final verifyResult = await appState.verifyAndGrantBrandExtraQuota(
            transactionId: tx.transactionIdentifier,
            productId: tx.productIdentifier,
            quotaAmount: 1000,
            purchaseDateIso: tx.purchaseDate,
            appUserId: _activeAppUserId,
          );
          if (verifyResult == BrandExtraVerificationResult.success) {
            _stopLoading();
            return true;
          }
          if (verifyResult == BrandExtraVerificationResult.serverUnavailable) {
            _setError(appState.brandExtraServerVerificationUnavailableMessage);
            return false;
          }
          if (verifyResult == BrandExtraVerificationResult.networkError) {
            _setError('결제 검증 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
            return false;
          }
          // alreadyProcessed: 다음 후보 transaction으로 재시도
        }
        return false;
      }

      if (await tryVerifyFrom(purchaseInfo)) return true;

      // 구매 직후 CustomerInfo 반영 지연 대비 1회 재조회
      final refreshedInfo = await Purchases.getCustomerInfo();
      if (await tryVerifyFrom(refreshedInfo)) return true;

      _setError('결제는 완료됐지만 서버 검증을 완료하지 못했습니다. 고객센터에 문의해주세요.');
      return false;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  /// Build 324: ExactDrop 100통 패키지 IAP. 이전에 "관리자에게 문의" 만 있어
  /// 자영업자가 토요일 오후 100통 소진 시 ceo@airony.xyz 메일 후 답 기다리는
  /// UX 였음 (Brand 사장 시뮬레이션 핵심 발견). RevenueCat 비구독 (one-time)
  /// 상품으로 등록 — 즉시 구매 + AppState.adminGrantExactDropCredits 호출.
  ///
  /// 단순화: brandExtra 의 서버 verification 흐름 없이 RevenueCat 구매 성공만
  /// 검증 (one-time consumable, replay 차단은 RC + 상점 측에서).
  ///
  /// Build 325 (T4): 50 / 100 / 500 통 가격 티어 지원. qty 만 50/100/500 중
  /// 하나로 호출. 100 외 값은 fallback 으로 100 처리.
  Future<bool> buyExactDrop100(AppState appState) =>
      buyExactDrop(appState, qty: 100);

  Future<bool> buyExactDrop(AppState appState, {required int qty}) async {
    final canBuyAsBrand = appState.isBrandMember || _isBrand;
    if (!canBuyAsBrand) {
      _setError('브랜드 계정에서만 ExactDrop 크레딧을 구매할 수 있어요.');
      return false;
    }
    final op = qty == 50
        ? PurchaseOperation.exactDrop50
        : qty == 500
            ? PurchaseOperation.exactDrop500
            : PurchaseOperation.exactDrop100;
    if (!_startLoading(op)) return false;
    if (!_isTestMode &&
        !_isBetaUpgradeSimulator &&
        !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 디버그 / RC 미연동 / 베타 시뮬레이터 → 테스트 모드 (즉시 qty grant).
    // Build 429 (device): 베타(TestFlight)에서도 ExactDrop '추가 구매' 가 동작하도록
    //   _isBetaUpgradeSimulator 추가 — 이전엔 _isTestMode(디버그 한정)만이라
    //   실 IAP 미등록 베타에서 구매가 항상 실패했음.
    if (_isTestMode || _isBetaUpgradeSimulator) {
      return await _fakePurchase(() async {
        await appState.adminGrantExactDropCredits(qty);
      });
    }

    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) {
        _setError('결제 서비스 연결 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final purchaseInfo = await _purchaseByPackageOrStoreProduct(
        PurchaseProductIds.exactDropCandidates(qty),
        preferNonSubscription: true,
      );
      if (purchaseInfo == null) {
        _setProductResolveError(PurchaseProductIds.exactDropProductId(qty));
        return false;
      }
      // 구매 성공 → qty 크레딧 즉시 grant (Firestore sync 포함).
      await appState.adminGrantExactDropCredits(qty);
      _stopLoading();
      return true;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── 구매 복원 ───────────────────────────────────────────────────────────
  Future<bool> restorePurchases() async {
    if (!_startLoading(PurchaseOperation.restore)) return false;
    if (!_isTestMode &&
        !_isBetaFreePremium &&
        !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 베타 무료 프리미엄 모드 → 로컬 상태만 복원
    if (_isBetaFreePremium) {
      final prefs = await _getPrefs();
      await _loadSecurePremiumState();
      _nextBillingDate = _loadDateFromPrefs(
        prefs,
        PrefKeys.purchaseNextBillingDate,
      );
      await _loadAndApplyScheduledPlanChange(prefs);
      _stopLoading();
      return true;
    }

    if (_isTestMode) {
      final prefs = await _getPrefs();
      await _loadSecurePremiumState();
      _nextBillingDate = _loadDateFromPrefs(
        prefs,
        PrefKeys.purchaseNextBillingDate,
      );
      await _loadAndApplyScheduledPlanChange(prefs);
      _stopLoading();
      return true;
    }

    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) {
        _setError('결제 서비스 연결 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      await _persistBillingDateToPrefs();
      _stopLoading();
      // Build 414 (sim100 #28): 활성 entitlement 가 없으면 false 반환 — 이전엔
      //   복원할 구매가 없어도 무조건 true 라 '복원 성공' 거짓 안내. 호출처
      //   (premium_screen)가 false 시 '복원할 구매 없음' 으로 분기.
      return _isPremium || _isBrand;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── 구독 해지 안내 (실제 해지는 앱스토어/플레이스토어에서) ────────────────
  Future<void> cancelSubscription() async {
    // RevenueCat에서는 앱 내에서 직접 해지할 수 없음
    // 앱스토어/플레이스토어 구독 관리 페이지로 이동 안내 필요
    // UI에서 url_launcher로 아래 URL 열기:
    // iOS: https://apps.apple.com/account/subscriptions
    // AOS: https://play.google.com/store/account/subscriptions
    final prefs = await _getPrefs();
    await _clearScheduledPlanChange(prefs);
    notifyListeners();
  }

  // ── 플랜 다운그레이드 예약 (다음 결제일 = 약 30일 후부터 무료 전환) ─────────
  Future<void> scheduleDowngradeToFree() async {
    if (!_isPremium && !_isBrand) return;
    final prefs = await _getPrefs();
    final effectiveDate =
        _nextBillingDate ?? SecureClock.now().add(const Duration(days: 30));

    _scheduledPlanChangeDate = effectiveDate;
    _scheduledPlanTarget = ScheduledPlanTarget.free;
    await prefs.setInt(
      PrefKeys.purchaseScheduledPlanChangeDate,
      effectiveDate.millisecondsSinceEpoch,
    );
    await prefs.setString(PrefKeys.purchaseScheduledPlanChangeTarget, 'free');
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    notifyListeners();
  }

  // ── Premium -> Brand 변경 (Build 368 PR-CC1 P0 #1: schedule deprecated) ───
  // 이전엔 다음 결제일까지 'schedule' 후 자동 _isBrand flip → IAP 없이 Brand
  // 권한 부여되던 critical 회귀. 이제 schedule 자체를 noop — Brand 전환은
  // 반드시 buyBrand() (실제 RC IAP) 통해서만. UI 가 이 메서드 호출 시 자동
  // buyBrand 로 fall-through 또는 안내.
  // Build 414 (sim100 #4/#6): Future<bool> 로 변경 — 결제 취소/실패 시 false 를
  //   반환해 호출자(premium_screen)가 '성공' 스낵바를 띄우지 않도록. 이전엔
  //   void 라 buyBrand() 결과를 버려 결제 실패에도 무조건 녹색 성공 표시.
  @Deprecated('Use buyBrand() — scheduling 은 P0 회귀로 제거됨')
  Future<bool> scheduleUpgradeToBrand({String? userEmail}) async {
    if (kDebugMode) {
      debugPrint('[PurchaseService] scheduleUpgradeToBrand deprecated — buyBrand 로 fall-through');
    }
    // Test/beta 모드에서만 시뮬레이션 — production 은 fall-through.
    if (_isTestMode || _isBetaUpgradeSimulator) {
      if (!_startLoading(PurchaseOperation.brand)) return false;
      return await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isBrand = true;
        _isPremium = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
        await _markBillingCycleRefreshed(prefs);
      });
    }
    // Production: 실제 IAP 강제.
    return await buyBrand();
  }

  // ── 테스트 이메일 자동 브랜드 설정 (DEBUG + BETA_ADMIN_EMAIL) ──────────────
  /// 허용 조건:
  /// 1) 디버그 빌드 + shimyup@gmail.com (하드코딩 테스트 계정)
  /// 2) 릴리스 빌드라도 BETA_ADMIN_EMAIL 주입 값과 일치 (베타 관리자)
  /// 정식 출시 시 .env.local 에서 BETA_ADMIN_EMAIL 제거하면 자동으로 잠김.
  Future<void> applyTestEmailOverride(String? email) async {
    if (email == null || email.isEmpty) return;
    // Build 207: 정식 출시 빌드에서는 BETA_ADMIN_EMAIL 주입돼 있어도 무시.
    // 베타 기간이 끝나면 코드 변경 없이도 자동으로 막혀 있어야 함.
    if (BetaConstants.disableInRelease && kReleaseMode) return;
    final isDebugTester =
        kDebugMode && email.toLowerCase() == DebugConstants.testBrandEmail;
    final isBetaAdmin = BetaConstants.isAdmin(email);
    if (!isDebugTester && !isBetaAdmin) return;
    if (_isBrand) return; // 이미 브랜드면 skip
    final prefs = await _getPrefs();
    _isBrand = true;
    _isPremium = true;
    await _saveSecurePremiumState(isPremium: true, isBrand: true);
    await _markBillingCycleRefreshed(prefs);
    notifyListeners();
  }

  // ── 관리자 전용: 등급 직접 변경 (DEBUG 전용) ────────────────────────────────
  Future<void> debugSetTier({
    required bool isPremium,
    required bool isBrand,
  }) async {
    if (!kDebugMode) return;
    _isPremium = isPremium;
    _isBrand = isBrand;
    await _saveSecurePremiumState(isPremium: isPremium, isBrand: isBrand);
    notifyListeners();
  }

  // ── 다운그레이드 예약 취소 ──────────────────────────────────────────────────
  Future<void> cancelScheduledDowngrade() async {
    final prefs = await _getPrefs();
    _scheduledPlanChangeDate = null;
    _scheduledPlanTarget = null;
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
    notifyListeners();
  }

  // ── 디버그 / 테스트용 ────────────────────────────────────────────────────
  Future<void> debugSetPremium({
    bool premium = true,
    bool brand = false,
  }) async {
    if (!kDebugMode) return;
    final prefs = await _getPrefs();
    _isPremium = premium;
    _isBrand = brand;
    await _saveSecurePremiumState(isPremium: premium, isBrand: brand);
    await _markBillingCycleRefreshed(prefs);
    notifyListeners();
  }

  Future<void> _markBillingCycleRefreshed(SharedPreferences prefs) async {
    _nextBillingDate = SecureClock.now().add(const Duration(days: 30));
    await prefs.setInt(
      PrefKeys.purchaseNextBillingDate,
      _nextBillingDate!.millisecondsSinceEpoch,
    );
    await _clearScheduledPlanChange(prefs);
  }

  Future<void> _clearScheduledPlanChange(SharedPreferences prefs) async {
    _scheduledPlanChangeDate = null;
    _scheduledPlanTarget = null;
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
  }

  Future<void> syncUserIdentity({String? userId, String? email}) async {
    final normalizedUserId = _normalizeAppUserId(userId: userId, email: email);
    if (_isTestMode) {
      _activeAppUserId = normalizedUserId;
      return;
    }
    if (!_initialized) {
      _activeAppUserId = normalizedUserId;
      return;
    }
    try {
      if (!await _ensureRevenueCatConfigured()) {
        _activeAppUserId = normalizedUserId;
        return;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] 사용자 식별 동기화 준비 실패: $e');
      _activeAppUserId = normalizedUserId;
      return;
    }

    try {
      if (normalizedUserId == null) {
        if (_activeAppUserId == null) return;
        final info = await Purchases.logOut();
        _activeAppUserId = null;
        _applyCustomerInfo(info);
        await _persistBillingDateToPrefs();
        final prefs = await _getPrefs();
        await _loadAndApplyScheduledPlanChange(prefs);
        notifyListeners();
        return;
      }

      if (_activeAppUserId == normalizedUserId) return;
      final result = await Purchases.logIn(normalizedUserId);
      _activeAppUserId = normalizedUserId;
      _applyCustomerInfo(result.customerInfo);
      await _persistBillingDateToPrefs();
      final prefs = await _getPrefs();
      await _loadAndApplyScheduledPlanChange(prefs);
      notifyListeners();
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] 사용자 식별 동기화 실패: $e');
    }
  }

  String? _normalizeAppUserId({String? userId, String? email}) {
    final id = userId?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) return normalizedEmail;
    return null;
  }

  // ── Private 헬퍼 ────────────────────────────────────────────────────────

  /// Build 409 (sim P1.14/P1.20): productId 의 현지화된 가격 문자열(예: "$4.99",
  ///   "₩6,000", "¥720"). RC StoreProduct.priceString 은 사용자 스토어프론트
  ///   로케일/통화로 자동 포맷됨. 캐시 또는 offering 에서 조회, 없으면 null →
  ///   호출자가 하드코딩 KRW fallback. (offerings 미로드 시 null)
  String? localizedPriceFor(String productId) {
    // Build 421 (sim-fresh P3): 빈 문자열 priceString 은 null 로 정규화 — 호출자
    //   `?? '₩4,900'` fallback 이 null 에서만 동작하므로, RC 가 빈 가격을 주면
    //   가격이 공란으로 표시되던 위험 차단.
    final cached = _storeProductsById[productId]?.priceString;
    if (cached != null && cached.trim().isNotEmpty) return cached;
    final pkg = _findPackage(productId)?.storeProduct.priceString;
    return (pkg != null && pkg.trim().isNotEmpty) ? pkg : null;
  }

  /// Offering에서 productId에 맞는 Package 찾기
  Package? _findPackage(String productId) {
    if (_offerings == null) return null;

    final candidates = <Offering>[
      if (_offerings!.getOffering(_RcOfferings.defaultOffering) != null)
        _offerings!.getOffering(_RcOfferings.defaultOffering)!,
      if (_offerings!.current != null) _offerings!.current!,
      ..._offerings!.all.values,
    ];

    final visited = <String>{};
    for (final offering in candidates) {
      if (!visited.add(offering.identifier)) continue;
      for (final pkg in offering.availablePackages) {
        if (pkg.storeProduct.identifier == productId) return pkg;
      }
    }
    return null;
  }

  // Build 293 (P1): _resolvePackage 3회 재시도 + exponential backoff.
  // 사용자가 "상품 정보를 불러올 수 없습니다" 보던 회귀: RevenueCat offerings
  // 가 일시적으로 null 일 때 단 1회 retry 만 → 네트워크 일순간 끊김 / RC SDK
  // 초기화 지연 시 실패 확률 높았음. 본 빌드부터 3회 재시도 (300ms / 600ms /
  // 1200ms backoff) 로 transient 오류에 강건.
  Future<Package?> _resolvePackage(String productId) async {
    var pkg = _findPackage(productId);
    if (pkg != null) return pkg;
    if (_isTestMode) return null;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        _offerings = await Purchases.getOfferings();
        pkg = _findPackage(productId);
        if (pkg != null) return pkg;
      } on PlatformException catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[PurchaseService] 상품 재조회 실패 attempt ${attempt + 1}/3 ($productId): $e');
        }
      }
      // 다음 시도까지 대기 (마지막 attempt 후엔 대기 안 함).
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 300 * (1 << attempt)));
      }
    }
    return null;
  }

  Future<CustomerInfo?> _purchaseByPackageOrStoreProduct(
    List<String> productIds, {
    required bool preferNonSubscription,
  }) async {
    for (final productId in productIds) {
      final pkg = await _resolvePackage(productId);
      if (pkg != null) {
        return Purchases.purchasePackage(pkg);
      }

      final storeProduct = await _resolveStoreProduct(
        productId,
        preferNonSubscription: preferNonSubscription,
      );
      if (storeProduct != null) {
        return Purchases.purchaseStoreProduct(storeProduct);
      }
    }
    return null;
  }

  // Build 293 (P1): StoreProduct 조회도 카테고리당 2회 재시도. offerings 가
  // null 일 때 fallback 경로 — 여기마저 실패하면 사용자에게 "상품 정보 없음"
  // 노출. transient 오류 시 회복 가능성 ↑.
  Future<StoreProduct?> _resolveStoreProduct(
    String productId, {
    required bool preferNonSubscription,
  }) async {
    final cached = _storeProductsById[productId];
    if (cached != null) return cached;
    if (_isTestMode) return null;

    final categories = preferNonSubscription
        ? const <ProductCategory>[
            ProductCategory.nonSubscription,
            ProductCategory.subscription,
          ]
        : const <ProductCategory>[
            ProductCategory.subscription,
            ProductCategory.nonSubscription,
          ];

    for (final category in categories) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final products = await Purchases.getProducts([
            productId,
          ], productCategory: category);
          for (final product in products) {
            if (product.identifier == productId) {
              _storeProductsById[productId] = product;
              return product;
            }
          }
          // 결과 비어있으면 retry 한 번 더.
        } on PlatformException catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[PurchaseService] StoreProduct 조회 실패 attempt ${attempt + 1}/2 ($productId/${category.name}): $e',
            );
          }
        }
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
    return null;
  }

  List<StoreTransaction> _brandExtraTransactionsNewestFirst(
    CustomerInfo info, {
    required Set<String> excludeTransactionIds,
  }) {
    final targetProductIds = PurchaseProductIds.brandExtra1000Candidates()
        .toSet();
    final txs = info.nonSubscriptionTransactions.where((tx) {
      if (!targetProductIds.contains(tx.productIdentifier)) {
        return false;
      }
      if (tx.transactionIdentifier.isEmpty) return false;
      if (excludeTransactionIds.contains(tx.transactionIdentifier))
        return false;
      return true;
    }).toList();

    txs.sort((a, b) {
      final bMillis =
          DateTime.tryParse(b.purchaseDate)?.millisecondsSinceEpoch ?? 0;
      final aMillis =
          DateTime.tryParse(a.purchaseDate)?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });
    return txs;
  }

  /// 테스트 모드용 가짜 구매
  Future<bool> _fakePurchase(Future<void> Function() action) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await action();
    _stopLoading();
    return true;
  }

  /// Build 423 (sim-crosscut P2): 락 획득 성공 여부를 bool 로 반환 — 이전엔 void
  ///   라, 락이 잡혀 있어도 caller 가 계속 진행해 두 번째 buy 가 _setError 의
  ///   _loading=false 로 첫 operation 의 락을 풀어버리는 race(중복 grant 포함)가
  ///   있었음. caller 는 `if (!_startLoading(op)) return false;` 로 즉시 bail.
  bool _startLoading(PurchaseOperation operation) {
    if (_loading) {
      if (kDebugMode) {
        debugPrint(
          '[purchase] _startLoading skip — busy with $_activeOperation',
        );
      }
      return false;
    }
    _loading = true;
    _activeOperation = operation;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void _stopLoading() {
    _loading = false;
    _activeOperation = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _loading = false;
    _activeOperation = null;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setProductResolveError(String productId) {
    if (kDebugMode) {
      final offeringSnapshot = _offerings == null
          ? 'offerings=null'
          : _offerings!.all.entries
                .map(
                  (e) =>
                      '${e.key}['
                      '${e.value.availablePackages.map((p) => p.storeProduct.identifier).join(', ')}]',
                )
                .join(' | ');
      debugPrint(
        '[PurchaseService] 상품 해석 실패 '
        'productId=$productId '
        'cachedStoreProducts=${_storeProductsById.keys.join(',')} '
        'offeringSnapshot=$offeringSnapshot',
      );
      _setError(
        // Build 311: 베타 빌드는 IAP 가 ASC 콘솔 셋업 전이라 정상 — 사용자에게
        // 명확히 "테스트 환경" 임을 안내. release 빌드는 진짜 회귀이므로 기술
        // 메시지 유지.
        _isTestMode
            ? '테스트 환경 — IAP 상품이 아직 App Store Connect 에 등록되지 않았습니다.\n'
                '(product: $productId)\n'
                '실 결제는 출시 빌드에서만 동작합니다.'
            : '상품 정보를 불러올 수 없습니다. '
                '(product: $productId)\n'
                'RevenueCat Offering(default)과 App Store 상품 연결 상태를 확인해주세요.',
      );
      return;
    }
    // Build 293: 사용자 친화 메시지 + 재시도 안내. 이전엔 기술 용어 (RevenueCat
     // / Offering) 그대로 노출 → 사용자가 어떤 조치할지 모름.
    // Build 311: 베타 빌드에서는 테스트 환경 안내로 교체.
    _setError(
      _isTestMode
          ? '테스트 환경 — 결제 흐름은 출시 빌드에서만 동작합니다.\n'
              'TestFlight 베타 테스터는 무료로 모든 기능 사용 가능합니다.'
          : '상품 정보를 불러올 수 없어요.\n'
              '잠시 후 다시 시도해주세요. 문제가 계속되면 앱을 재시작해보세요.',
    );
  }

  /// purchases_flutter v8에서는 PurchasesErrorCode가 enum이라 직접 throw되지 않음.
  /// PlatformException.code 값이 PurchasesErrorCode 인덱스 문자열로 전달됨.
  /// - code "1" = purchaseCancelledError (사용자 취소) → 에러 없이 조용히 처리
  void _handlePlatformException(PlatformException e) {
    final codeInt = int.tryParse(e.code);
    // 사용자 취소 (PurchasesErrorCode.purchaseCancelledError.index == 1)
    if (codeInt == PurchasesErrorCode.purchaseCancelledError.index) {
      _stopLoading();
      return;
    }
    // 그 외 에러: 코드 → 사람이 읽을 수 있는 메시지로 변환
    final rcCode =
        (codeInt != null && codeInt < PurchasesErrorCode.values.length)
        ? PurchasesErrorCode.values[codeInt]
        : null;
    _setError(
      rcCode != null
          ? _rcErrorMessage(rcCode)
          : (e.message ?? '구매 중 오류가 발생했습니다.'),
    );
  }

  String _rcErrorMessage(PurchasesErrorCode code) {
    // 한국어 / 영어 메시지 (유저 언어 설정 우선, 없으면 시스템 로케일 사용)
    final languageCode = _preferredLanguageCode.isNotEmpty
        ? _preferredLanguageCode
        : WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final isKo = languageCode.startsWith('ko');
    switch (code) {
      case PurchasesErrorCode.networkError:
        return isKo
            ? '네트워크 오류가 발생했습니다. 연결을 확인해주세요.'
            : 'Network error. Please check your connection.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return isKo
            ? '이 기기에서 구매가 허용되지 않습니다.'
            : 'Purchases are not allowed on this device.';
      case PurchasesErrorCode.purchaseInvalidError:
        return isKo ? '구매 정보가 올바르지 않습니다.' : 'Invalid purchase information.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return isKo
            ? '현재 구매할 수 없는 상품입니다.'
            : 'This product is currently unavailable.';
      case PurchasesErrorCode.storeProblemError:
        return isKo
            ? 'App Store 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'
            : 'Store error. Please try again later.';
      default:
        return isKo
            ? '구매 중 오류가 발생했습니다. 다시 시도해주세요.'
            : 'Purchase failed. Please try again.';
    }
  }
}
