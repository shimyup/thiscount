import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/purchase_service.dart';
import '../state/app_state.dart';
import '../features/map/screens/world_map_screen.dart';
import '../features/compose/screens/compose_screen.dart';
import '../features/premium/brand_only_gate_sheet.dart';
import '../features/premium/premium_screen.dart';
import '../features/brand/brand_campaign_screen.dart';
import '../features/inbox/screens/inbox_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/streak/streak_badge.dart';
import '../features/progression/level_up_banner.dart';
import '../features/brand/brand_ad_modal.dart';
import '../features/brand/brand_insights_screen.dart';
import '../models/brand_insights.dart';
import 'offline_banner.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex = widget.initialIndex;
  // Build 418 (사용자 device): 비-지도 탭 지도 peek 제거 — 탭 콘텐츠 전체화면.
  // Build 205: 마지막으로 광고 모달을 trigger 시도한 promo letter id. 같은
  // id 가 다시 build 되면 무시 — id 가 바뀌면(새 광고 도착) 다시 trigger.
  String? _lastTriggeredAdId;

  // Build 324 (positioning): 4탭 → 3탭. 타워 탭 격리 — TowerScreen 은 별도
  //   /tower 라우트로 ProfileScreen 안의 진입 카드를 통해 접근. 첫 화면의
  //   인지 부하 -25% (4개 nav → 3개 + 중앙 보내기).
  //   인덱스 매핑: 0=지도, 1=인박스/캠페인, 2=프로필.
  //
  // Build 405 (PR-NN3): isBrand 분기 — 가운데 탭이 사용자 종류에 따라 달라짐.
  //   일반 회원: [지도, 인박스 (받은 쿠폰), 프로필]
  //   Brand 계정: [지도 (공유), 캠페인 (내 발송), 프로필 (공유)]
  //   index 1 만 다르고 0/2 는 공유. 데이터 source 도 일부 공유:
  //   - state.worldLetters / state.currentUser.latitude/longitude → 공유
  //   - state.sent → Brand 쪽에서 캠페인 list 로 사용
  //   - state.inbox → 일반 회원만 사용
  //   getter 로 reactive — isBrand 변경 시 (settings 에서) 자동 재계산.
  // Build 408 (QQ9): 지도는 Stack base 로 항상 mount. 비-지도 페이지는 body
  //   내부 IndexedStack 에서 직접 구성 (peek 레이아웃과 결합).
  Widget _mapPage() => WorldMapScreen(
        onGoToInbox: () => setState(() => _currentIndex = 1),
        // Build 408 (QQ9): 지도 탭일 때만 chrome 노출. 다른 탭에서는 배경
        //   peek 로만 쓰여 헤더/배너가 비치지 않게 한다.
        showChrome: _currentIndex == 0,
      );

  @override
  void initState() {
    super.initState();
    // 스트릭·레벨업 축하 스낵바 — 첫 프레임 이후 1회 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Build 324: 신규 가입자 trial 부여 직후 1회 모달 — "결제한 적 없는데 왜
      //   Premium?" 혼란 해소 (Free 신규 시뮬레이션 발견). 다른 banner 보다 우선.
      _maybeShowWelcomeTrialModal();
      StreakCelebrationBar.showIfIncreased(context);
      // 레벨업은 스트릭보다 우선 (더 큰 이벤트) — 살짝 딜레이로 연달아 표시
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) LevelUpBanner.showIfLevelUp(context);
      });
      // Build 205: 첫 번째 광고 trigger 는 build() 의 reactive 경로에서 처리.
      // Build 324: TowerScreen 탭 격리 — initialIndex 기반 popup auto-show 도
      //   더 이상 필요 없음 (TowerScreen 진입은 명시적 /tower 라우트로만).
    });
  }

  /// Build 324: trial 첫 부여 직후 home 화면에서 1회 모달.
  ///   AppState.pendingWelcomeTrialNotice 가 true 면 노출 + consume.
  /// Build 324 (5차 audit): 첫 액션 (픽업 1회) 후에만 노출 — 가입 직후 noi
  ///   "또 다른 구독 앱" 오염 차단. 사용자가 가치를 1회 체험한 후 trial 안내.
  Future<void> _maybeShowWelcomeTrialModal() async {
    final state = context.read<AppState>();
    if (!state.pendingWelcomeTrialNotice) return;
    // 첫 픽업 전이면 보류 — 픽업 후 _maybeShowDeferredTrialModal 가 다시 시도.
    if (!state.hasAtLeastOnePickup) return;
    state.consumeWelcomeTrialNotice();
    final l = AppL10n.of(state.currentUser.languageCode);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Text('🎁', style: TextStyle(fontSize: 38)),
        title: Text(
          l.welcomeTrialTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l.welcomeTrialBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF1A0008),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(
                l.welcomeTrialCta,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
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
    // Build 291 (P0 moderation): admin 이 차단한 계정은 compose 진입 즉시 차단.
    // Firestore `banned=true` 가 다음 sync 에서 _currentUser.isBanned 로 반영됨.
    if (state.currentUser.isBanned) {
      final l = AppL10n.of(state.currentUser.languageCode);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(l.composeBannedAccount),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    // Build 425 (device): 발송은 Brand(광고주) 계정 전용. Free·Premium 은 발송 탭
    //   자체가 숨겨져 여기 도달하지 않지만(다른 진입점 대비) 안전망으로 Brand
    //   전용 안내 시트를 띄운다. Premium 의 답장·DM 은 별도 경로로 유지.
    if (!state.currentUser.isBrand) {
      final l = AppL10n.of(state.currentUser.languageCode);
      BrandOnlyGateSheet.show(
        ctx,
        featureName: l.navCampaign,
        featureEmoji: '📣',
        description: l.categoryHelpBrandOnlyNote,
        viewerIsPremium: state.currentUser.isPremium,
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
    final badgeCount = context.select<AppState, int>((s) => s.unreadCount);
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
    // Build 324 (5차 audit): trial 모달 노출 보류된 경우 (가입 직후 첫 픽업
    //   전), 픽업 1회 후 build rebuild 트리거에서 다시 시도. context.select 로
    //   hasAtLeastOnePickup + pendingWelcomeTrialNotice 변화만 listen.
    final pendingTrial = context.select<AppState, bool>(
      (s) => s.pendingWelcomeTrialNotice && s.hasAtLeastOnePickup,
    );
    if (pendingTrial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowWelcomeTrialModal();
      });
    }
    final l = AppL10n.of(langCode);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTimeColors.of(context).backgroundGradient,
        ),
        // Build 408 (QQ3): 상단 SafeArea — 배너(offline/trial/brandInsights)가
        //   status bar/notch 아래로 짤리던 회귀 차단. bottom:false 로 하단
        //   네비(자체 SafeArea)와 inset 중복 방지. 배너가 모두 숨김(shrink)
        //   이어도 SafeArea 는 상단만 패딩 → 지도 상단 strip 은 테마 그라데이션.
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              const OfflineBanner(),
              // Build 288: trial 만료 카운트다운 배너 — Free 페르소나 friction
              // point 1 (trial 만료 surprise) 해소. trial 활성 중 + 미결제 상태
              // 일 때만 노출. 탭하면 premium_screen 진입.
              const _TrialCountdownBanner(),
              // Build 325 (T6): Brand 사용자 홈 배너 — brandInsights 사용 전환률 +
              //   상태 emoji 한 줄. 기존엔 profile → Brand 카드 (2뎁스) 진입.
              //   이제 모든 탭 상단에서 1뎁스로 ROI 가시화 + 1 탭으로 상세 진입.
              const _BrandInsightsHomeBanner(),
              Expanded(
                // Build 408 (QQ9): IndexedStack → Stack. 지도를 항상 base 로
                //   깔고, 비-지도 탭 선택 시 상단 _kMapPeek 만큼 지도가 보이도록
                //   콘텐츠 시트를 내린다("내 위치 지도 항상 일부 노출"). 비-지도
                //   페이지는 Offstage 안의 IndexedStack 으로 state 유지.
                child: Stack(
                  children: [
                    // 지도 — 항상 mount (state/카메라 유지 + peek 노출).
                    // Build 409 (sim P1.42 a11y): 비-지도 탭에서는 지도가 시트
                    //   뒤로 가려지므로 semantics 트리·포인터에서 제외 — 스크린
                    //   리더가 가려진 마커들을 읽는 dead zone + 시트 뒤 오작동
                    //   터치 차단. (상단 96px peek 도 비활성 — 탭은 하단 nav 로.)
                    Positioned.fill(
                      child: ExcludeSemantics(
                        excluding: _currentIndex != 0,
                        child: IgnorePointer(
                          ignoring: _currentIndex != 0,
                          child: _mapPage(),
                        ),
                      ),
                    ),
                    // Build 418 (사용자 device): 비-지도 탭은 지도 peek 없이 화면
                    //   전체를 채운다(상단 _kMapPeek 노출 제거) — 탭 콘텐츠만 전체로.
                    Positioned.fill(
                      child: Offstage(
                        offstage: _currentIndex == 0,
                        // 시트가 이미 status bar 아래라 top inset 중복 제거.
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: IndexedStack(
                            index: (_currentIndex - 1).clamp(0, 1),
                            children: [
                              if (isBrand)
                                const BrandCampaignScreen()
                              else
                                const InboxScreen(),
                              const ProfileScreen(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              // Build 271: 64 → 70 — _NavItem 의 icon(22) + SizedBox(3) +
              // Text(10pt) + SizedBox(3) + dot(3) 합산 시 vertical padding(16)
              // 포함하면 ~62 가 빠듯 → 일부 환경에서 2px overflow. 6px 여유.
              height: 70,
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
                  // Build 405 (PR-NN3): 가운데-왼쪽 탭이 isBrand 분기.
                  //   일반 회원: 인박스 (받은 쿠폰) + unread 뱃지
                  //   Brand: 캠페인 (보낸 발송) — 뱃지 없음 (받는 게 아니라 보내는 거)
                  Expanded(
                    child: isBrand
                        ? _NavItem(
                            icon: Icons.campaign_rounded,
                            label: l.brandCampaignTitle,
                            isSelected: _currentIndex == 1,
                            onTap: () => setState(() => _currentIndex = 1),
                          )
                        : _NavItemWithBadge(
                            icon: Icons.inventory_2_rounded,
                            label: l.navCollection,
                            isSelected: _currentIndex == 1,
                            badgeCount: badgeCount,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                  ),
                  // Build 425 (device): 발송은 Brand(광고주) 계정 전용으로 전환 —
                  //   Free·Premium 은 줍기 중심이라 발송 탭 자체를 숨긴다(이전엔
                  //   Free=업그레이드 / Premium=홍보 노출). Premium 은 답장·DM 으로
                  //   여전히 상호작용 가능.
                  if (isBrand)
                    Expanded(
                      child: _ComposeNavItem(
                        label: l.navCampaign,
                        icon: Icons.campaign_rounded,
                        accent: AppColors.coupon,
                        isLocked: false,
                        onTap: () => _openCompose(ctx),
                      ),
                    ),
                  // Build 324 (positioning): 4탭 → 3탭. 타워 탭 격리 →
                  //   ProfileScreen 의 "내 등급" 진입 카드로 통합. 첫 화면의
                  //   nav 인지 부하 -25% + 등급/타워 시스템은 진성 사용자만
                  //   발견하는 "숨겨진 깊이" (포켓몬 GO 의 메달 패턴).
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: l.profile,
                      isSelected: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
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

// ── 중앙 CTA 탭 — 등급별 색상·아이콘·라벨 (Build 139, 223) ──
// Free    → 💎 업그레이드 (gold + 🔒 lock) · tap → PremiumGate
// Premium → 📣 홍보 (gold) · tap → compose
// Brand   → 📣 캠페인 (orange) · tap → compose
class _ComposeNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isLocked;

  const _ComposeNavItem({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Build 161: Semantics 라벨 — 스크린리더 대응.
    return Semantics(
      label: isLocked ? '$label (locked)' : label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Build 223: Free 일 때 잠금 뱃지 overlay 추가
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isLocked ? accent.withValues(alpha: 0.55) : accent,
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
                  if (isLocked)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep,
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.2),
                        ),
                        child: Icon(Icons.lock_rounded, size: 8, color: accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isLocked ? accent.withValues(alpha: 0.75) : accent,
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
    final count = context.select<AppState, int>((s) => s.nearbyLetters.length);
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

/// Build 288: Premium trial 활성 중 매 화면 최상단에 잔여 시간 + 업그레이드 CTA.
/// trial 만료 sudden surprise 회귀 차단 — 사용자가 마지막 1-2일에 결제 의사
/// 결정 시간 확보.
class _TrialCountdownBanner extends StatelessWidget {
  const _TrialCountdownBanner();

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseService>();
    final isPremium = context.select<AppState, bool>(
      (s) => s.currentUser.isPremium,
    );
    // 본 결제 완료 (Brand 또는 정식 Premium) 시 배너 숨김 — trial 만 노출.
    if (!purchase.isTrialActive) return const SizedBox.shrink();
    if (purchase.trialExpiry == null) return const SizedBox.shrink();
    // Premium 정식 결제 완료 사용자가 trial 잔여기 있는 케이스는 잠재적 — 노출 X.
    if (isPremium && !purchase.isBetaFreePremium && !purchase.isTestMode) {
      return const SizedBox.shrink();
    }
    final hours = purchase.trialHoursRemaining;
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l = AppL10n.of(langCode);
    final isUrgent = hours <= 24;
    final color = isUrgent ? AppColors.error : AppColors.gold;
    return Material(
      color: color.withValues(alpha: 0.14),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: color.withValues(alpha: 0.32),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isUrgent ? Icons.access_time_filled : Icons.star_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.trialBannerLabel} · ${_formatRemaining(l, hours)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Text(
                l.trialBannerCta,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRemaining(AppL10n l, int hours) {
    if (hours <= 0) return l.trialBannerExpired;
    if (hours < 24) return l.trialBannerHoursLeft(hours);
    // Build 402 (PR-JJ9 UX P1-8): premium_screen `_TrialExpiryBanner` 와 동일하게
    //   `.ceil()` 통일. 이전엔 `.floor()` 사용 → 71h 남았을 때 헤더 배너 "2일"
    //   vs Premium 화면 "3일" 불일치 → 환불 요청 유발. 사용자 친화 측면에서도
    //   `.ceil()` 이 자연 ("내일까지 사용 가능" 인식).
    final days = (hours / 24).ceil();
    return l.trialBannerDaysLeft(days);
  }
}

/// Build 325 (T6): Brand 사용자 전용 ROI 요약 홈 배너.
///   기존: profile → Brand 카드 (2뎁스) 진입해야 redeemRate / healthEmoji 확인.
///   현재: 앱 진입 즉시 사용 전환률 + 상태 노출. 탭 → BrandInsightsScreen 풀상세.
///   Brand 비-회원이면 미노출.
class _BrandInsightsHomeBanner extends StatelessWidget {
  const _BrandInsightsHomeBanner();

  @override
  Widget build(BuildContext context) {
    final isBrand = context.select<AppState, bool>(
      (s) => s.currentUser.isBrand,
    );
    if (!isBrand) return const SizedBox.shrink();
    final insights = context.select<AppState, BrandInsights>(
      (s) => s.brandInsights,
    );
    final totalSent = insights.totalSent;
    final totalPickup = insights.totalPickup;
    final totalRevealed = insights.totalRevealed;
    final redeemRate = insights.redeemRate;
    final healthEmoji = insights.healthEmoji;
    // 데이터 0 이면 노출 X (신규 Brand 가 의미 없는 0% 보면 혼란).
    if (totalSent == 0 && totalPickup == 0) return const SizedBox.shrink();
    final pct = (redeemRate * 100).toStringAsFixed(redeemRate >= 0.10 ? 0 : 1);
    // Build 342 (PR-S13 3차 시뮬레이션 P2): 배너 prefix 14언어 i18n.
    final l = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    return Material(
      color: AppColors.gold.withValues(alpha: 0.10),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          BrandInsightsScreen.routeName,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.28),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(healthEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(text: l.brandHomeBannerPrefix),
                      TextSpan(
                        text: '$pct%',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        // Build 331 (PR-S3): 4단계 funnel 미니뷰 — 📮 → 🎯 → 🛒.
                        //   ✅ (사용) 은 pct 가 이미 표현하므로 trail 생략.
                        text:
                            '  ·  📮 $totalSent → 🎯 $totalPickup → 🛒 $totalRevealed',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gold,
                size: 16,
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
        final dashCount = (constraints.maxWidth / (dashWidth + dashGap))
            .floor();
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
