import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// 이번 주 챌린지 진행 상황을 보여주는 카드.
/// 프로필·타워 화면 등에 배치. 달성 여부에 따라 톤이 변화.
///
/// 디자인:
/// - 미달성: 진행 바 + "X/3개국" 표시
/// - 달성·미수령: 골드 강조 + "보상 받기" CTA
/// - 달성·수령완료: 체크 아이콘 + 다음 주 안내
class WeeklyChallengeCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const WeeklyChallengeCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final progress = state.weeklyChallengeProgress;
        final goal = state.weeklyChallengeGoal;
        final achieved = state.weeklyChallengeAchieved;
        final rewardPending = state.weeklyChallengeRewardPending;
        final l10n = AppL10n.of(state.currentUser.languageCode);

        final Color accent = rewardPending
            ? AppColors.gold
            : (achieved ? AppColors.teal : AppColors.textMuted);

        return Container(
          margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    rewardPending ? '🎁' : '🗺️',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rewardPending
                          ? l10n.weeklyChallengeRewardPendingTitle
                          : (achieved
                              ? l10n.weeklyChallengeAchievedTitle
                              : l10n.weeklyChallengeTitle),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (rewardPending)
                    ElevatedButton(
                      onPressed: () {
                        final wk = state.claimWeeklyChallengeReward();
                        if (wk != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text('🎁 ', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.weeklyChallengeClaimToast,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF1F2D44),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      child: Text(l10n.weeklyChallengeClaimButton),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.weeklyChallengeDescription(goal),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              // 진행바
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (progress / goal).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    l10n.weeklyChallengeProgress(progress, goal),
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (achieved && !rewardPending)
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.teal, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          l10n.weeklyChallengeClaimed,
                          style: TextStyle(
                            color: AppColors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else if (!achieved)
                    Text(
                      l10n.weeklyChallengeRemaining(goal - progress),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
