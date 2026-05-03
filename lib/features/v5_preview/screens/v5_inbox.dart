import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_wallet_card.dart';

class V5InboxScreen extends StatefulWidget {
  final VoidCallback onCardTap;

  const V5InboxScreen({super.key, required this.onCardTap});

  @override
  State<V5InboxScreen> createState() => _V5InboxScreenState();
}

class _V5InboxScreenState extends State<V5InboxScreen> {
  String _tab = '전체';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // 헤더
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '지갑',
                    style: V5Text.display.copyWith(fontSize: 34),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 12),
                  child: Text(
                    '12개',
                    style: V5Text.meta.copyWith(
                      color: V5Colors.tx2,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: V5Colors.bg3,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: V5Colors.tx,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 탭 칩
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _tabChip('전체', '12'),
                  _tabChip('쿠폰', '8'),
                  _tabChip('혜택', '3'),
                  _tabChip('만료', null),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('오늘 도착', '2개'),
            const SizedBox(height: 8),
            V5WalletCard(
              category: V5Category.coupon,
              brand: 'Blue Bottle 성수',
              title: '1+1 아메리카노',
              sub: '서울 성동구 · 320 m',
              deadline: 'D-2',
              urgent: true,
              stampsTotal: 10,
              stampsFilled: 5,
              onTap: widget.onCardTap,
            ),
            const SizedBox(height: 10),
            V5WalletCard(
              category: V5Category.letter,
              brand: 'Tokyo · @harumi',
              title: '"오늘 시부야 비 와요"',
              sub: '개인 편지 · 1.2 km',
              deadline: '2H',
              onTap: widget.onCardTap,
            ),
            const SizedBox(height: 22),
            _sectionLabel('이번 주', '4개'),
            const SizedBox(height: 8),
            V5WalletCard(
              category: V5Category.coupon,
              brand: 'CGV 강남',
              title: '주말 영화 30%',
              sub: '주말 1관 한정 · 1.8 km',
              deadline: 'D-9',
              onTap: widget.onCardTap,
            ),
            const SizedBox(height: 10),
            V5WalletCard(
              category: V5Category.coupon,
              brand: 'Paris Baguette 종로',
              title: '크루아상 무료',
              sub: '1만원 이상 구매 시 · 0.6 km',
              deadline: 'D-5',
              onTap: widget.onCardTap,
            ),
            const SizedBox(height: 10),
            V5WalletCard(
              category: V5Category.premium,
              brand: 'Air Mail Pass',
              title: 'Premium',
              sub: '@shimyup · seq 0421',
              deadline: '∞',
              onTap: widget.onCardTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, String? num) {
    final on = label == _tab;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _tab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? V5Colors.tx : V5Colors.bg3,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: on ? V5Colors.bg : V5Colors.tx2,
                  letterSpacing: -0.1,
                ),
              ),
              if (num != null) ...[
                const SizedBox(width: 6),
                Text(
                  num,
                  style: TextStyle(
                    fontSize: 11,
                    color: on ? V5Colors.tx3 : V5Colors.tx3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: V5Text.sectionLabel),
          Text(
            count,
            style: V5Text.meta.copyWith(
              color: V5Colors.tx3,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
