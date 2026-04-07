import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class DeliveryIntroScreen extends StatefulWidget {
  const DeliveryIntroScreen({super.key});

  @override
  State<DeliveryIntroScreen> createState() => _DeliveryIntroScreenState();
}

class _DeliveryIntroScreenState extends State<DeliveryIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _nextTimer;
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _nextTimer = Timer(const Duration(milliseconds: 4200), _goHome);
  }

  void _goHome() {
    if (!mounted || _moved) return;
    _moved = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l = AppL10n.of(langCode);
    final en = AppL10n.of('en');
    final showEn = langCode != 'en';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF081426), Color(0xFF0A1B31), Color(0xFF10243D)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _SoftParticles()),
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goHome,
                  child: Text(
                    l.skip,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.deliveryIntroTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (showEn) ...[
                      const SizedBox(height: 4),
                      Text(
                        en.deliveryIntroTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      l.deliveryIntroSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.95),
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    if (showEn) ...[
                      const SizedBox(height: 3),
                      Text(
                        en.deliveryIntroSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xCC111B2B),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _TravelPathPainter(_controller.value),
                              child: _MovingEmojis(progress: _controller.value),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _LoadingDots(),
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

class _MovingEmojis extends StatelessWidget {
  final double progress;
  const _MovingEmojis({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        Offset travel({
          required double t,
          required double y,
          double amp = 0,
          double phase = 0,
        }) {
          final x = -32 + (w + 64) * t;
          final wave = amp * math.sin((t + phase) * 2 * math.pi);
          return Offset(x, y + wave);
        }

        final carT = progress;
        final planeT = (progress + 0.18) % 1;
        final shipT = (progress + 0.38) % 1;

        final car = travel(t: carT, y: h * 0.74, amp: 6, phase: 0.1);
        final plane = travel(t: planeT, y: h * 0.28, amp: 16, phase: 0.25);
        final ship = travel(t: shipT, y: h * 0.55, amp: 10, phase: 0.5);
        final letter = travel(t: (progress + 0.06) % 1, y: h * 0.47, amp: 4);

        return Stack(
          children: [
            Positioned(
              left: car.dx,
              top: car.dy,
              child: const Text('🚗', style: TextStyle(fontSize: 30)),
            ),
            Positioned(
              left: plane.dx,
              top: plane.dy,
              child: const Text('✈️', style: TextStyle(fontSize: 30)),
            ),
            Positioned(
              left: ship.dx,
              top: ship.dy,
              child: const Text('🚢', style: TextStyle(fontSize: 30)),
            ),
            Positioned(
              left: letter.dx,
              top: letter.dy,
              child: const Text('💌', style: TextStyle(fontSize: 24)),
            ),
          ],
        );
      },
    );
  }
}

class _TravelPathPainter extends CustomPainter {
  final double progress;
  const _TravelPathPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final glowPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final pulseX = (size.width - 16) * progress + 8;
    canvas.drawCircle(Offset(pulseX, size.height * 0.5), 22, glowPaint);

    final upper = Path()
      ..moveTo(8, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.12,
        size.width * 0.68,
        size.height * 0.30,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.40,
        size.width - 10,
        size.height * 0.28,
      );

    final middle = Path()
      ..moveTo(8, size.height * 0.54)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.42,
        size.width * 0.52,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.70,
        size.width - 10,
        size.height * 0.58,
      );

    final lower = Path()
      ..moveTo(8, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.88,
        size.width * 0.45,
        size.height * 0.76,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.58,
        size.width - 10,
        size.height * 0.78,
      );

    _drawDashedPath(canvas, upper, linePaint);
    _drawDashedPath(canvas, middle, linePaint);
    _drawDashedPath(canvas, lower, linePaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      const step = 12.0;
      const dash = 6.0;
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += step;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TravelPathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SoftParticles extends StatelessWidget {
  const _SoftParticles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          _spot(28, 90, 5),
          _spot(74, 160, 4),
          _spot(44, 250, 7),
          _spot(82, 320, 5),
          _spot(14, 390, 4),
        ],
      ),
    );
  }

  Widget _spot(double xFactor, double y, double radius) {
    return FractionallySizedBox(
      alignment: Alignment(-1 + (xFactor / 50), -1 + (y / 450)),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final tick = (_controller.value * 3).floor() + 1;
          final dots = '.' * tick;
          return Text(
            dots,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          );
        },
      ),
    );
  }
}
