import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Premium is sold as a single SKU via RevenueCat — this widget does NOT
/// change that. It just reframes the Premium screen's pitch from a flat
/// feature list into 3 themed "collections". The underlying benefits
/// (image letters, unlimited express, priority delivery) are the same;
/// the framing turns them into something a user can want emotionally,
/// not just accept functionally.
class PremiumCollectionsPreview extends StatelessWidget {
  const PremiumCollectionsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    final collections = <_Collection>[
      _Collection(
        emoji: '🌌',
        name: l.premiumCollectionAuroraName,
        tagline: l.premiumCollectionAuroraTagline,
        bullets: [
          l.premiumCollectionAuroraBullet1,
          l.premiumCollectionAuroraBullet2,
        ],
        accent: const Color(0xFF8AB4FF),
      ),
      _Collection(
        emoji: '🌾',
        name: l.premiumCollectionHarvestName,
        tagline: l.premiumCollectionHarvestTagline,
        bullets: [
          l.premiumCollectionHarvestBullet1,
          l.premiumCollectionHarvestBullet2,
        ],
        accent: const Color(0xFFFFB95E),
      ),
      _Collection(
        emoji: '💌',
        name: l.premiumCollectionPostmasterName,
        tagline: l.premiumCollectionPostmasterTagline,
        bullets: [
          l.premiumCollectionPostmasterBullet1,
          l.premiumCollectionPostmasterBullet2,
        ],
        accent: AppColors.gold,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.premiumCollectionsHeader,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.premiumCollectionsSub,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < collections.length; i++) ...[
          _CollectionCard(collection: collections[i]),
          if (i < collections.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Collection {
  final String emoji;
  final String name;
  final String tagline;
  final List<String> bullets;
  final Color accent;

  const _Collection({
    required this.emoji,
    required this.name,
    required this.tagline,
    required this.bullets,
    required this.accent,
  });
}

class _CollectionCard extends StatelessWidget {
  final _Collection collection;
  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: collection.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: collection.accent.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(collection.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: TextStyle(
                    color: collection.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  collection.tagline,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                for (final b in collection.bullets)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('·  ',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            )),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
