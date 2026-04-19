import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../state/app_state.dart';
import '../features/map/screens/world_map_screen.dart';
import '../features/compose/screens/compose_screen.dart';
import '../features/inbox/screens/inbox_screen.dart';
import '../features/tower/screens/tower_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/streak/streak_badge.dart';
import 'offline_banner.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  late int _currentIndex = widget.initialIndex;

  late final List<Widget> _pages = [
    WorldMapScreen(onGoToInbox: () => setState(() => _currentIndex = 1)),
    const InboxScreen(),
    const TowerScreen(),
    const ProfileScreen(),
  ];

  late AnimationController _fabPulseController;
  late Animation<double> _fabPulse;
  late AnimationController _fabTapController;
  late Animation<double> _fabTapScale;

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _fabPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabPulseController, curve: Curves.easeInOut),
    );
    // FAB 탭 시 눌리는 효과
    _fabTapController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _fabTapScale = Tween<double>(begin: 1.0, end: 0.87).animate(
      CurvedAnimation(parent: _fabTapController, curve: Curves.easeOut),
    );
    // 스트릭 축하 스낵바 — 첫 프레임 이후 표시 (mount 직후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StreakCelebrationBar.showIfIncreased(context);
    });
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    _fabTapController.dispose();
    super.dispose();
  }

  void _openCompose(BuildContext ctx) async {
    // 가벼운 햅틱 + 버튼 눌림 애니메이션
    HapticFeedback.lightImpact();
    _fabTapController.forward().then((_) => _fabTapController.reverse());
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
    // unreadCount + totalDMUnread만 구독 → 편지/DM 뱃지 변경 시에만 rebuild
    final badgeCount = context.select<AppState, int>(
      (s) => s.unreadCount + s.totalDMUnread,
    );
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
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
      bottomNavigationBar: _buildBottomNav(context, badgeCount, l),
          floatingActionButton: AnimatedBuilder(
            animation: Listenable.merge([_fabPulse, _fabTapController]),
            builder: (_, __) => GestureDetector(
              onTap: () => _openCompose(context),
              child: Transform.scale(
                scale: _fabTapScale.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.goldLight,
                        AppColors.gold,
                        AppColors.goldDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(
                          alpha: 0.35 + _fabPulse.value * 0.25,
                        ),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('✍️', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
  }

  Widget _buildBottomNav(BuildContext ctx, int badgeCount, AppL10n l) {
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
                      icon: Icons.public_rounded,
                      label: l.map,
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItemWithBadge(
                      icon: Icons.mail_rounded,
                      label: l.inbox,
                      isSelected: _currentIndex == 1,
                      badgeCount: badgeCount,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 56), // center space for FAB
                  Expanded(
                    child: _NavItem(
                      icon: Icons.apartment_rounded,
                      label: l.navTower,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
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
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
