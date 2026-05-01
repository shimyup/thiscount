import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../state/app_state.dart';
import '../features/map/screens/world_map_screen.dart';
import '../features/compose/screens/compose_screen.dart';
import '../features/premium/premium_gate_sheet.dart';
import '../features/inbox/screens/inbox_screen.dart';
import '../features/tower/screens/tower_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/streak/streak_badge.dart';
import '../features/progression/level_up_banner.dart';
import '../features/brand/brand_ad_modal.dart';
import 'offline_banner.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex = widget.initialIndex;
  // Build 205: 마지막으로 광고 모달을 trigger 시도한 promo letter id. 같은
  // id 가 다시 build 되면 무시 — id 가 바뀌면(새 광고 도착) 다시 trigger.
  String? _lastTriggeredAdId;

  late final List<Widget> _pages = [
    WorldMapScreen(onGoToInbox: () => setState(() => _currentIndex = 1)),
    const InboxScreen(),
    const TowerScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 스트릭·레벨업 축하 스낵바 — 첫 프레임 이후 1회 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      StreakCelebrationBar.showIfIncreased(context);
      // 레벨업은 스트릭보다 우선 (더 큰 이벤트) — 살짝 딜레이로 연달아 표시
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) LevelUpBanner.showIfLevelUp(context);
      });
      // Build 205: 첫 번째 광고 trigger 는 build() 의 reactive 경로에서 처리.
      // (이전 build 202 의 1.2s 단발 호출은 새 광고 도착 시 재발사 안 됐음.)
    });
  }

  void _openCompose(BuildContext ctx) async {
    // 탭 진입 피드백
    HapticFeedback.lightImpact();
    // Build 137: Free 유저는 "줍기 전용" 포지셔닝. 보내기 탭을 탭하면
    // Premium 업그레이드 시트로 유도 — "자기 홍보 편지 (사진 + 채널 링크)"
    // 혜택을 어필. 답장은 `letter_read_screen` 에서 별도로 여전히 가능.
    final state = ctx.read<AppState>();
    if (!state.currentUser.isPremium && !state.currentUser.isBrand) {
      final l = AppL10n.of(state.currentUser.languageCode);
      PremiumGateSheet.show(
        ctx,
        featureName: l.composeGateFeatureName,
        featureEmoji: '📣',
        description: l.composeGateDesc,
      );
      return;
    }
    final result = await Navigator.push<bool>(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const ComposeScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    // 편지 발송 성공 시 → 지도 탭으로 전환 + 발송 편지 위치로 카메라 이동
    if (result == true && mounted) {
      setState(() => _currentIndex = 0);
      // 약간의 딜레이 후 카메라 이동 (탭 전환 렌더링 완료 대기)
      Future.delayed(const Duration(milliseconds: 300), () {
        WorldMapScreen.focusSentLetterNotifier.value = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DM 기능 제거로 unreadCount 만 구독 → 수집첩 뱃지 변경 시에만 rebuild
    final badgeCount = context.select<AppState, int>(
      (s) => s.unreadCount,
    );
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    // Build 139: 회원 등급에 따라 중앙 탭 라벨·아이콘·색을 바꿔 각 등급의
    // 핵심 동작을 자연스럽게 노출. Free → 💎 업그레이드, Premium → ✉️ 보내기,
    // Brand → 📣 캠페인.
    final isPremium = context.select<AppState, bool>(
      (s) => s.currentUser.isPremium,
    );
    final isBrand = context.select<AppState, bool>(
      (s) => s.currentUser.isBrand,
    );
    // Build 205: 새 브랜드 광고 도착 시마다 모달 재trigger.
    // featuredBrandPromo.id 만 select 해 build 폭발 방지.
    final currentAdId = context.select<AppState, String?>(
      (s) => s.featuredBrandPromo?.id,
    );
    if (currentAdId != null && currentAdId != _lastTriggeredAdId) {
      _lastTriggeredAdId = currentAdId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BrandAdModal.showIfDue(context);
      });
    }
    final l = AppL10n.of(langCode);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTimeColors.of(context).backgroundGradient,
        ),
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Build 120: 네비 바 바로 위 "🎟 근처 N통" 상시 칩. 0 이면 숨김.
          // 탐험 탭이 이미 선택된 상태에서는 지도에 이미 보이므로 숨긴다.
          _NearbyCountChip(
            onTap: () => setState(() => _currentIndex = 0),
            hideWhenExploreSelected: _currentIndex == 0,
          ),
          _buildBottomNav(context, badgeCount, l, isPremium, isBrand),
        ],
      ),
    );
    // 기존 중앙 FAB 제거 — "보내기" 가 하단 네비 5번째 탭으로 승격되며
    // 수집(보물찾기) UX 에 발송 액션을 동등한 비중으로 둔다. 발송 자체는
    // 여전히 중요하지만 FAB 크기(56px 골드 펄스)만큼 시각 우선순위를 주진
    // 않는다.
  }

  Widget _buildBottomNav(
    BuildContext ctx,
    int badgeCount,
    AppL10n l,
    bool isPremium,
    bool isBrand,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTimeColors.of(ctx).bgDeep,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate((constraints.maxWidth / 8).floor(), (
                    index,
                  ) {
                    return Container(
                      width: 4,
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.3),
                    );
                  }),
                );
              },
            ),
          ),
          SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.explore_rounded,
                      label: l.navExplore,
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItemWithBadge(
                      icon: Icons.inventory_2_rounded,
                      label: l.navCollection,
                      isSelected: _currentIndex == 1,
                      badgeCount: badgeCount,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  Expanded(
                    // Build 139: 등급별 중앙 CTA — Free 는 업그레이드 유도,
                    // Premium 은 홍보 편지 보내기, Brand 는 캠페인 발행.
                    child: _ComposeNavItem(
                      label: isBrand
                          ? l.navCampaign
                          : (isPremium ? l.navSend : l.navUpgradeShort),
                      icon: isBrand
                          ? Icons.campaign_rounded
                          : (isPremium
                              ? Icons.edit_note_rounded
                              : Icons.workspace_premium_rounded),
                      accent: isBrand
                          ? AppColors.coupon
                          : AppColors.gold,
                      onTap: () => _openCompose(ctx),
                    ),
                  ),
                  Expanded(
                    // Build 163: 티어별 탭 라벨·아이콘 — Brand 는 타워 (건물
                    // 아이콘) 유지, Free/Premium 은 "레터" 캐릭터 (emoji_events
                    // 대신 person 계열) 로 성장 내러티브 전달.
                    child: _NavItem(
                      icon: isBrand
                          ? Icons.apartment_rounded
                          : Icons.catching_pokemon_rounded,
                      label: isBrand ? l.navTower : l.navLetter,
                      isSelected: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: l.profile,
                      isSelected: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 중앙 CTA 탭 — 등급별 색상·아이콘·라벨 (Build 139) ──
// Free → 💎 업그레이드 (gold), Premium → ✉️ 보내기 (gold),
// Brand → 📣 캠페인 (orange) — 한 눈에 "지금 내 역할" 을 감지.
class _ComposeNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _ComposeNavItem({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build 161: Semantics 라벨 — 스크린리더 대응.
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accent == AppColors.gold
                    ? const Color(0xFF1A1300)
                    : AppColors.bgDeep,
                size: 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── 내비 아이템 ───────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build 161: Semantics — tab role + selected state.
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Build 145: 선택 시 살짝 커지는 피드백 (1.08x) + 색 전환.
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              scale: isSelected ? 1.08 : 1.0,
              child: Icon(
                icon,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              child: Text(label),
            ),
            // Build 145: 선택 탭 하단 gold dot indicator — 어느 탭인지 한 번 더 시각화.
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 14 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build 161: Semantics — tab with badge count 수집첩 hint.
    return Semantics(
      label: badgeCount > 0 ? '$label · $badgeCount' : label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Build 145: `_NavItem` 과 동일한 AnimatedScale + gold dot 피드백.
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              scale: isSelected ? 1.08 : 1.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppColors.gold : AppColors.textMuted,
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$badgeCount',
                            style: const TextStyle(
                              color: AppColors.bgDeep,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 14 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}


/// Build 120: "🎟 근처 N통" 항상 노출 칩. 네비 바 위에 얇은 띠로 렌더.
/// 0 통이면 공간 자체 숨김. 탐험 탭에 이미 있을 때도 중복이라 숨김.
class _NearbyCountChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool hideWhenExploreSelected;

  const _NearbyCountChip({
    required this.onTap,
    required this.hideWhenExploreSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (hideWhenExploreSelected) return const SizedBox.shrink();
    final count = context.select<AppState, int>(
      (s) => s.nearbyLetters.length,
    );
    if (count == 0) return const SizedBox.shrink();
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l10n = AppL10n.of(langCode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.15),
            border: Border(
              top: BorderSide(
                color: AppColors.teal.withValues(alpha: 0.35),
                width: 0.8,
              ),
              bottom: BorderSide(
                color: AppColors.teal.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.mainNavNearbyChip(count),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 5.0;
        const dashGap = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(
              width: dashWidth,
              height: 1.2,
              color: AppColors.goldDark.withValues(alpha: 0.45),
            ),
          ),
        );
      },
    );
  }
}
