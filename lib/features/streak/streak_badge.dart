import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// 현재 연속 접속 일수를 보여주는 작은 뱃지.
/// 홈 상단 / 프로필 / 타워 등 여러 곳에서 재사용.
///
/// 디자인 톤:
/// - 🔥 이모지 + 일수 숫자
/// - 골드 컬러 배경 (Letter Go 주요 액센트)
/// - tight padding · 작은 사이즈 → 시선 방해 최소
class StreakBadge extends StatelessWidget {
  final bool compact;

  const StreakBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final streak = state.currentStreak;
        if (streak <= 0) return const SizedBox.shrink();

        return Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
              SizedBox(width: compact ? 3 : 5),
              Text(
                '$streak일',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 스트릭 증가 시 1회 표시되는 축하 스낵바 헬퍼.
class StreakCelebrationBar {
  static void showIfIncreased(BuildContext context) {
    final state = context.read<AppState>();
    if (!state.consumeStreakIncreaseFlag()) return;
    if (state.currentStreak <= 1) return; // 1일째는 너무 흔해 생략

    final message = _milestoneMessage(state.currentStreak);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔥 ', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
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

  static String _milestoneMessage(int streak) {
    switch (streak) {
      case 3:
        return '3일 연속 접속! 습관이 시작되고 있어요';
      case 7:
        return '7일 연속 접속! 일주일을 채웠어요 ✨';
      case 14:
        return '14일 연속 접속! 편지가 익숙해졌어요';
      case 30:
        return '30일 연속 접속! 한 달의 여정 🌟';
      case 100:
        return '100일 연속 접속! 전설의 편지꾼 🏆';
      default:
        return '$streak일 연속 접속! 계속 이어가요';
    }
  }
}
