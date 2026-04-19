import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';

/// 편지의 "희소성"을 시각화하는 작은 카드.
/// - 이 편지를 읽은 사람 수 / 최대 수용 인원을 표시
/// - 남은 자리가 적을수록 강조 (orange → red)
///
/// 목표: "이 편지를 받은 사람은 전 세계에서 당신 외 몇 명뿐" 이라는
///       감정을 전달해 답장 동기 부여 + 공유 동기 증가.
class ScarcityIndicator extends StatelessWidget {
  final Letter letter;

  const ScarcityIndicator({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final readCount = letter.readCount;
    final maxReaders = letter.maxReaders;
    final remaining = (maxReaders - readCount).clamp(0, maxReaders);

    // readCount 가 0 인 경우 희귀 편지로 간주 — 특별 표시
    if (maxReaders <= 0) return const SizedBox.shrink();

    final langCode = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(langCode);

    // 꽉 찬 편지 (이 편지는 더 이상 다른 사람이 못 읽음)
    if (remaining <= 0) {
      return _buildCard(
        icon: Icons.lock_rounded,
        color: AppColors.textMuted,
        title: l10n.scarcityClosedTitle,
        subtitle: l10n.scarcityClosedSub,
      );
    }

    // 남은 자리가 1명: 마지막 수신자 감정
    if (remaining == 1) {
      return _buildCard(
        icon: Icons.hourglass_bottom_rounded,
        color: const Color(0xFFFF8A5C),
        title: l10n.scarcityLastReaderTitle,
        subtitle: l10n.scarcityLastReaderSub(readCount, maxReaders),
      );
    }

    // 일반 카운트 (2명 이상 남음)
    return _buildCard(
      icon: Icons.people_alt_rounded,
      color: AppColors.teal,
      title: l10n.scarcityCountTitle(readCount, maxReaders),
      subtitle: l10n.scarcityCountSub(remaining),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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
