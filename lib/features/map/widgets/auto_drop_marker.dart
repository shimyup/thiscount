// Build 284 (Phase 3 — D 단계): 자동 드롭 letter 의 지도 marker.
//
// Brand auto-drop (또는 관리자 특별 메시지) 로 자동 생성된 letter (즉
// `letter.brandZoneId != null`) 는 지도에서 일반 letter 와 시각적으로
// 차별화. brand gold #FFD60A 핀 + % 디자인 (PR #13 의 Icon A-refined 가
// 앱 아이콘에선 폐기됐지만 brand zone marker 로 살아남음).
//
// PNG asset: assets/branding/auto_drop_pin.png (1024×1024, ImageCache 가
// marker 사이즈로 자동 다운샘플).
//
// 사용:
//   ```dart
//   if (letter.brandZoneId != null)
//     AutoDropMarker(size: 32)
//   else
//     <기존 일반 letter marker>
//   ```

import 'package:flutter/material.dart';

class AutoDropMarker extends StatelessWidget {
  /// Pin 의 실제 그려질 크기 (보통 28-40).
  final double size;

  /// 호흡 효과 사용 여부. 자동 드롭은 "이게 자동" 임을 강조하기 위해 켜는 게
  /// 자연스럽지만, 너무 많은 marker 동시 호흡은 산만함 → 기본 off.
  final bool breathing;

  /// pin 아래 그림자 강도.
  final double shadowOpacity;

  const AutoDropMarker({
    super.key,
    this.size = 32,
    this.breathing = false,
    this.shadowOpacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final pin = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD60A).withOpacity(shadowOpacity),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/branding/auto_drop_pin.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          // PNG 가 없을 시 fallback — gold solid + % 텍스트
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFD60A),
            ),
            alignment: Alignment.center,
            child: Text(
              '%',
              style: TextStyle(
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1300),
              ),
            ),
          ),
        ),
      ),
    );

    if (!breathing) return pin;

    return _Breathing(child: pin);
  }
}

class _Breathing extends StatefulWidget {
  final Widget child;
  const _Breathing({required this.child});
  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = 1.0 + 0.06 * t;
        return Transform.scale(scale: scale, child: widget.child);
      },
    );
  }
}
