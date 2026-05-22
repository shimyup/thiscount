import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/time_theme.dart';
import 'core/data/country_cities.dart';
import 'core/localization/language_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/feedback_service.dart';
import 'core/services/geocoding_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/secure_clock.dart';
import 'state/app_state.dart';
import 'features/splash/splash_screen.dart'; // kept for route
import 'features/auth/screens/auth_screen.dart';
import 'features/compose/screens/compose_screen.dart';
import 'features/intro/delivery_intro_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_tour_screen.dart';
import 'features/admin/admin_special_message_screen.dart';
import 'features/brand/brand_insights_screen.dart';
// Build 321: BrandZoneSetupScreen 제거됨 — compose 화면에 통합 (자동 zone 토글).
import 'features/premium/premium_screen.dart';
import 'features/v5_preview/v5_preview_root.dart';
import 'widgets/main_scaffold.dart';

/// 앱 시작 시 위치를 조용히 조회합니다.
/// 권한을 새로 요청하지 않고 이미 허용된 경우에만 사용합니다.
/// 권한 요청은 온보딩 화면에서 맥락과 함께 처리됩니다.
Future<Position?> _getLocation() async {
  try {
    final permission = await Geolocator.checkPermission();
    // 이미 허용된 경우에만 위치 조회 (denied / deniedForever 시 요청 안 함)
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    ).timeout(const Duration(seconds: 5));
  } catch (_) {
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // void 초기화 + bool/Position 동시 병렬 실행 → 시작 시간 단축
  await Future.wait([
    NotificationService.initialize(),
    NotificationService.loadPushMode(),
    CountryCities.init(),
    GeocodingService.instance.initialize(),
    // Build 182: 사운드 효과 프리로드. asset 경로 에러는 silent fail.
    FeedbackService.init(),
    // Build 304: 시계 되돌리기 우회 차단 — trial/OTP/lockout 만료 검증에 사용.
    SecureClock.init(),
  ]);
  // Build 258: 영구 어드민 계정 (ceo@airony.xyz / 0000) 자동 부트스트랩.
  // 이미 어떤 계정이라도 있으면 no-op. 없을 때만 자동 가입.
  // Build 297 (P0 audit): kDebugMode 가드 — release 빌드 no-op.
  await AuthService.bootstrapAdminIfNeeded();
  // Build 297 (HIGH security audit): OTP rate-limit / verify-failure 카운터
  // 를 secure storage 에서 복원. 앱 재시작으로 카운터 우회 (brute-force) 차단.
  await AuthService.restoreOtpRateState();

  // Build 305 (BLOCKER): 부팅 시 한쪽 future 실패가 다른 한쪽까지 죽이지
  // 않도록 각자 catch 로 default 복귀. Future.wait 가 throw 하면 전체 부팅
  // 실패하던 회귀 차단.
  final loginFuture = AuthService.isLoggedIn().catchError((e) {
    assert(() {
      debugPrint('[main] isLoggedIn 실패: $e');
      return true;
    }());
    return false;
  });
  final locFuture = _getLocation().catchError((e) {
    assert(() {
      debugPrint('[main] getLocation 실패: $e');
      return true;
    }());
    return null as Position?;
  });
  final loggedIn = await loginFuture;
  final position = await locFuture;

  Map<String, String>? userData;
  if (loggedIn) {
    try {
      userData = await AuthService.getCurrentUser();
    } catch (e) {
      assert(() {
        debugPrint('[main] getCurrentUser 실패: $e');
        return true;
      }());
      userData = null;
    }
  }

  runApp(
    GlobalDriftApp(
      initialLoggedIn: loggedIn,
      initialUserData: userData,
      initialLat: position?.latitude,
      initialLng: position?.longitude,
    ),
  );
}

class GlobalDriftApp extends StatefulWidget {
  final bool initialLoggedIn;
  final Map<String, String>? initialUserData;
  final double? initialLat;
  final double? initialLng;

