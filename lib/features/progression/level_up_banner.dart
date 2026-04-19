import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
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

    final l10n = AppL10n.of(state.currentUser.languageCode);
    final welcome = _localizedWelcome(l10n, newLevel);

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
                      color: Color(0xFFF0C35A),
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
            color: const Color(0xFFF0C35A).withValues(alpha: 0.4),
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
