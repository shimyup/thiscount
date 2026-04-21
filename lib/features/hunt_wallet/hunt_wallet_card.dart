import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// "나의 헌트 기록" 카드 — Build 115 에서 신규.
///
/// 프로필 화면 상단에 "이번 달 얼마나 벌었나?" 감각을 만드는 핵심 지표 4개.
/// 경쟁 앱(배민 쿠폰함 등) 이 이미 보여주는 "누적 사용량 가시화" 가 Letter Go
/// 에선 빠져 있던 리텐션 공백을 채운다. 금액 환산은 안 한다 — 브랜드마다
/// 실제 할인 금액이 달라 거짓 환산은 오해만 늘림. 대신 "픽업/사용" 숫자 자체
/// 에 집중.
class HuntWalletCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const HuntWalletCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final monthPickups = state.pickupsThisMonth;
        final monthRedeemed = state.redemptionsThisMonth;
        final totalPickups = state.totalBrandPickups;
        final totalRedeemed = state.totalRedemptions;
        final isEmpty = totalPickups == 0 && totalRedeemed == 0;

        return Container(
          margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal.withValues(alpha: 0.14),
                AppColors.gold.withValues(alpha: 0.08),
                AppColors.bgCard,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.huntWalletTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isEmpty)
                Text(
                  l10n.huntWalletEmpty,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                )
              else ...[
                Row(
                  children: [
                    _statCell(
                      emoji: '📩',
                      value: '$monthPickups',
                      label: l10n.huntWalletPickupsMonth,
                      accent: AppColors.teal,
                    ),
                    _divider(),
                    _statCell(
                      emoji: '🎫',
                      value: '$monthRedeemed',
                      label: l10n.huntWalletRedeemedMonth,
                      accent: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStatCell(
                      value: '$totalPickups',
                      label: l10n.huntWalletTotalPickups,
                    ),
                    const SizedBox(width: 18),
                    _miniStatCell(
                      value: '$totalRedeemed',
                      label: l10n.huntWalletTotalRedemptions,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statCell({
    required String emoji,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCell({required String value, required String label}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 46,
        color: AppColors.textMuted.withValues(alpha: 0.2),
      );
}
