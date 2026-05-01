import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/app_state.dart';
import '../config/app_keys.dart';

enum ScheduledPlanTarget { free, brand }

enum PurchaseOperation { premium, brand, giftCard, brandExtra, restore }

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

  // iOS (App Store Connect)
  static const String _premiumMonthlyIos = 'letter_go_premium_monthly_ios';
  static const String _brandMonthlyIos = 'letter_go_brand_monthly_ios';
  static const String _giftCardIos = 'letter_go_gift_1month_ios';
  static const String _brandExtra1000Ios = 'letter_go_brand_extra_1000_ios';

  // Android (Google Play Billing / RevenueCat import 결과)
  static const String _premiumMonthlyAndroid =
      'letter_go_premium_monthly:monthly';
  static const String _brandMonthlyAndroid = 'letter_go_brand_monthly:monthly';
  static const String _giftCardAndroid = _giftCardLegacy;
  static const String _brandExtra1000Android = _brandExtra1000Legacy;

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
class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _isBrand = false;
  bool get isBrand => _isBrand;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _initialized = false;
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
    final betaGranted =
        (await _secure.read(key: _kBetaGrantedKey)) == '1';
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

  // 플랜 변경 예약 (다음 결제일부터 반영)
  DateTime? _scheduledPlanChangeDate;
  ScheduledPlanTarget? _scheduledPlanTarget;
  DateTime? get scheduledPlanChangeDate => _scheduledPlanChangeDate;
  ScheduledPlanTarget? get scheduledPlanTarget => _scheduledPlanTarget;
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

  // UI 표시용 기본 상품 목록 (Offering 로드 전 fallback)
  List<ProductInfo> get products => [
    ProductInfo(
      id: PurchaseProductIds.premiumMonthly,
      title: 'Premium',
      price: '₩4,900',
      description: '하루 30통 발송 · 사진 첨부 · 타워 커스텀',
    ),
    ProductInfo(
      id: PurchaseProductIds.brandMonthly,
      title: 'Brand / Creator',
      price: '₩99,000',
      description: '인증 배지 · 하루 200통 · 대량 발송 · Premium 포함',
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
    if (BetaConstants.disableInRelease && kReleaseMode) return false;
    return _isBetaFreePremiumRaw;
  }

  /// UI에서 베타 무료 프리미엄 모드 여부를 확인할 때 사용
  bool get isBetaFreePremium => _isBetaFreePremium;

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
    await _loadAndApplyScheduledPlanChange(prefs);

    try {
      _offerings = await Purchases.getOfferings();
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] Offering 로드 실패: $e');
    }
    _isRevenueCatConfigured = true;
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
    if (!DateTime.now().isAfter(_scheduledPlanChangeDate!)) return;

    if (_scheduledPlanTarget == ScheduledPlanTarget.free) {
      _isPremium = false;
      _isBrand = false;
      unawaited(_saveSecurePremiumState(isPremium: false, isBrand: false));
    } else if (_scheduledPlanTarget == ScheduledPlanTarget.brand &&
        _isPremium &&
        !_isBrand) {
      _isBrand = true;
      unawaited(_saveSecurePremiumState(isPremium: true, isBrand: true));
    }
  }

  void _applyCustomerInfo(CustomerInfo info) {
    _isBrand = info.entitlements.active.containsKey(_RcEntitlements.brand);
    _isPremium =
        _isBrand ||
        info.entitlements.active.containsKey(_RcEntitlements.premium);
    _nextBillingDate = _parseRevenueCatDate(info.latestExpirationDate);
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

    final giftExpiry = prefs.getInt(PrefKeys.purchaseGiftExpiry) ?? 0;
    if (giftExpiry > 0) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(giftExpiry);
      if (DateTime.now().isAfter(expiry)) {
        if (!_isBrand) _isPremium = false;
        await prefs.remove(PrefKeys.purchaseGiftExpiry);
      }
    }

    _nextBillingDate = _loadDateFromPrefs(
      prefs,
      PrefKeys.purchaseNextBillingDate,
    );
    await _loadAndApplyScheduledPlanChange(prefs);
    notifyListeners();
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

    if (DateTime.now().isAfter(date)) {
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

  // ── Premium 구매 ────────────────────────────────────────────────────────
  Future<bool> buyPremium() async {
    _startLoading(PurchaseOperation.premium);
    if (!_isTestMode && !_isBetaFreePremium && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 디버그 빌드 or RevenueCat 미연동 or 베타 무료 프리미엄 → 로컬 활성화
    if (_isTestMode || _isBetaFreePremium) {
      return await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isPremium = true;
        _isBrand = false;
        await _saveSecurePremiumState(isPremium: true, isBrand: false);
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
      _stopLoading();
      return _isPremium;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── Brand 구매 ──────────────────────────────────────────────────────────
  Future<bool> buyBrand() async {
    _startLoading(PurchaseOperation.brand);

    // 베타 무료 프리미엄 모드에서는 Brand 구독 불가
    if (_isBetaFreePremium) {
      _setError('베타 테스트 기간에는 Brand 구독을 이용할 수 없습니다. 정식 출시 후 이용해주세요.');
      return false;
    }

    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    if (_isTestMode) {
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
    _startLoading(PurchaseOperation.giftCard);

    // 베타 무료 프리미엄 모드에서는 선물권 구매도 로컬 시뮬레이션
    if (_isBetaFreePremium) {
      await _fakePurchase(() async {});
      return true;
    }

    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    if (_isTestMode) {
      // 테스트 모드: 구매자 프리미엄 활성화 없이 결제 흐름만 시뮬레이션
      await _fakePurchase(() async {});
      return true;
    }

    try {
      final ready = await _ensureRevenueCatConfigured();
      if (!ready) {
        _setError('결제 서비스 연결 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final result = await _purchaseByPackageOrStoreProduct(
        PurchaseProductIds.giftCardCandidates(),
        preferNonSubscription: true,
      );
      if (result == null) {
        _setProductResolveError(PurchaseProductIds.giftCard);
        return false;
      }
      // 선물권은 구매자 자신의 entitlement를 활성화하지 않음
      // RevenueCat에서 선물권 상품이 non-consumable 또는 소모성으로 설정되어 있어야 함
      _applyCustomerInfo(result);
      _stopLoading();
      return true;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
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
    _startLoading(PurchaseOperation.brandExtra);
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

  // ── 구매 복원 ───────────────────────────────────────────────────────────
  Future<bool> restorePurchases() async {
    _startLoading(PurchaseOperation.restore);
    if (!_isTestMode && !_isBetaFreePremium && !_isRcKeyConfiguredForCurrentPlatform) {
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
      return true;
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
        _nextBillingDate ?? DateTime.now().add(const Duration(days: 30));

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

  // ── Premium -> Brand 변경 예약 (다음 결제일부터 반영) ───────────────────────
  Future<void> scheduleUpgradeToBrand({String? userEmail}) async {
    if (!_isPremium || _isBrand) return;

    // 테스트 모드: 즉시 브랜드로 업그레이드 (발송 한도는 AppState에서 계정별로 제한)
    if (_isTestMode) {
      _startLoading(PurchaseOperation.brand);
      await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isBrand = true;
        _isPremium = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
        await _markBillingCycleRefreshed(prefs);
      });
      return;
    }

    final prefs = await _getPrefs();
    final effectiveDate =
        _nextBillingDate ?? DateTime.now().add(const Duration(days: 30));
    _scheduledPlanChangeDate = effectiveDate;
    _scheduledPlanTarget = ScheduledPlanTarget.brand;
    await prefs.setInt(
      PrefKeys.purchaseScheduledPlanChangeDate,
      effectiveDate.millisecondsSinceEpoch,
    );
    await prefs.setString(PrefKeys.purchaseScheduledPlanChangeTarget, 'brand');
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    notifyListeners();
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
    _nextBillingDate = DateTime.now().add(const Duration(days: 30));
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

  Future<Package?> _resolvePackage(String productId) async {
    var pkg = _findPackage(productId);
    if (pkg != null) return pkg;
    if (_isTestMode) return null;
    try {
      _offerings = await Purchases.getOfferings();
      pkg = _findPackage(productId);
      return pkg;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] 상품 재조회 실패 ($productId): $e');
      return null;
    }
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
      } on PlatformException catch (e) {
        if (kDebugMode) debugPrint(
          '[PurchaseService] StoreProduct 조회 실패 ($productId/${category.name}): $e',
        );
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

  void _startLoading(PurchaseOperation operation) {
    _loading = true;
    _activeOperation = operation;
    _errorMessage = null;
    notifyListeners();
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
        '상품 정보를 불러올 수 없습니다. '
        '(product: $productId)\n'
        'RevenueCat Offering(default)과 App Store 상품 연결 상태를 확인해주세요.',
      );
      return;
    }
    _setError(
      '상품 정보를 불러올 수 없습니다.\n'
      'App Store 상품 상태, RevenueCat Offering(default) 연결, '
      '테스트 계정(App Store Sandbox) 로그인을 확인해주세요.',
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
