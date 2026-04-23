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
        if (_locationGranted) {
          // 자동으로 다음 페이지
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) _nextPage();
        }
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
      } else {
        // 거부해도 앱 전반의 알림 권한은 요청해 둔다 (편지 도착 알림 등)
        await NotificationService.requestPermissions();
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
                gradient: const [Color(0xFF0F1A30), Color(0xFF1A2A50)],
              ),
              _IntroPage(
                // Build 140: 기존 onboarding4 (🎁 benefits) 슬롯 재활용, 카피
                // 는 Premium/Brand 의 홍보 편지 발송 가치 제안으로 리프레임.
                emoji: '📸',
                title: _l.onboarding4Title,
                body: _l.onboarding4Body,
                gradient: const [Color(0xFF15102A), Color(0xFF2A1A50)],
              ),
              _IntroPage(
                emoji: '🚀',
                title: _l.onboarding5Title,
                body: _l.onboarding5Body,
                gradient: const [Color(0xFF0A1628), Color(0xFF162040)],
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
                          onPressed: _finish,
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
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.gold
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.bgDeep,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentPage == 1 && !_locationGranted
                              ? (_locationChecking
                                    ? _l.checking
                                    : '📍 ${_l.locationAllow}')
                              : _currentPage < _totalPages - 1
                              ? _l.next
                              : _l.getStarted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // 위치 권한 페이지: "나중에" 스킵 버튼 (앱스토어 가이드라인)
                    if (_currentPage == 1 && !_locationGranted && !_locationChecking)
                      TextButton(
                        onPressed: _skipLocationPermission,
                        child: Text(
                          _l.skip,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF070B14), Color(0xFF0D1F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                widget.l.onboardingCountryTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.l.onboardingCountrySubtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Search field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F2D44)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.l.onboardingSearchCountry,
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isSelected = widget.selectedFlag == c['flag'];
                    return InkWell(
                      onTap: () => widget.onCountrySelected(
                        c['name']!,
                        c['flag']!,
                        c['lang']!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.bgCard.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              c['flag']!,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                c['name']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              LanguageConfig.languageNames[c['lang']] ??
                                  c['lang']!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.gold,
                                size: 18,
                              ),
                            ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF060C18), Color(0xFF0A1A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 160),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isGranted ? AppColors.teal : AppColors.gold)
                      .withValues(alpha: 0.1),
                  border: Border.all(
                    color: (isGranted ? AppColors.teal : AppColors.gold)
                        .withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isGranted ? '✅' : '📍',
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                isGranted ? l.locationGranted : l.locationRequired,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isGranted ? AppColors.teal : AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isGranted ? l.locationGrantedBody : l.locationRequiredBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              if (!isGranted && !isChecking) ...[
                const SizedBox(height: 24),
                // Build 166: GPS 필수 동의 — 약관·제한사항 명시 박스.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.privacy_tip_rounded,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l.gpsTermsHeader,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.gpsTermsBody,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onRequest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.bgDeep,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.gpsAgreeAndContinue,
                          style: const TextStyle(
                            color: AppColors.bgDeep,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (isChecking)
                // Build 160: AppLoading.medium — 기존 CircularProgressIndicator
                // 직접 정의 → 캐노니컬 토큰.
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                ),
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
    const gradient = [Color(0xFF0B0618), Color(0xFF1A0B2E)];

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
      {'emoji': '✈️', 'text': l.onboardingPremiumFeat3, 'color': AppColors.gold},
      {'emoji': '🎨', 'text': l.onboardingPremiumFeat4, 'color': const Color(0xFFFF8A5C)},
    ];
    final dayTimeline = [
      {
        'emoji': '🌅',
        'time': l.onboardingTimelineMorning,
        'free': l.onboardingTimelineMorningFree,
        'premium': l.onboardingTimelineMorningPremium,
      },
      {
        'emoji': '🌊',
        'time': l.onboardingTimelineAfternoon,
        'free': l.onboardingTimelineAfternoonFree,
        'premium': l.onboardingTimelineAfternoonPremium,
      },
      {
        'emoji': '🌙',
        'time': l.onboardingTimelineEvening,
        'free': l.onboardingTimelineEveningFree,
        'premium': l.onboardingTimelineEveningBrand,
      },
    ];
    final socialProofReviews = [
      l.onboardingReview1,
      l.onboardingReview2,
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 ──
              Center(
                child: Column(
                  children: [
                    // 왕관 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.25),
                            AppColors.gold.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('👑', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.labelLetterGoPremium,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.onboardingPremiumTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.onboardingPremiumSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
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

              // ── 하루 타임라인: 무료 vs 프리미엄/브랜드 ──
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
                      '✨ ${l.onboardingTimelineTitle}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dayTimeline.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['emoji']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['time']!,
                                  style: TextStyle(
                                    color: AppColors.gold.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['free']!,
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.textMuted.withValues(alpha: 0.4),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '→ ${item['premium']!}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(color: AppColors.textMuted, height: 16, thickness: 0.3),
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

  const _IntroPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 160),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgCard.withValues(alpha: 0.5),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
