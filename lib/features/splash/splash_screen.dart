import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// v5 Wallet 디자인. 검정 배경 + 큰 brand wordmark + 1.8s 자동 이동.
/// Debug 모드에서 우상단 'v5 preview' 칩 노출.
class SplashScreen extends StatefulWidget {
  final bool skipToAuth;
  const SplashScreen({super.key, this.skipToAuth = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinner;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _spinner = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Build 293: splash 시간 단축 (1800ms → 1200ms). 사용자가 splash 가 너무
    // 길게 노출돼 "온보딩 자동 진행" 으로 오인하는 케이스 완화.
    _navigationTimer = Timer(const Duration(milliseconds: 1200), _go);
  }

  Future<void> _go() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    // Build 313: 모든 기존 사용자에게 1회만 온보딩 강제 재진입.
    // 이전 빌드 (294~) 에서 markSeen 된 사용자가 새 온보딩 콘텐츠 (Build 287
    // 수동 스크롤 / Build 301 베타 체크박스 / Build 311 콘텐츠 갱신) 를 보지
    // 못한 채로 잔존. 이 marker 가 false 면 1회 reset → true 로 저장 → 다음부터
    // 정상 markSeen 흐름.
    const _kForceResetMarker = 'onboarding_force_reset_v313';
    final alreadyForceReset = prefs.getBool(_kForceResetMarker) ?? false;
    if (!alreadyForceReset) {
      await prefs.setBool('onboarding_v2_complete', false);
      await prefs.setBool('seen_onboarding_tour', false);
      await prefs.setBool(_kForceResetMarker, true);
    }
    final onboardingDone = prefs.getBool('onboarding_v2_complete') ?? false;
    if (!mounted) return;

    if (!onboardingDone && kDebugMode) {
      await prefs.setBool('onboarding_v2_complete', true);
      Navigator.of(context).pushReplacementNamed('/auth');
      return;
    }
    if (!onboardingDone) {
      // Build 284: 첫 방문 → 인포그래픽 투어 → 기존 onboarding 으로.
      // SharedPreferences `seen_onboarding_tour` 가 true 면 투어 건너뜀.
      // Build 298 (P0 i18n audit): tour 콘텐츠가 한국어 only — 비-ko 단말은
      // 자동 skip 처리 후 markSeen 까지 호출해 한글 화면 노출 차단.
      var seenTour = prefs.getBool('seen_onboarding_tour') ?? false;
      if (!seenTour) {
        final locale = WidgetsBinding.instance.platformDispatcher.locale;
        if (locale.languageCode.toLowerCase() != 'ko') {
          await prefs.setBool('seen_onboarding_tour', true);
          seenTour = true;
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        seenTour ? '/onboarding' : '/onboarding_tour',
      );
    } else if (widget.skipToAuth) {
      Navigator.of(context).pushReplacementNamed('/auth');
    } else {
      Navigator.of(context).pushReplacementNamed('/delivery_intro');
    }
  }

  @override
  void dispose() {
    _spinner.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Build 220+: 워드마크 letter·go. → thiscount.
                  // 한 단어이지만 끝에 점(.) 으로 짧은 명령형 톤 유지.
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 0.96,
                        letterSpacing: -3.8,
                      ),
                      children: [
                        TextSpan(text: 'thiscount'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.top,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4, top: 14),
                            child: _Dot(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (ctx) {
                      final lang = ctx
                          .read<AppState>()
                          .currentUser
                          .languageCode;
                      return Text(
                        AppL10n.of(lang.isEmpty ? 'en' : lang).splashSub,
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          letterSpacing: -0.15,
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _spinner,
                    builder: (_, __) => Transform.rotate(
                      angle: _spinner.value * 6.283,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bgSurface,
                            width: 2,
                          ),
                        ),
                        child: CustomPaint(painter: _ArcPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'v 5.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'THISCOUNT.IO',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Debug 진입
            if (kDebugMode)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    _navigationTimer?.cancel();
                    Navigator.of(context).pushNamed('/v5_preview');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.premium.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.premium.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'v5',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.premium,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.premium,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Offset.zero & size, -1.57, 1.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
