import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'premium_screen.dart';

/// 유료 기능 접근 시 나타나는 업그레이드 바텀시트
class PremiumGateSheet extends StatelessWidget {
  final String featureName;
  final String featureEmoji;
  final String description;

  const PremiumGateSheet({
    super.key,
    required this.featureName,
    required this.featureEmoji,
    required this.description,
  });

  /// 간편 호출 메서드
  static Future<void> show(
    BuildContext context, {
    required String featureName,
    required String featureEmoji,
    required String description,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PremiumGateSheet(
        featureName: featureName,
        featureEmoji: featureEmoji,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 아이콘
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.25),
                  AppColors.gold.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(featureEmoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),

          // 제목
          Text(
            featureName,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // 설명
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Build 150: 가격 카드 전면 개편 — 두 줄 구성으로 가치 제안 명확화.
          // 1) 큰 글씨 가격 ("₩4,900 / 월")
          // 2) 안심 문구 ("언제든 해지 · 광고 없음")
          // 기존 작은 뱃지는 한 줄이라 눈에 잘 안 띈다는 페르소나 4 지적 반영.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.18),
                  AppColors.gold.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.premiumGatePriceLabel,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.premiumGateAssurance,
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 업그레이드 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.premiumGateStartBtn,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.premiumLater,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
