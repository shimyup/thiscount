import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_dev_bar.dart';

class V5DetailScreen extends StatelessWidget {
  final VoidCallback onBack;
  final void Function(String) onDevJump;

  const V5DetailScreen({
    super.key,
    required this.onBack,
    required this.onDevJump,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: Column(
        children: [
          V5DevBar(current: 'detail', onJump: onDevJump),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleBtn(Icons.arrow_back, onBack),
                        _circleBtn(Icons.more_horiz, () {}),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailCard(),
                    const SizedBox(height: 14),
                    _messageBox(),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: V5Colors.tx,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '바로 사용하기',
                                style: V5Text.button.copyWith(
                                  color: V5Colors.bg,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: V5Colors.bg3,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: V5Colors.tx,
                              size: 18,
                            ),
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

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: V5Colors.bg3,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: V5Colors.tx, size: 18),
      ),
    );
  }

  Widget _detailCard() {
    const ink = V5Colors.couponInk;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: V5Colors.coupon,
        borderRadius: BorderRadius.circular(V5Radius.cardLg),
        boxShadow: V5Shadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BLUE BOTTLE 성수',
            style: V5Text.brandLine.copyWith(
              color: ink.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '1+1\n아메리카노',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -1.3,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '서울 성동구 성수이로 3길 8 · 320m',
            style: V5Text.meta.copyWith(
              color: ink.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          // stamps 5/10
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) {
              final on = i < 5;
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: on ? ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: on
                      ? null
                      : Border.all(
                          color: ink.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ink.withValues(alpha: 0.18), width: 1),
              ),
            ),
            child: Row(
              children: [
                _meta(label: '유효기간', value: 'D-2', ink: ink),
                _meta(label: '픽업일', value: '04 · 27', ink: ink),
                _meta(label: '위치코드', value: 'A-12', ink: ink),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xEBFFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: _BarcodeImage(),
                      repeat: ImageRepeat.repeatX,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomPaint(painter: _BarcodePainter()),
                ),
                const SizedBox(height: 8),
                Text(
                  'LG · 7K2A · 0421',
                  style: V5Text.mono.copyWith(
                    color: ink,
                    fontSize: 12,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta({
    required String label,
    required String value,
    required Color ink,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: V5Colors.bg2,
        borderRadius: BorderRadius.circular(V5Radius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: V5Colors.coupon,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: V5Colors.couponInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '@bluebottle_seongsu',
                style: V5Text.meta.copyWith(
                  color: V5Colors.tx2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '성수에 새 카페 오픈했어요. 첫 잔은 제가 살게요.',
            style: V5Text.body.copyWith(
              color: V5Colors.tx,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 빈 ImageProvider — DecorationImage 자리 채움 (실제 그리지 않음)
class _BarcodeImage extends ImageProvider<Object> {
  const _BarcodeImage();
  @override
  Future<Object> obtainKey(ImageConfiguration configuration) async => this;
  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    throw UnimplementedError();
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = V5Colors.couponInk;
    final widths = [2.0, 1.0, 2.0, 4.0, 1.0, 3.0, 2.0, 1.0, 2.0, 1.5];
    final gaps = [2.0, 3.0, 4.0, 3.0, 4.0, 3.0, 3.0, 4.0, 3.0, 2.5];
    double x = 0;
    int i = 0;
    while (x < size.width) {
      final w = widths[i % widths.length];
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + gaps[i % gaps.length];
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
