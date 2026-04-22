import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../models/letter.dart';
import '../state/app_state.dart';
import '../features/map/screens/world_map_screen.dart';
import '../features/compose/screens/compose_screen.dart';
import '../features/premium/premium_gate_sheet.dart';
import '../features/inbox/screens/inbox_screen.dart';
import '../features/tower/screens/tower_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/streak/streak_badge.dart';
import '../features/progression/level_up_banner.dart';
import 'offline_banner.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex = widget.initialIndex;

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
      // 🎁 브랜드 할인 편지 안내 팝업 — 7일 간격으로 재노출 (Free/Premium 전용)
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showBrandPromoIfDue(context);
      });
    });
  }

  /// 🎟 브랜드 홍보 티켓형 팝업 (Build 107).
  /// 형식: 테두리 쿠폰 티켓 — "신상 50% 할인 by OOO 브랜드" + 만료 기간 표시.
  /// 표시 조건:
  ///   - 유저가 Free 또는 Premium (Brand 는 자기 캠페인이라 제외)
  ///   - 활성 브랜드 holidayBrand 편지가 존재 (`AppState.featuredBrandPromo`)
  ///   - 이번 세션에서 아직 한 번도 표시되지 않음
  /// 닫으면 `markPromoShownThisSession()` 으로 세션 플래그 on — 앱 재시작까지
  /// 재노출 안 됨. 기간 제한은 편지의 `expiresAt` 을 그대로 사용 (브랜드가
  /// 컴포즈 시 설정).
  Future<void> _showBrandPromoIfDue(BuildContext ctx) async {
    final state = ctx.read<AppState>();
    if (state.currentUser.isBrand) return;
    if (state.promoShownThisSession) return;

    final promo = state.featuredBrandPromo;
    if (promo == null) return;

    if (!ctx.mounted) return;
    final l = AppL10n.of(state.currentUser.languageCode);

    state.markPromoShownThisSession();

    await showDialog(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _BrandPromoTicket(
          promo: promo,
          l10n: l,
          onClose: () => Navigator.of(dCtx).pop(),
        ),
      ),
    );
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
                          ? const Color(0xFFFF8A5C)
                          : AppColors.gold,
                      onTap: () => _openCompose(ctx),
                    ),
                  ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: accent, size: 20),
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

// ── 🎟 브랜드 홍보 티켓형 팝업 ────────────────────────────────────────────────
/// "신상 50% 할인 by OOO 브랜드" 형식의 쿠폰 티켓 모달.
/// 좌우 반원 노치로 티켓감 + 점선 구분선 + 만료 기간 표시. 닫기 누르면 세션
/// 내 재표시 안 됨. 만료는 브랜드의 편지 expiresAt 을 그대로 따른다.
class _BrandPromoTicket extends StatelessWidget {
  final Letter promo;
  final AppL10n l10n;
  final VoidCallback onClose;

  const _BrandPromoTicket({
    required this.promo,
    required this.l10n,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final title = _extractTitle(promo.content);
    final brandName = promo.senderName.isNotEmpty
        ? promo.senderName
        : l10n.brandTicketDefaultBrand;
    final expiresAt = promo.expiresAt;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: Row(
                        children: [
                          const Text("🎟", style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.brandTicketTopLabel,
                              style: const TextStyle(
                                color: Color(0xFF6B4A00),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onClose,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4A00).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF6B4A00),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF2B1A00),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                l10n.brandTicketBy,
                                style: const TextStyle(
                                  color: Color(0xFF6B4A00),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  brandName,
                                  style: const TextStyle(
                                    color: Color(0xFF2B1A00),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (promo.senderCountryFlag.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  promo.senderCountryFlag,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _DashedLine(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFF6B4A00),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              expiresAt == null
                                  ? l10n.brandTicketNoExpiry
                                  : l10n.brandTicketExpiresAt(_formatExpiry(expiresAt)),
                              style: const TextStyle(
                                color: Color(0xFF6B4A00),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            l10n.brandTicketCloseHint,
                            style: TextStyle(
                              color: const Color(0xFF6B4A00).withValues(alpha: 0.7),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: -10,
                top: 0,
                bottom: 0,
                child: Center(child: _SideNotch()),
              ),
              const Positioned(
                right: -10,
                top: 0,
                bottom: 0,
                child: Center(child: _SideNotch()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractTitle(String content) {
    final firstLine = content.split("\n").firstWhere(
          (s) => s.trim().isNotEmpty,
          orElse: () => "",
        );
    final trimmed = firstLine.trim();
    if (trimmed.isEmpty) return l10n.brandTicketFallbackTitle;
    if (trimmed.length <= 40) return trimmed;
    return "${trimmed.substring(0, 38)}…";
  }

  String _formatExpiry(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now);
    if (diff.isNegative) return l10n.brandTicketExpired;
    if (diff.inHours < 24) return l10n.brandTicketHoursLeft(diff.inHours);
    return l10n.brandTicketDaysLeft(diff.inDays);
  }
}

class _SideNotch extends StatelessWidget {
  const _SideNotch();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A12),
        shape: BoxShape.circle,
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
              color: const Color(0xFF6B4A00).withValues(alpha: 0.45),
            ),
          ),
        );
      },
    );
  }
}
