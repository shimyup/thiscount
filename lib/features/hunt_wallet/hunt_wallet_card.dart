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
                // Build 120: 줍기 반경 진행바 — 현재 반경이 내 티어 최대의
                // 몇 % 인지 시각화. Free 는 하단에 "Premium 전환 시 5× 즉시
                // 확대" 골드 CTA 추가. 레벨 올릴수록 바가 차오름.
                const SizedBox(height: 16),
                _buildRadiusBar(l10n, state),
                // Build 121: 헌터 아이템 슬롯 — 타워 층 은유를 대체하는
                // "주워 모은 장비" 시각화. 마일스톤 레벨 5곳에 각각 이모지
                // 아이템 (🎯 🧭 🗺 🎒 👑). 획득=풀컬러, 미획득=회색 + 잠금 힌트.
                if (!state.currentUser.isBrand) ...[
                  const SizedBox(height: 16),
                  _buildHunterItems(l10n, state),
                  // Build 125: 동행 동물 6슬롯 (🐕 🐈 🦊 🦉 🐉 🦄).
                  const SizedBox(height: 14),
                  _buildCompanionsRow(l10n, state),
                  // Build 125: 악세사리 6슬롯 (🎩 🕶 🎀 💎 🌈 ⭐).
                  const SizedBox(height: 14),
                  _buildAccessoriesRow(l10n, state),
                ],
                // Build 116: 주간 퀘스트 진행 — Pokémon GO Field Research 류
                // 데일리/위클리 목표의 헌트 버전. 5통 목표 달성 시 체크 메시지.
                const SizedBox(height: 16),
                _buildWeeklyQuest(l10n, state),
                // Build 116: 팔로우 중인 브랜드 카운트 (0이면 숨김).
                if (state.followedBrandIds.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.huntWalletFollowing(state.followedBrandIds.length),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

  /// Build 120: 줍기 반경 진행 바. 현재 반경 / 내 티어의 Lv50 최대 반경.
  /// Free: 690m 기준 (200 + 49*10), Premium: 1490m (1000 + 49*10).
  /// 0→100% 를 teal/gold 그라디언트 로 시각화. Free 일 땐 하단에 "Premium
  /// 전환 시 5× 즉시 확대" 골드 CTA 삽입.
  Widget _buildRadiusBar(AppL10n l10n, AppState state) {
    final isBrand = state.currentUser.isBrand;
    final isPremium = state.currentUser.isPremium;
    final current = state.pickupRadiusMeters.round();
    // 티어별 최대 (Lv 50 도달 시)
    final tierMax = isBrand ? 1000 : (isPremium ? 1490 : 690);
    final pct = (current / tierMax).clamp(0.0, 1.0);
    final accent = isBrand
        ? AppColors.coupon
        : (isPremium ? AppColors.gold : AppColors.teal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.huntWalletRadiusTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.huntWalletRadiusValue(current, tierMax),
              style: TextStyle(
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        // Free 계정만 업그레이드 CTA 노출 — Premium·Brand 은 불필요.
        if (!isPremium && !isBrand) ...[
          const SizedBox(height: 6),
          Text(
            l10n.huntWalletRadiusUpgradeCta,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  /// Build 125: 동행 동물 6슬롯 (Lv 3/8/18/28/38/48). 획득 시 풀컬러, 미획득
  /// 시 회색 + 🔒 + "Lv N 해금" 툴팁. 타워의 "내 건물" 은유가 아니라 "함께
  /// 걷는 레터" 감각 부여.
  Widget _buildCompanionsRow(AppL10n l10n, AppState state) {
    final levels = AppState.letterCompanionLevels;
    final earned = state.earnedCompanionLevels.toSet();
    return _buildIconSlotRow(
      title: l10n.letterCompanionsTitle,
      levels: levels,
      earned: earned,
      emojiForLevel: AppState.letterCompanionEmoji,
      lockedHint: l10n.hunterItemLockedHint,
    );
  }

  /// Build 125: 악세사리 6슬롯 (Lv 4/12/20/30/40/50). 머리 위에 착용되는
  /// 꾸미기 요소. 해금 규칙·렌더링은 동행과 동일.
  Widget _buildAccessoriesRow(AppL10n l10n, AppState state) {
    final levels = AppState.letterAccessoryLevels;
    final earned = state.earnedAccessoryLevels.toSet();
    return _buildIconSlotRow(
      title: l10n.letterAccessoriesTitle,
      levels: levels,
      earned: earned,
      emojiForLevel: AppState.letterAccessoryEmoji,
      lockedHint: l10n.hunterItemLockedHint,
    );
  }

  /// 공통 슬롯 줄 렌더러 — 아이템·동행·악세사리 3군데가 같은 레이아웃을
  /// 공유. `_HunterItemSlot` 재사용.
  Widget _buildIconSlotRow({
    required String title,
    required List<int> levels,
    required Set<int> earned,
    required String? Function(int) emojiForLevel,
    required String Function(int) lockedHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final level in levels)
              Tooltip(
                message:
                    earned.contains(level) ? 'Lv $level' : lockedHint(level),
                child: _HunterItemSlot(
                  emoji: emojiForLevel(level) ?? '❓',
                  level: level,
                  isEarned: earned.contains(level),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Build 121: 헌터 아이템 줄 — 5개 마일스톤(Lv 2/5/10/25/50) 슬롯.
  /// 획득: 풀컬러 큰 이모지 · 미획득: 회색 + 작은 자물쇠 + "Lv N 해금" 툴팁.
  /// 타워의 "층" 대신 "주워 모은 장비" 메타포로 전환.
  Widget _buildHunterItems(AppL10n l10n, AppState state) {
    final milestones = AppState.hunterMilestoneLevels;
    final earned = state.earnedHunterItemLevels.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hunterItemsTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final level in milestones)
              Tooltip(
                message: earned.contains(level)
                    ? 'Lv $level'
                    : l10n.hunterItemLockedHint(level),
                child: _HunterItemSlot(
                  emoji: AppState.hunterItemEmoji(level) ?? '❓',
                  level: level,
                  isEarned: earned.contains(level),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyQuest(AppL10n l10n, AppState state) {
    final current = state.pickupsThisWeek;
    final goal = state.weeklyQuestGoal;
    final isDone = current >= goal;
    final pct = isDone ? 1.0 : current / goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDone
              ? l10n.huntWalletWeeklyGoalDone
              : l10n.huntWalletWeeklyGoal(current, goal),
          style: TextStyle(
            color: isDone ? AppColors.gold : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? AppColors.gold : AppColors.teal,
            ),
          ),
        ),
      ],
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

/// Build 121: 헌터 아이템 슬롯 한 칸. 획득 시 풀컬러 + 큰 이모지, 미획득 시
/// 회색 + 작은 자물쇠 + 필요 레벨 라벨.
class _HunterItemSlot extends StatelessWidget {
  final String emoji;
  final int level;
  final bool isEarned;

  const _HunterItemSlot({
    required this.emoji,
    required this.level,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    // Build 125: 너비 54 → 48 로 축소. 6슬롯 행(동행·악세사리) 이 소형
    // 화면(iPhone SE, 375px) 에서도 overflow 없이 들어가도록.
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      decoration: BoxDecoration(
        color: isEarned
            ? AppColors.gold.withValues(alpha: 0.12)
            : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEarned
              ? AppColors.gold.withValues(alpha: 0.55)
              : AppColors.textMuted.withValues(alpha: 0.18),
          width: isEarned ? 1.3 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isEarned ? 1.0 : 0.35,
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: isEarned ? 24 : 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEarned ? 'Lv $level' : '🔒',
            style: TextStyle(
              color: isEarned ? AppColors.gold : AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
