import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Selected country from page 0
  String _selectedCountry = '대한민국';
  String _selectedFlag = '🇰🇷';
  String _langCode = 'ko';

  // Location permission state
  bool _locationGranted = false;
  bool _locationChecking = false;

  AppL10n get _l => AppL10n.of(_langCode);

  // Build 140: intro 슬라이드를 4개 → 2개 로 축약. 새 티어 정체성을
  // (🎟 줍기 → 📸 홍보 → 🚀 시작) 3 단계로 간결 설명.
  static const int _totalPages =
      6; // page 0 = country, 1 = location, 2-4 = intro (🎟 📸 🚀), 5 = premium

  static const List<Map<String, String>> _popularCountries = [
    {'name': '대한민국', 'flag': '🇰🇷', 'lang': 'ko'},
    {'name': '日本', 'flag': '🇯🇵', 'lang': 'ja'},
    {'name': 'United States', 'flag': '🇺🇸', 'lang': 'en'},
    {'name': 'United Kingdom', 'flag': '🇬🇧', 'lang': 'en'},
    {'name': 'France', 'flag': '🇫🇷', 'lang': 'fr'},
    {'name': 'Deutschland', 'flag': '🇩🇪', 'lang': 'de'},
    {'name': 'Italia', 'flag': '🇮🇹', 'lang': 'it'},
    {'name': 'España', 'flag': '🇪🇸', 'lang': 'es'},
    {'name': 'Brasil', 'flag': '🇧🇷', 'lang': 'pt'},
    {'name': 'India', 'flag': '🇮🇳', 'lang': 'hi'},
    {'name': '中国', 'flag': '🇨🇳', 'lang': 'zh'},
    {'name': 'Australia', 'flag': '🇦🇺', 'lang': 'en'},
    {'name': 'Canada', 'flag': '🇨🇦', 'lang': 'en'},
    {'name': 'México', 'flag': '🇲🇽', 'lang': 'es'},
    {'name': 'Россия', 'flag': '🇷🇺', 'lang': 'ru'},
    {'name': 'Türkiye', 'flag': '🇹🇷', 'lang': 'tr'},
    {'name': 'مصر', 'flag': '🇪🇬', 'lang': 'ar'},
    {'name': 'South Africa', 'flag': '🇿🇦', 'lang': 'en'},
    {'name': 'ประเทศไทย', 'flag': '🇹🇭', 'lang': 'th'},
    {'name': 'Argentina', 'flag': '🇦🇷', 'lang': 'es'},
    {'name': 'Netherlands', 'flag': '🇳🇱', 'lang': 'en'},
    {'name': 'Sverige', 'flag': '🇸🇪', 'lang': 'en'},
    {'name': 'Norge', 'flag': '🇳🇴', 'lang': 'en'},
    {'name': 'Portugal', 'flag': '🇵🇹', 'lang': 'pt'},
    {'name': 'Indonesia', 'flag': '🇮🇩', 'lang': 'en'},
    {'name': 'Malaysia', 'flag': '🇲🇾', 'lang': 'en'},
    {'name': 'Singapore', 'flag': '🇸🇬', 'lang': 'en'},
    {'name': 'New Zealand', 'flag': '🇳🇿', 'lang': 'en'},
    {'name': 'Philippines', 'flag': '🇵🇭', 'lang': 'en'},
    {'name': 'Vietnam', 'flag': '🇻🇳', 'lang': 'en'},
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      if (mounted) setState(() => _locationGranted = true);
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _locationChecking = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (mounted) {
        setState(() {
          _locationGranted =
              permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
          _locationChecking = false;
        });
        // Build 285: 권한 허용 후 자동 페이지 넘김 제거.
        // 사용자가 "다음" 또는 swipe 로 직접 진행 — UX 일관성 확보.
      }
    } catch (_) {
      if (mounted) setState(() => _locationChecking = false);
    }
  }

  Future<void> _finish() async {
    // Map the displayed country name back to Korean for AppState compatibility
    final koreanName = _getKoreanName(_selectedCountry);
    await AuthService.saveOnboardingCountry(
      country: koreanName,
      countryFlag: _selectedFlag,
    );
    await AuthService.setOnboardingComplete();

    // 알림 권한 요청 (선택적 — 거부해도 진행 가능)
    // 먼저 커스텀 프리프롬프트로 "왜" 필요한지 설명 → 시스템 권한 팝업 →
    // 허용 시 매일 오전 8시 리마인더 자동 예약. 이 프리프롬프트 패턴은
    // 시스템 팝업에서 곧바로 거부되는 비율을 크게 낮춰준다.
    try {
      final wantsReminder = await _showReminderPrePrompt();
      if (wantsReminder) {
        final granted = await NotificationService.requestPermissions();
        if (granted) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('notify_daily_letter', true);
          await NotificationService.scheduleDailyLetterReminder(
            langCode: _langCode,
          );
        }
      }
    } catch (_) {}

    if (mounted) {
      // 이미 로그인 상태면 홈으로, 아니면 인증 화면으로
      final loggedIn = await AuthService.isLoggedIn();
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed(loggedIn ? '/home' : '/auth');
      }
    }
  }

  Future<bool> _showReminderPrePrompt() async {
    if (!mounted) return false;
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('☀️', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _l.reminderPrepromptTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _l.reminderPrepromptBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _l.reminderPrepromptLater,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l.reminderPrepromptYes),
          ),
        ],
      ),
    );
    return granted ?? false;
  }

  String _getKoreanName(String displayName) {
    // Map display names back to Korean names used in app
    const displayToKorean = {
      '대한민국': '대한민국',
      '日本': '일본',
      'United States': '미국',
      'United Kingdom': '영국',
      'France': '프랑스',
      'Deutschland': '독일',
      'Italia': '이탈리아',
      'España': '스페인',
      'Brasil': '브라질',
      'India': '인도',
      '中国': '중국',
      'Australia': '호주',
      'Canada': '캐나다',
      'México': '멕시코',
      'Россия': '러시아',
      'Türkiye': '터키',
      'مصر': '이집트',
      'South Africa': '남아프리카',
      'ประเทศไทย': '태국',
      'Argentina': '아르헨티나',
      'Netherlands': '네덜란드',
      'Sverige': '스웨덴',
      'Norge': '노르웨이',
      'Portugal': '포르투갈',
      'Indonesia': '인도네시아',
      'Malaysia': '말레이시아',
      'Singapore': '싱가포르',
      'New Zealand': '뉴질랜드',
      'Philippines': '필리핀',
      'Vietnam': '베트남',
    };
    return displayToKorean[displayName] ?? displayName;
  }

  void _nextPage() {
    // 페이지 1(위치 허용): 권한 미허가 시 먼저 요청, 이미 거부됐으면 건너뛰기 허용
    if (_currentPage == 1 && !_locationGranted) {
      _requestLocationPermission();
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  /// Build 166: 위치 권한 건너뛰기 전 강한 경고 모달.
  /// "GPS 미동의 시 편지 줍기·보내기 불가" 를 명시하고 유저가 명시적으로
  /// "제한 모드로 진행" 을 탭해야만 skip. App Store 가이드라인 준수 + 사용성
  /// 저하 방지 (빈 앱 경험).
  Future<void> _skipLocationPermission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _l.gpsSkipWarningTitle,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _l.gpsSkipWarningBody,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _l.gpsSkipBack,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _l.gpsSkipContinueLimited,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageCtrl,
            // Build 287: 스크롤(swipe) 로 한장씩 넘김 명시. 자동 timer 없음 —
            // 사용자가 손가락으로 슬라이드 또는 하단 "다음" 버튼으로 진행.
            physics: const PageScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Page 0: Country selection
              _CountrySelectionPage(
                selectedCountry: _selectedCountry,
                selectedFlag: _selectedFlag,
                countries: _popularCountries,
                l: _l,
                onCountrySelected: (name, flag, lang) {
                  setState(() {
                    _selectedCountry = name;
                    _selectedFlag = flag;
                    _langCode = lang;
                  });
                },
              ),
              // Page 1: Location permission (필수)
              _LocationPermissionPage(
                isGranted: _locationGranted,
                isChecking: _locationChecking,
                onRequest: _requestLocationPermission,
                langCode: _langCode,
              ),
              // Build 140: Intro 슬라이드 3개 — 새 3-티어 정체성을 한 흐름에
              // 전달.
              //   Page 2 (🎟) — 줍기 (Free 의 핵심 활동)
              //   Page 3 (📸) — 홍보 (Premium + Brand 의 가치 제안)
              //   Page 4 (🚀) — 시작
              // ✈️ 배송 메커니즘 + 🎁 혜택 설명은 "픽업하면 알아서 보인다"
              // 로 inline 교육으로 위임 — 온보딩은 짧게.
              _IntroPage(
                emoji: '🎟',
                title: _l.onboarding3Title,
                body: _l.onboarding3Body,
                gradient: const [AppColors.bgDeep, AppColors.bgCard],
                // Build 186: 줍기는 모든 티어 가능 — "Free + Premium + Brand".
                tiers: [
                  _TierBadge(_l.tierLabelFree, AppColors.teal),
                  _TierBadge(_l.tierLabelPremium, AppColors.gold),
                  _TierBadge(_l.tierLabelBrand, AppColors.coupon),
                ],
              ),
              _IntroPage(
                // Build 140: 기존 onboarding4 (🎁 benefits) 슬롯 재활용, 카피
                // 는 Premium/Brand 의 홍보 편지 발송 가치 제안으로 리프레임.
                emoji: '📸',
                title: _l.onboarding4Title,
                body: _l.onboarding4Body,
                gradient: const [AppColors.bgDeep, AppColors.bgCard],
                // Build 186: 편지 뿌리기는 Premium + Brand 만. Free 배제를
                // 시각적으로 명시해 gate 시 혼선 예방.
                tiers: [
                  _TierBadge(_l.tierLabelPremium, AppColors.gold),
                  _TierBadge(_l.tierLabelBrand, AppColors.coupon),
                ],
              ),
              _IntroPage(
                emoji: '🚀',
                title: _l.onboarding5Title,
                body: _l.onboarding5Body,
                gradient: const [AppColors.bgDeep, AppColors.bgCard],
              ),
              // Page 5: Premium 소개
              _PremiumPage(l: _l),
            ],
          ),
          // Top skip button (only show after page 0)
          if (_currentPage > 0)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _currentPage < _totalPages - 1
                      ? TextButton(
                          onPressed: _currentPage == 1
                              ? _skipLocationPermission
                              : _finish,
                          child: Text(
                            _l.skip,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          // Bottom nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // v5 progress bar — 가는 막대
                    Row(
                      children: List.generate(_totalPages, (i) {
                        final isActive = i <= _currentPage;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.only(
                              right: i < _totalPages - 1 ? 4 : 0,
                            ),
                            height: 3,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // v5 CTA — 흰색 pill
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _currentPage == 1 && !_locationGranted
                              ? (_locationChecking
                                    ? _l.checking
                                    : _l.locationAllow)
                              : _currentPage < _totalPages - 1
                              ? _l.next
                              : _l.getStarted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.bgDeep,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage == 1 &&
                        !_locationGranted &&
                        !_locationChecking)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: TextButton(
                          onPressed: _skipLocationPermission,
                          child: Text(
                            _l.skip,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySelectionPage extends StatefulWidget {
  final String selectedCountry;
  final String selectedFlag;
  final List<Map<String, String>> countries;
  final AppL10n l;
  final void Function(String name, String flag, String lang) onCountrySelected;

  const _CountrySelectionPage({
    required this.selectedCountry,
    required this.selectedFlag,
    required this.countries,
    required this.l,
    required this.onCountrySelected,
  });

  @override
  State<_CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<_CountrySelectionPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.countries
        .where((c) => c['name']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.l.onboardingCountryTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.l.onboardingCountrySubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.l.onboardingSearchCountry,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isSelected = widget.selectedFlag == c['flag'];
                    return GestureDetector(
                      onTap: () => widget.onCountrySelected(
                        c['name']!,
                        c['flag']!,
                        c['lang']!,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              c['flag']!,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                c['name']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.bgDeep
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Text(
                              LanguageConfig.languageNames[c['lang']] ??
                                  c['lang']!,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.bgDeep.withValues(alpha: 0.55)
                                    : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 위치 허용 페이지 ──────────────────────────────────────────────────────────
class _LocationPermissionPage extends StatelessWidget {
  final bool isGranted;
  final bool isChecking;
  final VoidCallback onRequest;
  final String langCode;

  const _LocationPermissionPage({
    required this.isGranted,
    required this.isChecking,
    required this.onRequest,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(langCode);
    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // 큰 라인 아이콘
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isGranted ? AppColors.letter : AppColors.bgCard,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted ? Icons.check_rounded : Icons.location_on_outlined,
                  size: 32,
                  color: isGranted
                      ? const Color(0xFF0A1A00)
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                isGranted ? l.locationGranted : l.locationRequired,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isGranted ? l.locationGrantedBody : l.locationRequiredBody,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.15,
                ),
              ),
              if (!isGranted && !isChecking) ...[
                const SizedBox(height: 22),
                // GPS 약관 박스 — v5 클린
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.gpsTermsHeader.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.66,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.gpsTermsBody,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onRequest,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l.gpsAgreeAndContinue,
                      style: const TextStyle(
                        color: AppColors.bgDeep,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
              if (isChecking)
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Premium 소개 페이지 ──────────────────────────────────────────────────────
class _PremiumPage extends StatelessWidget {
  final AppL10n l;
  const _PremiumPage({required this.l});

  @override
  Widget build(BuildContext context) {
    // 무료 기능
    final freeFeatures = [
      l.onboardingFreeFeat1,
      l.onboardingFreeFeat2,
      l.onboardingFreeFeat3,
      l.onboardingFreeFeat4,
    ];

    // Build 119: 픽업-퍼스트 리오더. 반경 📍 → 쿨다운 ⏱ → 발송 묶음 ✈️ →
    // 꾸미기 묶음 🎨 순서로 페이월(premium_screen) 과 통일.
    final premiumFeatures = [
      {
        'emoji': '📍',
        'text': l.onboardingPremiumFeat1,
        'color': const Color(0xFFFF6B9D),
      },
      {'emoji': '⏱', 'text': l.onboardingPremiumFeat2, 'color': AppColors.teal},
      {
        'emoji': '✈️',
        'text': l.onboardingPremiumFeat3,
        'color': AppColors.gold,
      },
      {
        'emoji': '🎨',
        'text': l.onboardingPremiumFeat4,
        'color': AppColors.coupon,
      },
    ];
    final socialProofReviews = [l.onboardingReview1, l.onboardingReview2];

    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.labelThiscountPremium.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.66,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.onboardingPremiumTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.onboardingPremiumSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 28),

              // ── 플랜 비교 카드 ──
              Row(
                children: [
                  // 무료 플랜
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.tierFree,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '₩0',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...freeFeatures.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 프리미엄 플랜
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.15),
                            AppColors.gold.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l.tierPremium,
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.tierBest,
                                  style: TextStyle(
                                    color: AppColors.bgDeep,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: '₩4,900',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: l.onboardingPerMonth,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...premiumFeatures.map((f) {
                            final color = f['color'] as Color;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    f['emoji'] as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f['text'] as String,
                                      style: TextStyle(
                                        color: color.withValues(alpha: 0.9),
                                        fontSize: 11,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 간단 사용법 (Build 257: "하루 타임라인" 대체) ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 ${l.onboardingHowToTitle}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final entry in [
                      {'n': '1', 'text': l.onboardingHowToStep1},
                      {'n': '2', 'text': l.onboardingHowToStep2},
                      {'n': '3', 'text': l.onboardingHowToStep3},
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                entry['n']!,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  entry['text']!,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(
                      color: AppColors.textMuted,
                      height: 16,
                      thickness: 0.3,
                    ),
                    ...socialProofReviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $review',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 안내 문구 ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.onboardingFreeStartHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final List<Color> gradient;
  // Build 186: 티어 뱃지 칩 (선택). 해당 슬라이드가 어느 tier 에게 적용되는지
  // 한 눈에 표현. 예: 🎟 줍기 = [Free, Premium, Brand] / 📸 홍보 = [Premium, Brand].
  // null 이면 렌더 안 함 (기존 동작).
  final List<_TierBadge>? tiers;

  const _IntroPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
    this.tiers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              if (tiers != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tiers!.map((t) => _tierChip(t)).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.15,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierChip(_TierBadge t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        t.label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF1A0008),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Build 186: 온보딩 슬라이드에서 "이 기능은 어느 티어용?" 를 시각 표현.
class _TierBadge {
  final String label;
  final Color color;
  const _TierBadge(this.label, this.color);
}
