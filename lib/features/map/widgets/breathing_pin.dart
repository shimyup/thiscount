// Build 283: 지도 사용자 위치 핀 — 1.6s 사이클로 호흡 (scale + blur).
// 픽업 가능 거리 (100m) 진입 시 [active] true → ripple ring 1회 + 햅틱.
//
// 사용 의도: world_map_screen 의 사용자 marker 교체. 정적 dot 대신 살아있는
// 듯한 효과로 "지금 여기" 감각 강화.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreathingPin extends StatefulWidget {
  final Color color;
  final double size;
  final bool active;

  /// Active 진입 시 자동으로 햅틱 발화. 외부에서 끄려면 false.
  final bool hapticOnActivate;

  const BreathingPin({
    super.key,
    required this.color,
    this.size = 24,
    this.active = false,
    this.hapticOnActivate = true,
  });

  @override
  State<BreathingPin> createState() => _BreathingPinState();
}

class _BreathingPinState extends State<BreathingPin>
    with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(BreathingPin old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _pulse.forward(from: 0);
      if (widget.hapticOnActivate) {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _pulse]),
      builder: (_, __) {
        final breathT = Curves.easeInOut.transform(_breath.value);
        final blur = 16.0 + 12.0 * breathT;
        final alpha = 0.25 + 0.20 * breathT;

        final pulseT = Curves.easeOutBack.transform(_pulse.value);
        final scale = 1.0 + 0.18 * pulseT * (1 - _pulse.value);
        final ringR = widget.size * (1.5 + 2.5 * _pulse.value);
        final ringA = (1 - _pulse.value) * 0.7;

        return SizedBox(
          width: widget.size * 4,
          height: widget.size * 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_pulse.isAnimating || _pulse.value > 0)
                Container(
                  width: ringR * 2,
                  height: ringR * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(ringA),
                      width: 2,
                    ),
                  ),
                ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(alpha),
                        blurRadius: blur,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