  const GlobalDriftApp({
    super.key,
    required this.initialLoggedIn,
    this.initialUserData,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<GlobalDriftApp> createState() => _GlobalDriftAppState();
}

class _GlobalDriftAppState extends State<GlobalDriftApp> {
  late AppState _appState;
  // 싱글톤이지만 변수에 고정 → 동일 인스턴스 보장 + listener 해제 가능
  final PurchaseService _purchaseService = PurchaseService();
  Timer? _themeTimer;
  TimeOfDayPeriod? _lastPeriod;
  // Build 254: 푸시 알림 탭 시 네비게이션 라우팅용 키.
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  void _onPurchaseChanged() {
    _purchaseService.setPreferredLanguageCode(
      _appState.currentUser.languageCode,
    );
    _appState.syncPremiumStatus(
      isPremium: _purchaseService.isPremium,
      isBrand: _purchaseService.isBrand,
    );
  }

  void _onAppStateChanged() {
    _purchaseService.setPreferredLanguageCode(
      _appState.currentUser.languageCode,
    );
  }

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.addListener(_onAppStateChanged);
    // Build 254: 푸시 알림 탭 → 인박스 화면 이동.
    // Build 271: payload 에 'letter=<id>' 또는 'letterId=<id>' 가 있으면
    // AppState 에 보관 → 인박스 진입 후 해당 편지 자동 오픈.
    NotificationService.onNotificationTap = (payload) {
      try {
        if (payload != null && payload.isNotEmpty) {
          // 가장 단순한 파싱 — 'letter=xxx' 또는 'letterId=xxx' 추출.
          final m = RegExp(r'letter(?:Id)?[=:]([^&\s]+)').firstMatch(payload);
          if (m != null) {
            _appState.pendingDeepLinkLetterId = m.group(1);
          }
        }
        _navKey.currentState?.pushNamedAndRemoveUntil(
          '/home_inbox',
          (route) => false,
        );
      } catch (_) {
        // 네비게이터 미준비 또는 라우트 미존재 시 silent fail
      }
    };
    _purchaseService.setPreferredLanguageCode(
      _appState.currentUser.languageCode,
    );
    // 인앱 결제 초기화 후 AppState 프리미엄 상태 동기화
    // Build 305 (BLOCKER 후속): chain 중간 실패 시에도 최종 addListener 가
    // 도달하도록 catchError 보강. initialize 실패해도 listener 는 등록되어
    // 차후 재시도 / 사용자 manual restore 가 UI 에 반영되도록 함.
    _purchaseService.initialize().catchError((e) {
      assert(() {
        debugPrint('[main] PurchaseService.initialize 실패: $e');
        return true;
      }());
    }).then((_) async {
      if (!mounted) return;
      final userId = widget.initialUserData?['id'];
      final email = widget.initialUserData?['email'];
      try {
        await _purchaseService.syncUserIdentity(userId: userId, email: email);
        await _purchaseService.applyTestEmailOverride(email);
      } catch (e) {
        assert(() {
          debugPrint('[main] PurchaseService.syncUserIdentity 실패: $e');
          return true;
        }());
      }
      if (!mounted) return;
      _onPurchaseChanged();
      _purchaseService.addListener(_onPurchaseChanged);
    });
    if (widget.initialLoggedIn && widget.initialUserData != null) {
      // Build 272 (P1 글로벌화): country/countryFlag fallback 의 한국 기본값 제거.
      // initialUserData 에 값이 없을 케이스는 거의 없지만, 예외 시 system locale 미반영
      // → onboarding 에서 사용자가 명시적으로 선택하도록 빈 값으로 둔다.
      _appState.setUser(
        id: widget.initialUserData!['id'] ?? '',
        username: widget.initialUserData!['username'] ?? 'Traveler',
        country: widget.initialUserData!['country'] ?? '',
        countryFlag: widget.initialUserData!['countryFlag'] ?? '',
        languageCode: widget.initialUserData!['languageCode'],
        socialLink: widget.initialUserData!['socialLink']?.isNotEmpty == true
            ? widget.initialUserData!['socialLink']
            : null,
        phoneNumber: widget.initialUserData!['phoneNumber']?.isNotEmpty == true
            ? widget.initialUserData!['phoneNumber']
            : null,
        verifyMethod: widget.initialUserData!['verifyMethod'] ?? 'email',
        latitude: widget.initialLat,
        longitude: widget.initialLng,
      );
      // 이메일을 UserProfile에 저장 (이메일 기반 기능에 필요)
      final email = widget.initialUserData!['email'];
      if (email != null && email.isNotEmpty) {
        _appState.updateProfile(email: email);
      }
      // Build 302 (HIGH audit): Welcome trial cold-start 재시도 hook.
      // signup 시점에 Firestore 일시 장애로 trial 부여 실패한 사용자가 다음
      // cold-start 에서 다시 시도. tryClaimWelcomeTrial 자체가 server claim
      // 존재 시 skip 하므로 idempotent — 정상 사용자엔 영향 없음.
      if (email != null && email.isNotEmpty) {
        _appState.tryClaimWelcomeTrial(
          email: email,
          grant: () => _purchaseService.grantWelcomeTrial(days: 3),
        );
      }
    }
    // 저장된 데이터 복원 (편지함, 보낸 편지, 활동 점수, 차단 목록)
    _appState.loadFromPrefs();
    // 자주 사용하는 국가의 실제 주소 백그라운드 프리페치
    _prefetchPopularAddresses();
    // 시간대 변화 감지 타이머 (30초마다 체크, 시간대 변경 시 테마 갱신)
    _lastPeriod = _appState.activeTimePeriod;
    _themeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final period = _appState.activeTimePeriod;
      if (period != _lastPeriod) {
        _lastPeriod = period;
        if (mounted) setState(() {});
      }
    });
  }

  /// 인기 국가 실제 주소 백그라운드 프리페치 (Nominatim, 1 req/sec)
  void _prefetchPopularAddresses() {
    final geo = GeocodingService.instance;
    if (!geo.isInitialized) return;
    // 사용자 언어·위치 기반 상위 국가 우선, 나머지 주요 20개국
    const popular = [
      '대한민국', '일본', '미국', '프랑스', '영국', '독일',
      '이탈리아', '스페인', '브라질', '인도', '중국', '호주',
      '캐나다', '멕시코', '태국', '터키', '인도네시아', '베트남',
      '러시아', '아르헨티나',
    ];
    // 비동기로 실행 — UI 블로킹 없음
    geo.prefetchMultiple(popular, perCountry: 5);
  }

  @override
  void dispose() {
    _purchaseService.removeListener(_onPurchaseChanged);
    _appState.removeListener(_onAppStateChanged);
    _themeTimer?.cancel();
    _appState.dispose();
    super.dispose();
  }

  ThemeData _buildTheme(AppState state) {
    final timeTheme = TimeTheme.forPeriod(state.activeTimePeriod);
    final base = AppTheme.darkTheme;
    return base.copyWith(
      scaffoldBackgroundColor: timeTheme.bgDeep,
      colorScheme: base.colorScheme.copyWith(
        surface: timeTheme.bgCard,
        primary: timeTheme.accent,
      ),
      cardTheme: base.cardTheme.copyWith(color: timeTheme.bgCard),
      extensions: [
        AppTimeColors(
          bgDeep: timeTheme.bgDeep,
          bgCard: timeTheme.bgCard,
          bgSurface: timeTheme.bgSurface,
          accent: timeTheme.accent,
          periodEmoji: timeTheme.emoji,
          periodLabel: timeTheme.label,
          gradientTop: timeTheme.gradientTop,
          gradientMid: timeTheme.gradientMid,
          gradientBottom: timeTheme.gradientBottom,
        ),
      ],
    );
  }

  String _getInitialRoute() {
    // Allows controlled capture/testing flows via:
    // --dart-define=APP_INITIAL_ROUTE=/delivery_intro
    const forcedRoute = String.fromEnvironment(
      'APP_INITIAL_ROUTE',
      defaultValue: '',
    );
    if (forcedRoute.isNotEmpty) return forcedRoute;
    return '/splash';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appState),
        ChangeNotifierProvider.value(value: _purchaseService),
      ],
      child: Consumer<AppState>(
        builder: (context, state, _) {
          // 현재 사용자 언어 → Locale 변환 (언어 변경 즉시 반영 + RTL 자동 처리)
          final langCode = state.currentUser.languageCode.isNotEmpty
              ? state.currentUser.languageCode
              : 'en';
          final appLocale = Locale(langCode);
          final isRtl = LanguageConfig.isRtl(langCode);
          return MaterialApp(
            title: 'Thiscount',
            debugShowCheckedModeBanner: false,
            // Build 254: 푸시 알림 탭 시 라우팅용 키 (state 의 _navKey 와 연결)
            navigatorKey: _navKey,
            // Build 283 (light mode 인프라): dark/light 두 테마 모두 정의.
            // themeMode: dark 강제 — 모든 widget 이 dark 가정 hardcoded 인
            // 동안엔 light 활성 시 vision 깨질 가능성. widget 마이그레이션
            // (AppColors.* → context.palette.*) 80% 이후 ThemeMode.system 으로 전환.
            theme: AppTheme.lightTheme,
            darkTheme: _buildTheme(state),
            themeMode: ThemeMode.dark,
            locale: appLocale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko'), Locale('en'), Locale('ja'), Locale('zh'),
              Locale('fr'), Locale('de'), Locale('es'), Locale('pt'),
              Locale('ru'), Locale('tr'), Locale('ar'), Locale('it'),
              Locale('hi'), Locale('th'),
            ],
            // RTL 언어(아랍어 등) 자동 우→좌 방향 처리
            // Build 302 (MED audit): iOS 시스템 큰 글자 (Dynamic Type max)
            // 시 UI overflow 방지 — 1.3× 까지만 허용. 그 이상은 clamp.
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child,
                ),
              );
            },
            initialRoute: _getInitialRoute(),
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              // Build 284: 첫 진입 인포그래픽 투어 (수동 스크롤 + 페이지 indicator)
              OnboardingTourScreen.routeName: (_) =>
                  const OnboardingTourScreen(),
              // Build 284 (PR #20 wire): 관리자 특별 메시지 zone 생성
              '/admin_special_message': (_) =>
                  const AdminSpecialMessageScreen(),
              // Build 323: Brand 인사이트 대시보드
              BrandInsightsScreen.routeName: (_) =>
                  const BrandInsightsScreen(),
              // Build 321: '/brand_zone_setup' 제거 — compose 화면 통합.
              '/splash': (_) =>
                  SplashScreen(skipToAuth: !widget.initialLoggedIn),
              '/auth': (_) => const AuthScreen(),
              '/delivery_intro': (_) => const DeliveryIntroScreen(),
              '/home': (_) => const MainScaffold(),
              '/home_inbox': (_) => const MainScaffold(initialIndex: 1),
              '/home_tower': (_) => const MainScaffold(initialIndex: 2),
              '/home_profile': (_) => const MainScaffold(initialIndex: 3),
              '/compose': (_) => const ComposeScreen(),
              '/premium_welcome': (_) =>
                  const PremiumScreen(isWelcomeMode: true),
              '/v5_preview': (_) => const V5PreviewRoot(),
            },
          );
        },
      ),
    );
  }
}
