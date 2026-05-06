import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_dev_bar.dart';

class V5SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final void Function(String) onDevJump;

  const V5SplashScreen({
    super.key,
    required this.onContinue,
    required this.onDevJump,
  });

  @override
  State<V5SplashScreen> createState() => _V5SplashScreenState();
}

class _V5SplashScreenState extends State<V5SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: Column(
        children: [
          V5DevBar(current: 'splash', onJump: widget.onDevJump),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Build 263: 옛 "letter.go." 워드마크 → "Thiscount" 정리.
                    const Text(
                      'Thiscount',
                      style: TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w800,
                        color: V5Colors.tx,
                        height: 0.92,
                        letterSpacing: -5.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '근처에 떠있는 쿠폰과 편지를\n주워 쓰는 지갑.',
                      style: V5Text.body.copyWith(
                        color: V5Colors.tx2,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => Transform.rotate(
                        angle: _controller.value * 6.283,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: V5Colors.bg3,
                              width: 2,
                            ),
                          ),
                          child: CustomPaint(painter: _ArcPainter()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'v 5.0',
                          style: V5Text.meta.copyWith(
                            color: V5Colors.tx3,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'SEOUL · 04.27 19:24',
                          style: V5Text.meta.copyWith(
                            color: V5Colors.tx3,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: V5Colors.premium,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = V5Colors.tx
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Offset.zero & size,
      -1.57,
      1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
