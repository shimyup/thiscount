import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/feedback_service.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'user_level.dart';

/// 레벨업 이벤트 감지 시 1회 표시되는 축하 스낵바.
///
/// 사용: 주요 화면의 initState / postFrameCallback 에서
/// `LevelUpBanner.showIfLevelUp(context)` 호출.
class LevelUpBanner {
  static void showIfLevelUp(BuildContext context) {
    final state = context.read<AppState>();
    final newLevel = state.consumeLevelUpFlag();
    if (newLevel == null) return;
    if (newLevel == UserLevel.newbie) return; // newbie 는 축하 생략

    // Build 182: 레벨업 순간 chime + heavy haptic.
    FeedbackService.onLevelUp();

    final l10n = AppL10n.of(state.currentUser.languageCode);
    final welcome = _localizedWelcome(l10n, newLevel);
    // Build 120: 레벨업 순간 실제 "반경 확대" 를 함께 보여준다. 배너 본문에
    // 한 줄 추가. XP 레벨 기반 픽업 반경이 +10m 단위로 올라가므로 델타는
    // 고정 10m, 신규 값은 pickupRadiusMeters 를 정수로 반올림.
    final isBrand = state.currentUser.isBrand;
    final newRadius = state.pickupRadiusMeters.round();
    final radiusLine = isBrand ? null : l10n.levelUpRadiusDelta(10, newRadius);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.levelUpBannerTitle,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    welcome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (radiusLine != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      radiusLine,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1F2D44),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static String _localizedWelcome(AppL10n l10n, UserLevel level) {
    switch (level) {
      case UserLevel.newbie:
        return l10n.userLevelNewbieWelcome;
      case UserLevel.beginner:
        return l10n.userLevelBeginnerWelcome;
      case UserLevel.casual:
        return l10n.userLevelCasualWelcome;
      case UserLevel.regular:
        return l10n.userLevelRegularWelcome;
      case UserLevel.experienced:
        return l10n.userLevelExperiencedWelcome;
    }
  }
}
