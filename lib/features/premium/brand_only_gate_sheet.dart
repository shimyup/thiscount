import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Build 182: Brand 전용 기능(쿠폰·교환권·대량 발송·ExactDrop)을 Free/Premium
/// 유저가 탭했을 때 표시하는 안내 시트.
/// - Free 유저: "Brand 계정 전용" 설명 + Premium 이 아닌 Brand 가 필요함을 명시.
/// - Premium 유저: Premium 인데도 Premium 업그레이드 유도가 나오는 오류를 제거
///   ("이미 Premium 이에요, Brand 는 별도 광고주 계정입니다" 라고 정확히 안내).
///
/// PremiumGateSheet 과 분리된 이유: Brand 는 Premium 의 상위가 아니라 **다른
/// 트랙** (광고주 계정). 업그레이드 버튼으로는 Brand 가 될 수 없다.
class BrandOnlyGateSheet extends StatelessWidget {
  final String featureName;
  final String featureEmoji;
  final String description;
  final bool viewerIsPremium;

  const BrandOnlyGateSheet({
    super.key,
    required this.featureName,
    required this.featureEmoji,
    required this.description,
    required this.viewerIsPremium,
  });

  static Future<void> show(
    BuildContext context, {
    required String featureName,
    required String featureEmoji,
    required String description,
    required bool viewerIsPremium,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BrandOnlyGateSheet(
        featureName: featureName,
        featureEmoji: featureEmoji,
        description: description,
        viewerIsPremium: viewerIsPremium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppL10n.of(langCode);
    final orange = AppColors.coupon;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  orange.withValues(alpha: 0.25),
                  orange.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: orange.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(featureEmoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            featureName,
            style: TextStyle(
              color: orange,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),

          // Brand 전용임을 명시하는 배지 — Premium 상위 아님을 시각적으로 강조.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: orange.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              l10n.brandOnlyBadge,
              style: TextStyle(
                color: orange,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),

          // Premium 유저에게는 "이미 Premium 이고 Brand 는 다른 트랙" 명시.
          if (viewerIsPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.brandOnlyPremiumNote,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (viewerIsPremium) const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.brandOnlyAcknowledge,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
