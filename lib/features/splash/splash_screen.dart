import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

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

    _navigationTimer = Timer(const Duration(milliseconds: 1800), _go);
  }

  Future<void> _go() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_v2_complete') ?? false;
    if (!mounted) return;

    if (!onboardingDone && kDebugMode) {
      await prefs.setBool('onboarding_v2_complete', true);
      Navigator.of(context).pushReplacementNamed('/auth');
      return;
    }
    if (!onboardingDone) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 0.92,
                        letterSpacing: -5.2,
                      ),
                      children: [
                        TextSpan(text: 'letter'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.top,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4, top: 16),
                            child: _Dot(),
                          ),
                        ),
                        TextSpan(text: '\ngo.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '근처에 떠있는 쿠폰과 편지를\n주워 쓰는 지갑.',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      letterSpacing: -0.15,
                    ),
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
                        'GLOBAL POSTAL CO.',
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
