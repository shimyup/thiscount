import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/brand_stamp.dart';
import '../../state/app_state.dart';

/// Build 453: 단골 스탬프 카드 가로 리스트 — 프로필(HuntWalletCard 아래) 노출.
///
/// "헌팅(신규)×스탬프(재방문)" 풀퍼널의 재방문 절반을 시각화: 매장별 스탬프
/// 진행도(●●●○○)와 완성 횟수. 카드가 없으면 위젯 자체를 렌더하지 않아
/// 기존 화면 밀도에 영향 없음.
class StampCardsRow extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const StampCardsRow({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final cards = state.stampCards;
        if (cards.isEmpty) return const SizedBox.shrink();
        final l10n = AppL10n.of(state.currentUser.languageCode);
        return Container(
          margin: margin ?? const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('☕', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.koEn('단골 스탬프', 'Loyalty stamps'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.koEn(
                        '같은 매장에서 쓸수록 보상이 쌓여요',
                        'Redeem at the same store to earn rewards',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _StampCardChip(card: cards[i], l10n: l10n),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StampCardChip extends StatelessWidget {
  final BrandStampCard card;
  final AppL10n l10n;
  const _StampCardChip({required this.card, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final remaining = card.rewardThreshold - card.stamps;
    return Container(
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: card.stamps > 0
              ? AppColors.gold.withValues(alpha: 0.45)
              : AppColors.bgSurface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (card.completedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🏆 ${card.completedCount}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 스탬프 도트 ●●●○○
          Row(
            children: List.generate(card.rewardThreshold, (i) {
              final filled = i < card.stamps;
              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppColors.gold.withValues(alpha: 0.9)
                        : AppColors.bgSurface,
                    border: Border.all(
                      color: filled
                          ? AppColors.gold
                          : AppColors.textMuted.withValues(alpha: 0.35),
                    ),
                  ),
                  child: filled
                      ? const Icon(Icons.check_rounded,
                          size: 11, color: AppColors.bgDeep)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.koEn('$remaining개 더 모으면 보상 🎁', '$remaining more to reward 🎁'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
