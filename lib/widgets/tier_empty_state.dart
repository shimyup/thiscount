import 'package:flutter/material.dart';

import '../core/auth/tier_gate.dart';
import '../core/theme/app_theme.dart';

/// Build 403 (PR-LL6): 통합 empty state 위젯.
///
/// 배경: inbox / tower / brand / settings 각 화면이 자체 empty state 를
/// 가지며 Free/Premium/Brand 별로 메시지·CTA·스타일이 분기됐다. 화면당
/// 3종 변형 × 5+ 화면 → 인지 일관성 무너지고 유지보수 비용 증가.
///
/// 이 위젯 1개로 통일:
/// - emoji + title + subtitle 은 화면 컨텍스트만 받음
/// - tier 별 CTA 는 [TierEmptyState.tierAware] convenience constructor
///   가 [tier] 에 따라 적절한 액션 라벨 + onTap 분기
///
/// 기존 `_EmptyState` (inbox_screen 내부) 의 외관을 그대로 옮겨와 시각
/// 회귀 없이 다른 화면도 함께 채택 가능하도록 한다.
class TierEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  /// 단일 CTA — tier 무관한 액션. (예: "지도로 이동")
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCtaTap;

  const TierEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.ctaIcon,
    this.onCtaTap,
  });

  /// tier 별로 다른 CTA 표시. callsite 는 콜백 3개를 미리 준비하고
  /// 위젯이 현재 tier 에 맞는 1개만 노출.
  ///
  /// 예 — 인박스 empty:
  /// ```dart
  /// TierEmptyState.tierAware(
  ///   emoji: '✉️',
  ///   title: '아직 받은 쿠폰이 없어요',
  ///   subtitle: '근처에서 픽업해보세요',
  ///   tier: TierGate.currentTier(user: u, purchase: p),
  ///   onFreePickup: () => Navigator.pushNamed(ctx, '/map'),
  ///   onPremiumStorage: () => Navigator.pushNamed(ctx, '/inbox/saved'),
  ///   onBrandCompose: () => Navigator.pushNamed(ctx, '/compose'),
  /// )
  /// ```
  factory TierEmptyState.tierAware({
    Key? key,
    required String emoji,
    required String title,
    required String subtitle,
    required TierLevel tier,
    String? freeLabel,
    VoidCallback? onFreePickup,
    String? premiumLabel,
    VoidCallback? onPremiumStorage,
    String? brandLabel,
    VoidCallback? onBrandCompose,
  }) {
    String? label;
    IconData? icon;
    VoidCallback? tap;
    switch (tier) {
      case TierLevel.free:
        label = freeLabel;
        icon = Icons.location_on_outlined;
        tap = onFreePickup;
        break;
      case TierLevel.premium:
        label = premiumLabel;
        icon = Icons.bookmark_outline_rounded;
        tap = onPremiumStorage;
        break;
      case TierLevel.brand:
        label = brandLabel;
        icon = Icons.edit_outlined;
        tap = onBrandCompose;
        break;
    }
    return TierEmptyState(
      key: key,
      emoji: emoji,
      title: title,
      subtitle: subtitle,
      ctaLabel: label,
      ctaIcon: icon,
      onCtaTap: tap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCtaTap,
                icon: Icon(ctaIcon ?? Icons.edit_outlined, size: 18),
                label: Text(ctaLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
