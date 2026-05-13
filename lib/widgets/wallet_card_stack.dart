// Build 283: 인박스 WalletCard stack — 카드가 종이처럼 살짝 겹쳐 떠있는 느낌.
// 카테고리 색의 띠 1면 + 본문 검정 비율 1:4 (Apple Wallet 비율).
// `AnimatedPositioned` 가 카드 재정렬 시 spring 모션으로 부드럽게.
//
// 사용 의도: inbox_screen 의 ListView 를 점진 교체. 현재 ad-hoc tile 들의
// 시각 일관성 + 카드 정체성 강화.

import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';

enum WalletCategory { coupon, reward, premium, map, streak }

extension _CatColors on WalletCategory {
  Color bar(AppPalette p) => switch (this) {
        WalletCategory.coupon => p.coupon,
        WalletCategory.reward => p.reward,
        WalletCategory.premium => p.premium,
        WalletCategory.map => p.map,
        WalletCategory.streak => p.streak,
      };
  Color ink(AppPalette p) => switch (this) {
        WalletCategory.coupon => p.couponInk,
        WalletCategory.reward => p.rewardInk,
        WalletCategory.premium => p.premiumInk,
        WalletCategory.map => Colors.white,
        WalletCategory.streak => Colors.white,
      };
}

class WalletCardData {
  final String title;
  final String brand;
  final String code;
  final String deadline;
  final WalletCategory category;
  final bool expiringSoon;
  const WalletCardData({
    required this.title,
    required this.brand,
    required this.code,
    required this.deadline,
    required this.category,
    this.expiringSoon = false,
  });
}

class WalletCardStack extends StatelessWidget {
  final List<WalletCardData> cards;
  final void Function(WalletCardData)? onTap;
  final double cardHeight;
  final double peekOffset;

  const WalletCardStack({
    super.key,
    required this.cards,
    this.onTap,
    this.cardHeight = 220,
    this.peekOffset = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final stackHeight = cardHeight + (cards.length - 1) * peekOffset;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        children: List.generate(cards.length, (i) {
          final reversed = cards.length - 1 - i;
          final c = cards[reversed];
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            top: i * peekOffset,
            left: 16,
            right: 16,
            child: _WalletCardTile(
              data: c,
              onTap: onTap,
              height: cardHeight,
            ),
          );
        }),
      ),
    );
  }
}

class _WalletCardTile extends StatelessWidget {
  final WalletCardData data;
  final void Function(WalletCardData)? onTap;
  final double height;
  const _WalletCardTile({
    required this.data,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cat = data.category;
    final inkColor = cat.ink(p);

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(data),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: p.bgCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 12)),
            BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
          border: data.expiringSoon
              ? Border.all(color: p.premium, width: 1.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 컬러 band (높이 1/5)
              Container(
                height: 44,
                color: cat.bar(p),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        color: inkColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (data.expiringSoon)
                      Text(
                        data.deadline,
                        style: TextStyle(
                          color: inkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
              // 본문 (검정 4/5)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.brand,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data.code,
                        style: TextStyle(
                          fontFamily: 'Menlo',
                          fontSize: 12,
                          color: p.textSecondary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
