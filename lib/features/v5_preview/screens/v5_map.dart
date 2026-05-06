import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_pin.dart';

class V5MapScreen extends StatefulWidget {
  final VoidCallback onCardTap;

  const V5MapScreen({super.key, required this.onCardTap});

  @override
  State<V5MapScreen> createState() => _V5MapScreenState();
}

class _V5MapScreenState extends State<V5MapScreen> {
  String _filter = '전체';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          // 지도 배경 — CustomPaint로 도로/그리드 흉내
          Positioned.fill(child: CustomPaint(painter: _MapBgPainter())),

          // 지역명 라벨
          const Positioned(
            top: 180,
            left: 30,
            child: _DistrictLabel(text: 'SEONGDONG-GU'),
          ),
          const Positioned(
            top: 280,
            right: 40,
            child: _DistrictLabel(text: 'GANGNAM-GU'),
          ),
          Positioned(
            top: 460,
            left: 80,
            child: const _DistrictLabel(text: 'YONGSAN-GU'),
          ),

          // 핀들
          Positioned(
            top: 220,
            left: 60,
            child: const V5Pin(category: V5Category.coupon),
          ),
          Positioned(
            top: 340,
            left: 160,
            child: const V5Pin(
              category: V5Category.coupon,
              selected: true,
            ),
          ),
          Positioned(
            top: 250,
            right: 70,
            child: const V5Pin(category: V5Category.letter),
          ),
          Positioned(
            top: 480,
            left: 110,
            child: const V5Pin(category: V5Category.coupon),
          ),
          Positioned(
            top: 470,
            right: 100,
            child: const V5Pin(category: V5Category.premium),
          ),
          Positioned(
            top: 200,
            right: 130,
            child: const V5ClusterPin(count: 4),
          ),
          Positioned(
            top: 380,
            left: 170,
            child: const V5UserPin(),
          ),

          // 상단 search + filter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _glassSearch()),
                        const SizedBox(width: 8),
                        _glassButton('◎'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('전체 12', V5Colors.coupon),
                          _filterChip('쿠폰 8', V5Colors.coupon),
                          _filterChip('혜택 3', V5Colors.letter),
                          _filterChip('만료임박', null),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 wallet sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomSheet(onCardTap: widget.onCardTap),
          ),
        ],
      ),
    );
  }

  Widget _glassSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: V5Colors.bg3.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: V5Colors.tx2, size: 16),
          const SizedBox(width: 10),
          Text(
            '어디서 줍고 싶어요?',
            style: V5Text.meta.copyWith(
              color: V5Colors.tx2,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(String icon) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: V5Colors.bg3.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: const Icon(Icons.my_location, color: V5Colors.tx, size: 18),
    );
  }

  Widget _filterChip(String label, Color? dotColor) {
    final on = label.startsWith(_filter);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = label.split(' ').first;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: on
                ? Colors.white.withValues(alpha: 0.95)
                : V5Colors.bg3.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? V5Colors.bg : V5Colors.tx,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistrictLabel extends StatelessWidget {
  final String text;
  const _DistrictLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0x4DFFFFFF),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _MapBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0DFFFFFF);
    // grid 40px
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // 사선 도로 (조금 굵게)
    final road = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(-50, size.height * 0.3),
      Offset(size.width + 50, size.height * 0.55),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, -50),
      Offset(size.width * 0.6, size.height + 50),
      road..color = const Color(0x10FFFFFF),
    );
    // 강 흉내
    final river = Paint()
      ..color = V5Colors.map.withValues(alpha: 0.06)
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.6),
      river,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomSheet extends StatelessWidget {
  final VoidCallback onCardTap;

  const _BottomSheet({required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        decoration: BoxDecoration(
          color: V5Colors.bg2.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            _sheetCard(
              category: V5Category.coupon,
              brand: 'Blue Bottle 성수',
              dist: '320 m',
              title: '1+1 아메리카노',
              sub: 'D-2 · 도보 4분',
              onTap: onCardTap,
            ),
            const SizedBox(height: 8),
            _sheetCard(
              category: V5Category.letter,
              brand: 'Tokyo · @harumi',
              dist: '1.2 km',
              title: '"오늘 시부야 비 와요"',
              sub: '2시간 전 도착',
              onTap: onCardTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetCard({
    required V5Category category,
    required String brand,
    required String dist,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    final ink = category.ink;
    return Material(
      color: category.bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          brand.toUpperCase(),
                          style: V5Text.brandLine.copyWith(
                            color: ink.withValues(alpha: 0.85),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            dist,
                            style: V5Text.brandLine.copyWith(
                              color: ink,
                              fontSize: 10,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ink,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
