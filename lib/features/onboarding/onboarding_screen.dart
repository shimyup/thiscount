import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_config.dart';
import '../../core/services/auth_service.dart';

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

  static const int _totalPages =
      7; // page 0 = country, 1 = location, 2-5 = intro, 6 = coming soon

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
    // 페이지 1(위치 허용)에서 아직 허가 안됐으면 막기
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
              // Pages 2-5: Intro slides
              _IntroPage(
                emoji: '✈️',
                title: _l.onboarding2Title,
                body: _l.onboarding2Body,
                gradient: const [Color(0xFF0A1628), Color(0xFF0D2040)],
              ),
              _IntroPage(
                emoji: '📬',
                title: _l.onboarding3Title,
                body: _l.onboarding3Body,
                gradient: const [Color(0xFF0F1A30), Color(0xFF1A2A50)],
              ),
              _IntroPage(
                emoji: '🌗',
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
              // Page 6: Premium 소개
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
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onRequest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.locationAllow,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (isChecking)
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

    // 프리미엄 전용 기능 (실제 한도와 동일하게 유지)
    final premiumFeatures = [
      {
        'emoji': '✉️',
        'text': l.onboardingPremiumFeat1,
        'color': const Color(0xFFFF6B9D),
      },
      {'emoji': '📸', 'text': l.onboardingPremiumFeat2, 'color': AppColors.teal},
      {'emoji': '⚡', 'text': l.onboardingPremiumFeat3, 'color': AppColors.gold},
      {'emoji': '🗼', 'text': l.onboardingPremiumFeat4, 'color': const Color(0xFFFF8A5C)},
    ];
    final socialProofStats = [
      {'label': l.onboardingStatActiveUsers, 'value': '42K+'},
      {'label': l.onboardingStatTotalLetters, 'value': '128K+'},
      {'label': l.onboardingStatCountries, 'value': l.onboardingStatCountriesValue},
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
                    const Text(
                      'LETTER GO PREMIUM',
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
                          const Text(
                            'FREE',
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
                              const Text(
                                'PREMIUM',
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
                                child: const Text(
                                  'BEST',
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

              // ── 사회적 증거 ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌍 ${l.onboardingLiveStats}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: socialProofStats
                          .map(
                            (stat) => Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    stat['value']!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stat['label']!,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
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
