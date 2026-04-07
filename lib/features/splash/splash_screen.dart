import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class SplashScreen extends StatefulWidget {
  final bool skipToAuth;
  const SplashScreen({super.key, this.skipToAuth = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo float + rotate
  late AnimationController _floatController;
  late Animation<double> _floatY;
  late Animation<double> _floatRotate;

  // Radar pulse
  late AnimationController _radarController;

  // Gold glow on logo
  late AnimationController _glowController;
  late Animation<double> _glowPulse;

  // Fade-in for text
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  // 슬로건 페이드 인
  late AnimationController _sloganFadeCtrl;
  late Animation<double> _sloganFade;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _radarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _floatY = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatRotate = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _glowPulse = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // 슬로건 페이드 컨트롤러
    _sloganFadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    )..forward();
    _sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sloganFadeCtrl, curve: Curves.easeInOut),
    );
    // Navigate after 3.5 s
    _navigationTimer = Timer(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_v2_complete') ?? false;
      if (!mounted) return;
      // DEBUG: 온보딩 미완료 시 자동 완료 처리 (테스트용)
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
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _radarController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    _sloganFadeCtrl.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.read<AppState>().currentUser.languageCode;
    final l = AppL10n.of(langCode);
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // ── 별빛 배경 ──────────────────────────────────────────────────────
          const _StarField(),
          // ── 하단 파도 ──────────────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _WaveBackground()),

          // ── 메인 콘텐츠 ────────────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _slideUp,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── 레이더 + 로고 ────────────────────────────────────────
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _floatController,
                        _radarController,
                        _glowController,
                      ]),
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatY.value),
                        child: Transform.rotate(
                          angle: _floatRotate.value,
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 레이더 파동
                                CustomPaint(
                                  size: const Size(220, 220),
                                  painter: _RadarPainter(
                                    _radarController.value,
                                  ),
                                ),
                                // 로고 카드
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(
                                          alpha: _glowPulse.value * 0.6,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 4,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: CustomPaint(
                                      size: const Size(130, 130),
                                      painter: _LetterGoLogoPainter(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── 앱 이름 "Letter Go" ──────────────────────────────────
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFE8D48B),
                          Color(0xFFD4A44B),
                          Color(0xFFB87333),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Letter Go',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          height: 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 슬로건 (현재 언어 + 영어) ────────────────────────────
                    FadeTransition(
                      opacity: _sloganFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.tagline,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.85,
                                ),
                                letterSpacing: 0.4,
                                height: 1.6,
                              ),
                            ),
                            if (langCode != 'en') ...[
                              const SizedBox(height: 4),
                              Text(
                                AppL10n.of('en').tagline,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.55,
                                  ),
                                  letterSpacing: 0.3,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 52),

                    // ── 로딩 도트 ────────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (_, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final offset = i / 3;
                          final val = (_radarController.value + offset) % 1.0;
                          final opacity = sin(val * pi).clamp(0.15, 1.0);
                          return AnimatedContainer(
                            duration: Duration.zero,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: opacity),
                            ),
                          );
                        }),
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

// ── 레이더 파동 페인터 ────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double value; // 0.0 → 1.0 (loop)

  const _RadarPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 3 offset waves, like the React Native version
    for (int i = 0; i < 3; i++) {
      final phase = (value + i / 3) % 1.0;
      final radius = phase * maxRadius;
      final opacity = (1.0 - phase) * 0.55;

      // Outer ring stroke
      final strokePaint = Paint()
        ..color = AppColors.gold.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, strokePaint);

      // Inner fill (very subtle)
      final fillPaint = Paint()
        ..color = AppColors.gold.withValues(alpha: opacity * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    // Center dot (user location marker — blue like RN version)
    final dotPaint = Paint()
      ..color = const Color(0xFF4A9EFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, dotPaint);
    // White ring around center dot
    final dotRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 6, dotRing);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.value != value;
}

// ── Letter Go 로고 페인터 ─────────────────────────────────────────────────────
// 흰 배경(외부 컨테이너)에 그리는 금빛 그라디언트 아이콘
class _LetterGoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gold gradient shader
    final goldShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4A44B), Color(0xFFE8C472), Color(0xFFB87333)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Rose gold shader for wave
    final roseShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4A44B), Color(0xFFB87060)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final strokeW = w * 0.055;
    final pad = w * 0.17;

    // ── Envelope rectangle ──────────────────────────────────────────────────
    final envPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final envLeft = pad;
    final envRight = w - pad;
    final envTop = h * 0.20;
    final envBottom = h * 0.76;

    // Rectangle
    final envPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(envLeft, envTop, envRight, envBottom),
          Radius.circular(w * 0.04),
        ),
      );
    canvas.drawPath(envPath, envPaint);

    // Envelope V flap (two lines from top corners meeting at center-ish)
    final flapPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final flapPath = Path()
      ..moveTo(envLeft + w * 0.02, envTop)
      ..lineTo(w / 2, h * 0.46)
      ..lineTo(envRight - w * 0.02, envTop);
    canvas.drawPath(flapPath, flapPaint);

    // ── Fish / wave curve flowing through the envelope ────────────────────
    final wavePaint = Paint()
      ..shader = roseShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final wavePath = Path()
      ..moveTo(pad * 0.4, h * 0.60)
      ..cubicTo(
        w * 0.28,
        h * 0.28,
        w * 0.55,
        h * 0.72,
        envRight + pad * 0.15,
        h * 0.38,
      );
    canvas.drawPath(wavePath, wavePaint);

    // ── Location pin at top-right corner of envelope ──────────────────────
    final pinX = envRight - w * 0.03;
    final pinY = envTop - h * 0.02;
    final pinR = w * 0.065;

    // Pin circle (filled)
    final pinFill = Paint()
      ..shader = roseShader
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pinX, pinY - pinR * 0.3), pinR, pinFill);

    // White hole in pin
    canvas.drawCircle(
      Offset(pinX, pinY - pinR * 0.3),
      pinR * 0.38,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Pin teardrop bottom
    final tearPath = Path()
      ..moveTo(pinX - pinR * 0.6, pinY - pinR * 0.3 + pinR * 0.6)
      ..quadraticBezierTo(
        pinX,
        pinY + pinR * 1.3,
        pinX + pinR * 0.6,
        pinY - pinR * 0.3 + pinR * 0.6,
      );
    canvas.drawPath(
      tearPath,
      Paint()
        ..shader = roseShader
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 별빛 배경 ─────────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> _positions;
  final List<double> _sizes;

  _StarPainter()
    : _positions = List.generate(90, (i) {
        final rng = Random(i * 17);
        return Offset(rng.nextDouble(), rng.nextDouble());
      }),
      _sizes = List.generate(90, (i) {
        final rng = Random(i * 31);
        return rng.nextDouble() * 2 + 0.4;
      });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < _positions.length; i++) {
      canvas.drawCircle(
        Offset(
          _positions[i].dx * size.width,
          _positions[i].dy * size.height * 0.72,
        ),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 파도 배경 ─────────────────────────────────────────────────────────────────
class _WaveBackground extends StatefulWidget {
  @override
  State<_WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<_WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 200),
        painter: _WavePainter(_ctrl.value),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFF0D1F3C).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final p2 = Paint()
      ..color = const Color(0xFF162A4A).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    _drawWave(canvas, size, p1, phase, 28, 62);
    _drawWave(canvas, size, p2, phase + 0.3, 18, 84);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    Paint paint,
    double ph,
    double amp,
    double yOff,
  ) {
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y =
          amp * sin((x / size.width * 2 * pi) + ph * 2 * pi) +
          size.height -
          yOff;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}
