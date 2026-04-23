import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../models/letter.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../settings/settings_screen.dart';
import '../../premium/premium_screen.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../widgets/shared_profile_dialogs.dart';

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen>
    with TickerProviderStateMixin {
  late AnimationController _towerRiseController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late Animation<double> _towerRise;
  late Animation<double> _glow;
  late Animation<double> _float;

  // 레벨업 감지용 이전 단계 추적
  TowerTier? _prevTier;

  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

  @override
  void initState() {
    super.initState();

    _towerRiseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _towerRise = CurvedAnimation(
      parent: _towerRiseController,
      curve: Curves.easeOutBack,
    );
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _float = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _towerRiseController.forward();
  }

  @override
  void dispose() {
    _towerRiseController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, PurchaseService>(
      builder: (context, state, purchase, _) {
        final user = state.currentUser;
        final _lc = user.languageCode;
        final _l = AppL10n.of(_lc);
        final score = user.activityScore;
        final hasPremium =
            purchase.isPremium ||
            purchase.isBrand ||
            user.isPremium ||
            user.isBrand;
        // Build 183: Free/Premium 레터 탭에서 "타워" 표기 숨김. Brand 는
        // 기존 타워 네러티브 유지 — 사업자에게는 건물 은유가 여전히 유효.
        final isBrand = user.isBrand || purchase.isBrand;

        // 타워 단계 상승 감지 → 강렬한 햅틱 피드백
        final currentTier = score.tier;
        if (_prevTier != null &&
            currentTier.tierNumber > _prevTier!.tierNumber) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              HapticFeedback.heavyImpact();
              Future.delayed(const Duration(milliseconds: 250), () {
                if (mounted) HapticFeedback.heavyImpact();
              });
            }
          });
        }
        _prevTier = currentTier;

        return Scaffold(
          backgroundColor: AppTimeColors.of(context).bgDeep,
          body: CustomScrollView(
            slivers: [
              // 앱바
              SliverAppBar(
                expandedHeight: 0,
                floating: false,
                pinned: true,
                toolbarHeight: kToolbarHeight,
                backgroundColor: AppTimeColors.of(context).bgDeep,
                title: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.gold],
                  ).createShader(b),
                  child: Text(
                    isBrand ? _l.towerMyTower : _l.letterMyCharacter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                actions: [
                  // 레벨 뱃지 (앱바 오른쪽 — 타워 카드와 완전 분리)
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) {
                      final tierColor = _communityTierColor(score.tier);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tierColor.withValues(
                              alpha: 0.5 + _glow.value * 0.3,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tierColor.withValues(
                                alpha: _glow.value * 0.25,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          'Lv.${score.tier.tierNumber}  ${score.tier.labelL(_lc)}',
                          style: TextStyle(
                            color: tierColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                  // 타워 꾸미기 버튼 — Build 183: Brand 만 노출.
                  // Free/Premium 은 레터 캐릭터 탭이라 "타워 꾸미기" 가
                  // 맥락 불일치. 향후 캐릭터 커스터마이저 별도 구현 시 재등장.
                  if (isBrand)
                    TextButton.icon(
                      onPressed: () => _showTowerCustomizer(context, state),
                      icon: const Text('🎨', style: TextStyle(fontSize: 14)),
                      label: Text(
                        _l.towerCustomize,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => _showMoreMenu(context, state),
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Build 163: Brand 는 타워 시각화 유지, Free/Premium 은
                    // "성장하는 레터 캐릭터" 로 교체. 유저의 `characterEmoji`
                    // + 컴패니언 + 악세사리 스택을 hero 로 노출.
                    if (user.isBrand)
                      _buildTowerVisualization(score, user, hasPremium)
                    else
                      _buildCharacterVisualization(state, user),
                    // Build 174: 레터 캐릭터 갤러리 — 과거 티어 회고 (Free/Premium).
                    if (!user.isBrand) ...[
                      const SizedBox(height: 8),
                      _buildCharacterGallery(state, user),
                    ],
                    // ── 유저 정보 카드 ────────────────────────────────────────
                    _buildUserCard(context, user, score),
                    const SizedBox(height: 14),
                    // ── 활동 통계 ─────────────────────────────────────────────
                    _buildStatsGrid(context, score),
                    const SizedBox(height: 14),
                    // Build 180: Free/Premium 은 레벨업 가이드 숨김 — 레터 hero
                    // 의 로드맵 pill (Build 177) 과 중복. Brand 만 타워 진척 안내.
                    if (user.isBrand) ...[
                      _buildLevelUpGuide(context, score),
                      const SizedBox(height: 14),
                    ],
                    // Build 180: 성취 배지 ExpansionTile 로 접기.
                    _buildAchievementsCollapsible(context, score, user.languageCode),
                    const SizedBox(height: 14),
                    _buildCommunityTowers(context, state),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build 163: Free/Premium 유저 hero 영역 — 성장 캐릭터 중심.
  /// 타워 대신 큰 캐릭터 이모지 + 컴패니언/악세사리 + 레벨 pill.
  /// 유저가 앱 켜면 "내 레터 캐릭터가 지금 Level N" 을 즉시 인지.
  Widget _buildCharacterVisualization(AppState state, UserProfile user) {
    final char = state.currentCharacterEmoji;
    final companion = state.activeCompanionEmoji;
    final accessory = state.activeAccessoryEmoji;
    final level = state.currentLevel;
    final progress = state.levelProgress;
    final accent = user.isPremium ? AppColors.gold : AppColors.teal;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: accent.withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 캐릭터 stack — 아바타 배경 + 중앙 캐릭터 + 악세사리/컴패니언
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _float.value * 0.5),
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 외곽 글로우 링
                    AnimatedBuilder(
                      animation: _glow,
                      builder: (_, __) => Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(
                              alpha: 0.25 + _glow.value * 0.25,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // 아바타 본체
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCard.withValues(alpha: 0.95),
                        border: Border.all(color: accent, width: 2.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        char,
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                    // 머리 위 악세사리
                    if (accessory != null)
                      Positioned(
                        top: 0,
                        child: Text(
                          accessory,
                          style: const TextStyle(fontSize: 38),
                        ),
                      ),
                    // 오른쪽 하단 컴패니언
                    if (companion != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            companion,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Build 171: 레터 이름 (커스텀) + 편집 아이콘. 미설정 시 "이름 없음 · 탭".
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showEditTowerNameDialog(context, state),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    user.customTowerName?.isNotEmpty == true
                        ? user.customTowerName!
                        : AppL10n.of(user.languageCode)
                            .profileDialogLetterNameHint,
                    style: AppText.heading.copyWith(
                      color: user.customTowerName?.isNotEmpty == true
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontStyle: user.customTowerName?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: accent.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Build 177: 레벨 라벨 + Lv N 한 줄 통합 (separate rows 3개 → 1줄).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.levelLabel,
                style: AppText.title.copyWith(color: accent),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Lv $level',
                  style: AppText.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 진척 바 (얇아짐 6→4px)
          SizedBox(
            width: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.chip / 2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.bgSurface,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          // Build 177: 3개 pill (로드맵·생일·나이) → 1 rotating tip 으로 merge.
          const SizedBox(height: 12),
          _LetterTipRotator(state: state, accent: accent, lang: user.languageCode),
        ],
      ),
    );
  }

  /// Build 177: 레터 진행 관련 pill 3개 (생일·경과일·로드맵) 를 4초 간격
  /// 자동 순환하는 단일 tip pill 로 merge. AnimatedSwitcher fade.
  /// — 생일 당일은 우선순위 1 로 계속 고정.

  /// Build 174: 레터 캐릭터 갤러리 — 10 티어 진화 그리드 회고.
  /// 이미 지나온 티어는 풀 컬러 + 체크 오버레이, 현재 티어는 pulse glow,
  /// 미래 티어는 회색/잠금 아이콘. "내가 어디에서 왔고 어디로 가는지" 시각화.
  Widget _buildCharacterGallery(AppState state, UserProfile user) {
    final l = AppL10n.of(user.languageCode);
    final tiers = AppState.characterTierEmojis;
    final currentLvl = state.currentLevel;
    final currentTierIdx = ((currentLvl - 1) ~/ 5).clamp(0, tiers.length - 1);
    // Build 177: 갤러리 ExpansionTile 로 wrap — 기본 접힘 상태.
    // 유저가 원할 때만 10 티어 그리드 펼쳐보기.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: AppColors.textMuted,
          collapsedIconColor: AppColors.textMuted,
          title: Row(
            children: [
              Text(
                l.letterGalleryTitle,
                style: AppText.title.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${currentTierIdx + 1} / ${tiers.length}',
                  style: AppText.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l.letterGallerySubtitle,
              style: AppText.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ),
          children: [
            // 10개 티어 그리드 (5×2)
            GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: tiers.length,
            itemBuilder: (_, i) {
              final emoji = tiers[i];
              final tierStartLvl = (i * 5) + 1;
              final passed = i < currentTierIdx;
              final current = i == currentTierIdx;
              final locked = i > currentTierIdx;
              return Container(
                decoration: BoxDecoration(
                  color: current
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : passed
                          ? AppColors.bgSurface
                          : AppColors.bgDeep.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: current
                        ? AppColors.gold.withValues(alpha: 0.6)
                        : passed
                            ? AppColors.teal.withValues(alpha: 0.3)
                            : AppColors.textMuted.withValues(alpha: 0.15),
                    width: current ? 1.4 : 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: locked ? 0.25 : 1.0,
                      child: ColorFiltered(
                        colorFilter: locked
                            ? const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ])
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lv $tierStartLvl',
                      style: AppText.caption.copyWith(
                        color: current
                            ? AppColors.gold
                            : passed
                                ? AppColors.teal.withValues(alpha: 0.8)
                                : AppColors.textMuted.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ],  // ExpansionTile children
        ),    // ExpansionTile
      ),      // Theme
    );        // Container
  }


  // ── 타워 시각화 섹션 ─────────────────────────────────────────────────────────
  Widget _buildTowerVisualization(
    ActivityScore score,
    UserProfile user,
    bool hasPremium,
  ) {
    // 커스텀 색상 적용 (프리미엄 유저)
    Color tierColor = _communityTierColor(score.tier);
    if (hasPremium && user.towerColor.isNotEmpty) {
      try {
        final hex = user.towerColor.replaceFirst('#', '');
        tierColor = Color(int.parse('0xFF$hex'));
      } catch (_) {}
    }
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: 310,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF060D1A),
                tierColor.withValues(alpha: 0.06),
                const Color(0xFF0D1F3C),
              ],
            ),
            border: Border.all(
              color: tierColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 도시 배경 스카이라인
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _SkylinePainter(),
                  ),
                ),
                // 지면
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0D1F3C).withValues(alpha: 0.0),
                          const Color(0xFF0D1F3C),
                        ],
                      ),
                    ),
                  ),
                ),
                // 별 파티클 (높은 단계일수록 더 많이)
                ...List.generate((score.tier.tierNumber * 2).clamp(0, 16), (i) {
                  final rng = Random(i * 31 + score.tier.tierNumber);
                  final x = rng.nextDouble();
                  final y = rng.nextDouble() * 0.6;
                  final size = 1.5 + rng.nextDouble() * 2.5;
                  return Positioned(
                    left: x * 320,
                    top: y * 200,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, __) => Opacity(
                        opacity:
                            (0.3 + rng.nextDouble() * 0.5) *
                            (0.6 + _glow.value * 0.4),
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i % 3 == 0
                                ? tierColor
                                : i % 3 == 1
                                ? AppColors.gold
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // 스포트라이트 (landmark 단계)
                if (score.tier == TowerTier.landmark)
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) => Positioned(
                      bottom: 32,
                      child: Container(
                        width: 120,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              tierColor.withValues(alpha: _glow.value * 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // 글로우 효과
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, __) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(
                            alpha: _glow.value * 0.25,
                          ),
                          blurRadius: 70,
                          spreadRadius: 25,
                        ),
                      ],
                    ),
                  ),
                ),
                // 타워 본체
                AnimatedBuilder(
                  animation: Listenable.merge([_towerRise, _floatController]),
                  builder: (_, __) {
                    return Transform.translate(
                      offset: Offset(0, _float.value),
                      child: Transform.scale(
                        scale: _towerRise.value,
                        alignment: Alignment.bottomCenter,
                        child: CustomPaint(
                          size: Size(120, _calcTowerHeight(score)),
                          painter: _TowerPainter(
                            floors: score.towerFloors,
                            tier: score.tier,
                            glowIntensity: _glow.value,
                            tierColor: tierColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 층수 뱃지 (우상단)
                Positioned(
                  top: 14,
                  right: 14,
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tierColor.withValues(
                            alpha: 0.45 + _glow.value * 0.3,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withValues(
                              alpha: _glow.value * 0.25,
                            ),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.tier.emoji,
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (user.towerAccentEmoji != null) ...[
                            const SizedBox(width: 3),
                            Text(
                              user.towerAccentEmoji!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          const SizedBox(width: 5),
                          Text(
                            '${score.towerFloors}F',
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 단계 뱃지는 타워 카드 위 별도 행으로 이동됨 (겹침 방지)
                // 타워 이름 오버레이 (하단 중앙) — Stitch AI 추천
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (animCtx, __) => Column(
                      children: [
                        Text(
                          _l10n(animCtx).koEn('글자의 건축가', 'ARCHITECT OF WORDS'),
                          style: TextStyle(
                            color: tierColor.withValues(
                              alpha: 0.5 + _glow.value * 0.3,
                            ),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          score.tier.towerName,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.7 + _glow.value * 0.2,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ], // Column children
    ); // Column
  }

  double _calcTowerHeight(ActivityScore score) {
    final floors = score.towerFloors;
    return (60 + floors * 4.0).clamp(60.0, 240.0);
  }

  // ── 유저 정보 카드 ───────────────────────────────────────────────────────────
  Widget _buildUserCard(
    BuildContext ctx,
    UserProfile user,
    ActivityScore score,
  ) {
    final _l = AppL10n.of(user.languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(20),
        color: AppColors.gold.withValues(alpha: 0.4),
        strokeWidth: 2,
        dashPattern: const [6, 4],
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 아바타
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.countryFlag,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ── 타워 이름 편집 버튼 ──────────────────────────────
                        GestureDetector(
                          onTap: () => showEditTowerNameDialog(
                            ctx,
                            ctx.read<AppState>(),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: user.customTowerName?.isNotEmpty == true
                                  ? AppColors.gold.withValues(alpha: 0.12)
                                  : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: user.customTowerName?.isNotEmpty == true
                                    ? AppColors.gold.withValues(alpha: 0.55)
                                    : AppColors.gold.withValues(alpha: 0.35),
                                width: 1.3,
                              ),
                              boxShadow:
                                  user.customTowerName?.isNotEmpty == true
                                  ? [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.apartment_rounded,
                                  size: 15,
                                  color:
                                      user.customTowerName?.isNotEmpty == true
                                      ? AppColors.gold
                                      : AppColors.gold.withValues(alpha: 0.55),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    user.customTowerName?.isNotEmpty == true
                                        ? user.customTowerName!
                                        : _l.towerSetNameHint,
                                    style: TextStyle(
                                      color:
                                          user.customTowerName?.isNotEmpty ==
                                              true
                                          ? AppColors.gold
                                          : AppColors.textMuted,
                                      fontSize: 13,
                                      fontWeight:
                                          user.customTowerName?.isNotEmpty ==
                                              true
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 11,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              user.countryFlag,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.country,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 티어 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${score.tier.emoji}  ${score.tier.labelL(user.languageCode)}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (user.socialLink != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.socialLink!,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 활동 통계 그리드 ─────────────────────────────────────────────────────────
  Widget _buildStatsGrid(BuildContext ctx, ActivityScore score) {
    final _sl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sl.towerActivityStats,
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '📬',
                  value: '${score.receivedCount}',
                  label: _sl.towerReceivedLetters,
                  contribution: score.receivedCount * 1.2,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  emoji: '💌',
                  value: '${score.replyCount}',
                  label: _sl.towerReply,
                  contribution: score.replyCount * 2.0,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  emoji: '📤',
                  value: '${score.sentCount}',
                  label: _sl.towerSentLetters,
                  contribution: score.sentCount * 0.8,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 10단계 타워 게이지 바
          _buildTierGauge(ctx, score),
        ],
      ),
    );
  }

  // ── 10단계 타워 게이지 ────────────────────────────────────────────────────────
  Widget _buildTierGauge(BuildContext ctx, ActivityScore score) {
    final _sl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    final tier = score.tier;
    final tierColor = _communityTierColor(tier);
    final progress = score.tierProgress;
    final isMax = tier == TowerTier.landmark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: tierColor.withValues(alpha: 0.08), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          // 상단: 현재 단계 + 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(tier.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.labelL(ctx.read<AppState>().currentUser.languageCode),
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _sl.towerTierProgress(tier.tierNumber, 10),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.towerHeight.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _sl.towerActivityScore,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 10단계 도트 진행 표시
          Row(
            children: List.generate(TowerTier.values.length, (i) {
              final dotTier = TowerTier.values[i];
              final dotColor = _communityTierColor(dotTier);
              final isActive = i < tier.tierNumber;
              final isCurrent = i == tier.tierNumber - 1;
              return Expanded(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, __) => Container(
                    height: isCurrent ? 10 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? dotColor.withValues(alpha: isCurrent ? 1.0 : 0.6)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: dotColor.withValues(
                                  alpha: 0.4 + _glow.value * 0.3,
                                ),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // 현재 단계 내 진행 바
          if (!isMax) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bgSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tierColor.withValues(alpha: 0.8 + _glow.value * 0.2),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${score.tierMin.toInt()}pts',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  _sl.towerNextTierInfo(score.tierMax.toInt(), ((1 - progress) * (score.tierMax - score.tierMin)).toStringAsFixed(1)),
                  style: TextStyle(
                    color: tierColor.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _sl.towerTopTierReached,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tierColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _sl.towerScoreFormula,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── 레벨업 가이드 ────────────────────────────────────────────────────────────
  Widget _buildLevelUpGuide(BuildContext ctx, ActivityScore score) {
    final _sl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.08),
              AppColors.teal.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sl.towerNextGoal,
                    style: Theme.of(
                      ctx,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    score.tier.nextGoalL(ctx.read<AppState>().currentUser.languageCode),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build 180: 성취 배지를 ExpansionTile 로 감싼 collapsed 기본 wrapper.
  /// 획득 뱃지 수만 타이틀에 노출 — 자세한 그리드는 탭해서 펼침.
  Widget _buildAchievementsCollapsible(
    BuildContext ctx, ActivityScore score, String lang) {
    final l = AppL10n.of(lang);
    // 획득 수 계산은 `_buildAchievements` 와 동일 로직을 여기서 직접 세어
    // 헤더 정보로 사용. 실제 그리드 렌더링은 기존 `_buildAchievements` 위임.
    int earned = 0;
    if (score.sentCount >= 1) earned++;
    if (score.sentCount >= 10) earned++;
    if (score.sentCount >= 50) earned++;
    if (score.sentCount >= 100) earned++;
    if (score.receivedCount >= 1) earned++;
    if (score.receivedCount >= 10) earned++;
    if (score.receivedCount >= 50) earned++;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Theme(
        data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: EdgeInsets.zero,
          iconColor: AppColors.textMuted,
          collapsedIconColor: AppColors.textMuted,
          title: Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                l.towerAchievementBadges,
                style: AppText.title.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$earned',
                  style: AppText.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          children: [
            _buildAchievements(ctx, score),
          ],
        ),
      ),
    );
  }

  // ── 성취 배지 ────────────────────────────────────────────────────────────────
  Widget _buildAchievements(BuildContext ctx, ActivityScore score) {
    final _al = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    final achievements = [
      // ── letter activity ──────────────────────────────────────────
      _Achievement(
        emoji: '🌱',
        title: _al.towerBadgeFirstStep,
        desc: _al.towerBadgeFirstStepDesc,
        unlocked: score.sentCount >= 1,
      ),
      _Achievement(
        emoji: '📬',
        title: _al.towerBadgeCollector,
        desc: _al.towerBadgeCollectorDesc,
        unlocked: score.receivedCount >= 5,
      ),
      _Achievement(
        emoji: '💌',
        title: _al.towerBadgeCommunicator,
        desc: _al.towerBadgeCommunicatorDesc,
        unlocked: score.replyCount >= 3,
      ),
      _Achievement(
        emoji: '🌍',
        title: _al.towerBadgeTraveler,
        desc: _al.towerBadgeTravelerDesc,
        unlocked: score.sentCount >= 10,
      ),
      // ── tower tier achievements ──────────────────────────────────────
      _Achievement(
        emoji: '🏡',
        title: _al.towerBadgeHouseBuilder,
        desc: _al.towerBadgeHouseBuilderDesc, // house (15pts)
        unlocked: score.towerHeight >= 15,
      ),
      _Achievement(
        emoji: '🏢',
        title: _al.towerBadgeBuildingArchitect,
        desc: _al.towerBadgeBuildingArchitectDesc, // building (50pts)
        unlocked: score.towerHeight >= 50,
      ),
      _Achievement(
        emoji: '🏙️',
        title: _al.towerBadgeSkyscraper,
        desc: _al.towerBadgeSkyscraperDesc, // skyscraper (120pts)
        unlocked: score.towerHeight >= 120,
      ),
      // ── popularity / special ──────────────────────────────────────────
      _Achievement(
        emoji: '❤️',
        title: _al.towerBadgePopular,
        desc: _al.towerBadgePopularDesc,
        unlocked: score.likeCount >= 10,
      ),
      _Achievement(
        emoji: '🗼',
        title: _al.towerBadgeLegendaryLandmark,
        desc: _al.towerBadgeLegendaryLandmarkDesc, // landmark (330pts)
        unlocked: score.towerHeight >= 330,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _al.towerAchievementBadges,
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: achievements
                .map((a) => _AchievementBadge(achievement: a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTowers(BuildContext ctx, AppState state) {
    final _cl = AppL10n.of(state.currentUser.languageCode);
    final _clc = state.currentUser.languageCode;
    // Mock community members with usernames
    final members = [
      {
        'flag': '🇯🇵',
        'name': 'Kenji M.',
        'floors': 83,
        'tier': TowerTier.landmark,
      },
      {
        'flag': '🇧🇷',
        'name': 'Luis G.',
        'floors': 67,
        'tier': TowerTier.landmark,
      },
      {
        'flag': '🇨🇳',
        'name': 'Mei L.',
        'floors': 55,
        'tier': TowerTier.skyscraper,
      },
      {
        'flag': '🇺🇸',
        'name': 'Tom H.',
        'floors': 47,
        'tier': TowerTier.skyscraper,
      },
      {
        'flag': '🇫🇷',
        'name': 'Nina S.',
        'floors': 31,
        'tier': TowerTier.building,
      },
      {
        'flag': '🇬🇧',
        'name': 'Emma W.',
        'floors': 22,
        'tier': TowerTier.building,
      },
      {
        'flag': '🇩🇪',
        'name': 'Hana B.',
        'floors': 12,
        'tier': TowerTier.house,
      },
      {
        'flag': '🇰🇷',
        'name': _cl.towerAnonymousUser,
        'floors': 5,
        'tier': TowerTier.cottage,
      },
    ];
    final myScore = state.currentUser.activityScore;
    final myFloors = myScore.towerFloors;
    final myRank =
        members.where((m) => (m['floors'] as int) > myFloors).length + 1;

    String rankLabel(int rank) {
      if (rank == 1) return '🥇 ${_cl.towerRank1}';
      if (rank == 2) return '🥈 ${_cl.towerRank2}';
      if (rank == 3) return '🥉 ${_cl.towerRank3}';
      return '#$rank';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🌍 ${_cl.towerWorldRanking}',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _cl.towerMyRank(myRank),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...members.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final floors = m['floors'] as int;
            final tier = m['tier'] as TowerTier;
            final flag = m['flag'] as String;
            final name = m['name'] as String;
            final tierColor = _communityTierColor(tier);

            return GestureDetector(
              onTap: () => _showCommunityTowerDetail(ctx, idx + 1, m),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: idx == 0
                      ? AppColors.gold.withValues(alpha: 0.08)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: idx == 0
                        ? AppColors.gold.withValues(alpha: 0.3)
                        : const Color(0xFF1F2D44),
                  ),
                ),
                child: Row(
                  children: [
                    // 순위
                    SizedBox(
                      width: 32,
                      child: Text(
                        rankLabel(idx + 1),
                        style: TextStyle(
                          color: idx < 3 ? AppColors.gold : AppColors.textMuted,
                          fontSize: idx < 3 ? 18 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 국기
                    Text(flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    // 이름 + 티어
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                tier.emoji,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tier.labelL(_clc),
                                style: TextStyle(
                                  color: tierColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 층수 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${floors}F',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    rankLabel(myRank),
                    style: TextStyle(
                      color: myRank <= 3 ? AppColors.gold : AppColors.textMuted,
                      fontSize: myRank <= 3 ? 18 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.currentUser.countryFlag,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentUser.username,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            myScore.tier.emoji,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            myScore.tier.labelL(_clc),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${myScore.towerFloors}F',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _communityTierColor(TowerTier tier) {
    switch (tier) {
      case TowerTier.shack:
        return const Color(0xFF8B7355);
      case TowerTier.cottage:
        return const Color(0xFFCD7F32);
      case TowerTier.house:
        return const Color(0xFFC0C0C0);
      case TowerTier.townhouse:
        return const Color(0xFF90C878);
      case TowerTier.building:
        return AppColors.gold;
      case TowerTier.office:
        return AppColors.teal;
      case TowerTier.skyscraper:
        return const Color(0xFF60A5FA);
      case TowerTier.supertall:
        return const Color(0xFFAB78FF);
      case TowerTier.megatower:
        return const Color(0xFFFF9F43);
      case TowerTier.landmark:
        return const Color(0xFFFF6B9D);
    }
  }

  void _showCommunityTowerDetail(
    BuildContext ctx,
    int rank,
    Map<String, Object> m,
  ) {
    final _cdl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    final tier = m['tier'] as TowerTier;
    final floors = m['floors'] as int;
    final flag = m['flag'] as String;
    final name = m['name'] as String;
    final label = m['label'] as String;
    final tierColor = _communityTierColor(tier);

    // 층수에서 타워 높이 계산 (내 타워와 동일 공식)
    final towerH = (60 + floors * 4.0).clamp(60.0, 240.0);

    final _tl = _l10n(ctx);
    final rankLabel = rank == 1
        ? '🥇 ${_tl.towerRank1}'
        : rank == 2
        ? '🥈 ${_tl.towerRank2}'
        : rank == 3
        ? '🥉 ${_tl.towerRank3}'
        : '🌍 ${_tl.towerRankN(rank)}';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // 국기 + 이름
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgSurface,
                    border: Border.all(color: tierColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(flag, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tierColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '${tier.emoji}  $label',
                              style: TextStyle(
                                color: tierColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 통계 카드 2개
            Row(
              children: [
                // 세계 랭킹
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          rankLabel,
                          style: TextStyle(
                            color: rank <= 3
                                ? AppColors.gold
                                : AppColors.textSecondary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cdl.towerWorldRanking,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 건물 층수
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${floors}F',
                          style: TextStyle(
                            color: tierColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cdl.towerBuildingFloors,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 타워 높이 프로그레스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2D44)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _cdl.towerTowerHeight,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${towerH.toInt()}px',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: towerH / 240.0,
                      backgroundColor: AppColors.bgDeep,
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgSurface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_cdl.towerClose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showEditProfile(BuildContext ctx, AppState state) {
    final _el = AppL10n.of(state.currentUser.languageCode);
    final nameCtrl = TextEditingController(text: state.currentUser.username);
    final _socialInitial = state.currentUser.socialLink ?? '';
    final socialCtrl = TextEditingController.fromValue(
      TextEditingValue(
        text: _socialInitial,
        selection: TextSelection.collapsed(offset: _socialInitial.length),
      ),
    );
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(_el.towerEditProfile, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: _el.towerNickname,
                  prefixIcon: Icon(
                    Icons.person_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: socialCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: _el.towerSnsLinkOptional,
                  prefixIcon: Icon(
                    Icons.link_rounded,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  hintText: 'https://instagram.com/...',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final username = nameCtrl.text.trim().isNotEmpty
                        ? nameCtrl.text.trim()
                        : null;
                    final socialLink = socialCtrl.text.trim().isNotEmpty
                        ? socialCtrl.text.trim()
                        : null;
                    // AppState + SharedPreferences 동시 업데이트
                    state.updateProfile(
                      username: username,
                      socialLink: socialLink,
                    );
                    await AuthService.updateProfile(
                      username: username,
                      socialLink: socialLink,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(_el.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 타워 스킨 커스터마이저 ──────────────────────────────────────────────────
  void _showTowerCustomizer(BuildContext ctx, AppState state) {
    final _tl = AppL10n.of(state.currentUser.languageCode);
    final purchase = ctx.read<PurchaseService>();
    final hasPremium =
        purchase.isPremium ||
        purchase.isBrand ||
        state.currentUser.isPremium ||
        state.currentUser.isBrand;
    if (!hasPremium) {
      // 프리미엄 게이트
      showModalBottomSheet(
        context: ctx,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('🎨', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                _tl.towerCustomTitle,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tl.towerCustomDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.bgDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _tl.towerStartPremium,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 프리미엄 유저: 커스터마이저 열기
    String selectedColor = state.currentUser.towerColor;
    String? selectedEmoji = state.currentUser.towerAccentEmoji;
    int selectedRoof = state.currentUser.towerRoofStyle;
    int selectedWindow = state.currentUser.towerWindowStyle;

    const presetColors = [
      '#FFD700', // 금색 (기본)
      '#00E5CC', // 청록
      '#FF6B9D', // 핑크
      '#4FC3F7', // 하늘
      '#69F0AE', // 연두
      '#FF8A5C', // 오렌지
      '#CE93D8', // 보라
      '#EF5350', // 빨강
      '#FFFFFF', // 화이트
      '#90CAF9', // 연파랑
    ];

    const presetEmojis = [
      '🌟', '🔥', '⚡', '🌈', '🌸', '🎯',
      '💫', '🏆', '🌙', '☀️', '🌊', '🎪',
      '❄️', '🍀', '🦋', '👑',
    ];

    const transportVehicles = [
      {'emoji': '✈️', 'label': '여객기', 'tier': 0},    // 무료 (always unlocked)
      {'emoji': '🚀', 'label': '로켓', 'tier': 5},       // Lv.5 (landmark)
      {'emoji': '🛸', 'label': 'UFO', 'tier': -1},       // 프리미엄 전용
      {'emoji': '🎈', 'label': '열기구', 'tier': 2},     // Cottage 이상
      {'emoji': '🚢', 'label': '여객선', 'tier': 0},     // 무료
      {'emoji': '🚂', 'label': '증기기차', 'tier': 3},   // House 이상
      {'emoji': '🚁', 'label': '헬리콥터', 'tier': -1},  // 프리미엄
      {'emoji': '🛶', 'label': '나룻배', 'tier': 0},     // 무료
      {'emoji': '🛷', 'label': '산타썰매', 'tier': -1},  // 프리미엄
      {'emoji': '🪂', 'label': '낙하산', 'tier': -1},    // 프리미엄
      {'emoji': '🛩️', 'label': '소형비행기', 'tier': 1}, // Shack 이상
      {'emoji': '🚤', 'label': '스피드보트', 'tier': 4}, // Skyscraper 이상
    ];

    // 지붕 스타일 목록
    const roofStyles = [
      {'id': 0, 'label': '기본', 'icon': '🏠'},
      {'id': 1, 'label': '뾰족', 'icon': '⛪'},
      {'id': 2, 'label': '돔', 'icon': '🕌'},
      {'id': 3, 'label': '평지붕', 'icon': '🏢'},
      {'id': 4, 'label': '안테나', 'icon': '📡'},
    ];

    // 창문 스타일 목록
    const windowStyles = [
      {'id': 0, 'label': '사각', 'icon': '⬜'},
      {'id': 1, 'label': '원형', 'icon': '⭕'},
      {'id': 2, 'label': '아치', 'icon': '🪟'},
      {'id': 3, 'label': '모던', 'icon': '➖'},
    ];

    // ── 미니 타워 프리뷰 위젯 ──
    Widget buildMiniPreview(StateSetter setS) {
      final hexClean = selectedColor.replaceFirst('#', '');
      final previewColor = Color(int.parse('0xFF$hexClean'));
      const floors = 5;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: previewColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedEmoji != null)
              Text(selectedEmoji!, style: const TextStyle(fontSize: 14)),
            Text(state.currentUser.countryFlag, style: const TextStyle(fontSize: 14)),
            // 지붕
            _buildPreviewRoof(previewColor, selectedRoof),
            // 층
            ...List.generate(floors, (i) {
              final isBottom = i == floors - 1;
              final alpha = 0.25 - (i / floors) * 0.15;
              return _buildPreviewFloor(
                previewColor,
                alpha.clamp(0.05, 0.25),
                isBottom,
                i,
                selectedWindow,
              );
            }),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  previewColor.withValues(alpha: 0.95),
                  previewColor.withValues(alpha: 0.7),
                ]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '🥇',
                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    int _customizeTabIndex = 0; // 0=이동수단, 1=스킨, 2=효과

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 16, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      _tl.towerCustomizeTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '🏗️',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 스크롤 가능한 본문
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24, 0, 24,
                    MediaQuery.of(context).viewInsets.bottom + 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 미리보기 ──
                      buildMiniPreview(setS),

                      // ── 카테고리 탭 ──
                      StatefulBuilder(builder: (ctx2, setTab) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tab pills
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCustomizeTab('🚗 이동수단', 0, _customizeTabIndex, () { setS(() { _customizeTabIndex = 0; }); }),
                                  const SizedBox(width: 8),
                                  _buildCustomizeTab('🏢 타워스킨', 1, _customizeTabIndex, () { setS(() { _customizeTabIndex = 1; }); }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Transport vehicles tab
                            if (_customizeTabIndex == 0) ...[
                              Text(
                                '이동수단 장식',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: transportVehicles.length,
                                itemBuilder: (ctx3, i) {
                                  final v = transportVehicles[i];
                                  final vEmoji = v['emoji'] as String;
                                  final vLabel = v['label'] as String;
                                  final vTier = v['tier'] as int;
                                  final isSelected = selectedEmoji == vEmoji;
                                  // Unlock logic: tier -1 = premium only, 0 = always free, N = requires tierNumber >= N
                                  final currentTierNum = state.currentUser.activityScore.tier.tierNumber;
                                  final isUnlocked = vTier == 0 || (vTier == -1 ? false : currentTierNum >= vTier);
                                  final isPremiumOnly = vTier == -1;
                                  return GestureDetector(
                                    onTap: isUnlocked ? () => setS(() { selectedEmoji = isSelected ? null : vEmoji; }) : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.gold.withValues(alpha: 0.12)
                                            : isPremiumOnly
                                                ? const Color(0xFF8B65FF).withValues(alpha: 0.07)
                                                : AppColors.bgSurface.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.gold.withValues(alpha: 0.65)
                                              : isPremiumOnly
                                                  ? const Color(0xFF8B65FF).withValues(alpha: 0.22)
                                                  : const Color(0xFF1F2D44),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.15), blurRadius: 8)]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            vEmoji,
                                            style: TextStyle(
                                              fontSize: 22,
                                              color: isUnlocked ? null : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            vLabel,
                                            style: TextStyle(
                                              color: isSelected ? AppColors.gold : AppColors.textSecondary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (!isUnlocked)
                                            Text(
                                              isPremiumOnly ? '⭐' : 'Lv.$vTier',
                                              style: TextStyle(
                                                color: isPremiumOnly ? const Color(0xFF8B65FF) : AppColors.gold.withValues(alpha: 0.6),
                                                fontSize: 8,
                                              ),
                                            ),
                                          if (isSelected)
                                            Text('✓', style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      }),

                      // ── 색상 선택 (타워스킨 탭) ──
                      if (_customizeTabIndex == 1) ...[
                        Text(
                          _tl.towerGlowColor,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: presetColors.map((hex) {
                            final color = Color(int.parse('0xFF${hex.substring(1)}'));
                            final isSelected = selectedColor == hex;
                            return GestureDetector(
                              onTap: () => setS(() => selectedColor = hex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.6),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),

                        // ── 지붕 스타일 ──
                        const Text(
                          '🏠 지붕 스타일',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: roofStyles.map((r) {
                            final id = r['id'] as int;
                            final isSel = selectedRoof == id;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setS(() => selectedRoof = id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.gold.withValues(alpha: 0.15)
                                        : AppColors.bgSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.gold.withValues(alpha: 0.5)
                                          : AppColors.textMuted.withValues(alpha: 0.2),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${r['icon']}', style: const TextStyle(fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${r['label']}',
                                        style: TextStyle(
                                          color: isSel ? AppColors.gold : AppColors.textMuted,
                                          fontSize: 9,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),

                        // ── 창문 스타일 ──
                        const Text(
                          '🪟 창문 스타일',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: windowStyles.map((w) {
                            final id = w['id'] as int;
                            final isSel = selectedWindow == id;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setS(() => selectedWindow = id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.gold.withValues(alpha: 0.15)
                                        : AppColors.bgSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.gold.withValues(alpha: 0.5)
                                          : AppColors.textMuted.withValues(alpha: 0.2),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${w['icon']}', style: const TextStyle(fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${w['label']}',
                                        style: TextStyle(
                                          color: isSel ? AppColors.gold : AppColors.textMuted,
                                          fontSize: 9,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),

                        // ── 장식 이모지 ──
                        Text(
                          _tl.towerDecoEmoji,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            GestureDetector(
                              onTap: () => setS(() => selectedEmoji = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selectedEmoji == null
                                      ? AppColors.gold.withValues(alpha: 0.15)
                                      : AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedEmoji == null
                                        ? AppColors.gold.withValues(alpha: 0.5)
                                        : AppColors.textMuted.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '✗',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            ...presetEmojis.map((e) {
                              final isSel = selectedEmoji == e;
                              return GestureDetector(
                                onTap: () => setS(() => selectedEmoji = e),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.gold.withValues(alpha: 0.15)
                                        : AppColors.bgSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.gold.withValues(alpha: 0.5)
                                          : AppColors.textMuted.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(e, style: const TextStyle(fontSize: 22)),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 28),
                      ],

                      // ── 저장 버튼 ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            state.updateTowerSkin(
                              color: selectedColor,
                              accentEmoji: selectedEmoji,
                              roofStyle: selectedRoof,
                              windowStyle: selectedWindow,
                            );
                            Navigator.pop(context);
                            HapticFeedback.mediumImpact();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.bgDeep,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _tl.towerSaveChanges,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 미리보기 지붕 ──────────────────────────────────────────────────────────
  Widget _buildPreviewRoof(Color color, int roofStyle) {
    const w = 48.0;
    const h = 12.0;
    switch (roofStyle) {
      case 1: // 뾰족
        return CustomPaint(
          size: const Size(w, h + 4),
          painter: _PreviewPointedRoofPainter(color: color),
        );
      case 2: // 돔
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.elliptical(24, 12),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.4)],
            ),
          ),
        );
      case 3: // 평지붕
        return Container(
          width: w,
          height: h * 0.5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        );
      case 4: // 안테나
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2,
              height: 10,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Container(
              width: w,
              height: h * 0.5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        );
      default:
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.45)],
            ),
          ),
        );
    }
  }

  // ── 미리보기 층 ────────────────────────────────────────────────────────────
  Widget _buildPreviewFloor(
    Color color,
    double alpha,
    bool isBottom,
    int floorIndex,
    int windowStyle,
  ) {
    const w = 42.0;
    const h = 10.0;
    final lit = (floorIndex * 7 + 3) % 3 != 0;
    final lit2 = (floorIndex * 5 + 1) % 3 != 0;

    Widget window(bool isLit) {
      final baseColor = isLit
          ? const Color(0xFFFFFFCC).withValues(alpha: 0.75)
          : const Color(0xFFFFFFCC).withValues(alpha: 0.15);
      switch (windowStyle) {
        case 1:
          return Container(
            width: 5, height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor,
              boxShadow: isLit ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 3)] : [],
            ),
          );
        case 2:
          return Container(
            width: 5, height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5)),
              color: baseColor,
              boxShadow: isLit ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 3)] : [],
            ),
          );
        case 3:
          return Container(
            width: 8, height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0.5),
              color: baseColor,
              boxShadow: isLit ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 3)] : [],
            ),
          );
        default:
          return Container(
            width: 5, height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: baseColor,
              boxShadow: isLit ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 3)] : [],
            ),
          );
      }
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: alpha),
            const Color(0xFF1E293B).withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.45), width: 2),
          right: BorderSide(color: color.withValues(alpha: 0.45), width: 2),
          bottom: isBottom
              ? BorderSide(color: color.withValues(alpha: 0.45), width: 2)
              : BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        borderRadius: isBottom
            ? const BorderRadius.vertical(bottom: Radius.circular(3))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [window(lit), window(lit2)],
      ),
    );
  }

  void _showMoreMenu(BuildContext ctx, AppState state) {
    final _ml = AppL10n.of(state.currentUser.languageCode);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_rounded,
                color: AppColors.textSecondary,
              ),
              title: Text(
                _ml.towerSettings,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(color: Color(0xFF1F2D44)),
            ListTile(
              leading: const Icon(Icons.mail_rounded, color: AppColors.teal),
              title: Text(
                _ml.towerManageReceived,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _ml.towerTotalCount(state.inbox.length),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showLetterManagement(ctx, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded, color: AppColors.gold),
              title: Text(
                _ml.towerManageSent,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _ml.towerTotalCount(state.sent.length),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showLetterManagement(ctx, state, showSent: true);
              },
            ),
            const Divider(color: Color(0xFF1F2D44)),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.textMuted,
              ),
              title: Text(
                _ml.logout,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmLogout(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
              title: Text(
                _ml.deleteAccount,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLetterManagement(
    BuildContext ctx,
    AppState state, {
    bool showSent = false,
  }) {
    final _ll = AppL10n.of(state.currentUser.languageCode);
    final letters = showSent
        ? state.sent.reversed.toList()
        : state.inbox.reversed.toList();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    showSent
                        ? _ll.towerSentLetterCount(letters.length)
                        : _ll.towerReceivedLetterCount(letters.length),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: letters.isEmpty
                  ? Center(
                      child: Text(
                        _ll.towerNoLetters,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: letters.length,
                      itemBuilder: (_, i) {
                        final l = letters[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1F2D44)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                showSent
                                    ? l.destinationCountryFlag
                                    : l.senderCountryFlag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      showSent
                                          ? '→ ${CountryL10n.localizedName(l.destinationCountry, state.currentUser.languageCode)}'
                                          : (l.isAnonymous
                                                ? _ll.towerAnonymousLetter
                                                : l.senderName),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!showSent && l.status == DeliveryStatus.read)
                                const Text(
                                  '✓',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                  ),
                                )
                              else if (!showSent)
                                const Text(
                                  '●',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                  ),
                                ),
                              if (showSent && l.isReadByRecipient)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppL10n.of(state.currentUser.languageCode).towerRead,
                                    style: const TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext ctx) {
    final _dl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _dl.towerDeleteAccountTitle,
          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
        ),
        content: Text(
          _dl.towerDeleteAccountMsg,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _dl.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.deleteAccount();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              Navigator.of(ctx).pushNamedAndRemoveUntil('/auth', (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(_dl.towerDeleteAccountConfirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    final _dl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _dl.logout,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          _dl.towerLogoutMsg,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _dl.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Firebase 세션 살아있을 때 마지막 위치 Firestore 반영 →
              // 다른 회원 지도에서 타워가 "마지막 접속 위치"로 유지됨
              await ctx.read<AppState>().snapshotUserForLogout();
              await AuthService.logout();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: Text(
              _dl.logout,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizeTab(String label, int index, int current, VoidCallback onTap) {
    final isOn = index == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? AppColors.gold.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn ? AppColors.gold.withValues(alpha: 0.55) : const Color(0xFF1F2D44),
            width: isOn ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOn ? AppColors.gold : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── 통계 카드 ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final double contribution;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.contribution,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D44)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '+${contribution.toStringAsFixed(1)}pts',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Build 177: 3개 정보 pill (생일·경과일·로드맵) 을 4초 순환 단일 pill 로 merge.
/// 생일 당일은 고정, 그 외엔 [경과일, 로드맵] 2개만 순환.
class _LetterTipRotator extends StatefulWidget {
  final AppState state;
  final Color accent;
  final String lang;
  const _LetterTipRotator({
    required this.state,
    required this.accent,
    required this.lang,
  });

  @override
  State<_LetterTipRotator> createState() => _LetterTipRotatorState();
}

class _LetterTipRotatorState extends State<_LetterTipRotator> {
  int _idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _idx = (_idx + 1) % 2);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(widget.lang);
    final state = widget.state;
    // 생일 당일 → 고정 표시 (최고 우선순위).
    if (state.isLetterBirthdayToday) {
      return _pill(
        text: state.letterAgeYears > 0
            ? l.letterBirthdayAnniversary(state.letterAgeYears)
            : l.letterBirthdayFirstDay,
        color: const Color(0xFFFFB86B),
        emoji: '🎂',
      );
    }
    // 순환 tip — 0: 경과일, 1: 로드맵
    final lvl = state.currentLevel;
    String? roadmapText;
    int? roadmapLvl;
    final candidates = <(int, String)>[];
    for (final k in AppState.letterCompanionLevels) {
      if (k > lvl) candidates.add((k, l.letterRoadmapCompanion(k)));
    }
    for (final k in AppState.letterAccessoryLevels) {
      if (k > lvl) candidates.add((k, l.letterRoadmapAccessory(k)));
    }
    final nextCharLvl = (((lvl ~/ 5) + 1) * 5) + 1;
    if (nextCharLvl <= 50) {
      candidates.add((nextCharLvl - 1, l.letterRoadmapCharacter(nextCharLvl - 1)));
    }
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => a.$1.compareTo(b.$1));
      final next = candidates.first;
      roadmapLvl = next.$1;
      roadmapText = next.$2;
    }
    // 로드맵 없을 땐 (Lv 50 달성) 경과일만.
    final showRoadmap = _idx == 1 && roadmapText != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: showRoadmap
          ? _pill(
              key: const ValueKey('roadmap'),
              emoji: '🎯',
              text: '$roadmapText · -${roadmapLvl! - lvl}',
              color: widget.accent,
            )
          : _pill(
              key: const ValueKey('age'),
              emoji: '📫',
              text: l.letterAgeDays(state.daysSinceJoined),
              color: AppColors.textMuted,
            ),
    );
  }

  Widget _pill({
    required String emoji,
    required String text,
    required Color color,
    Key? key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 성취 배지 ─────────────────────────────────────────────────────────────────
class _Achievement {
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;

  const _Achievement({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.unlocked,
  });
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? AppColors.gold.withValues(alpha: 0.15)
            : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: achievement.unlocked
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                ),
              ]
            : null,
        border: Border.all(
          color: achievement.unlocked
              ? AppColors.gold
              : AppColors.textMuted.withValues(alpha: 0.2),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.unlocked ? achievement.emoji : '🔒',
            style: TextStyle(
              fontSize: 26,
              color: achievement.unlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.title,
            style: TextStyle(
              color: achievement.unlocked
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            achievement.desc,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── 타워 그리기 CustomPainter ─────────────────────────────────────────────────
class _TowerPainter extends CustomPainter {
  final int floors;
  final TowerTier tier;
  final double glowIntensity;
  final Color tierColor;

  _TowerPainter({
    required this.floors,
    required this.tier,
    required this.glowIntensity,
    required this.tierColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tier == TowerTier.shack ||
        tier == TowerTier.cottage ||
        tier == TowerTier.house) {
      _drawHouse(canvas, size);
    } else {
      _drawSkyscraper(canvas, size);
    }
  }

  void _drawHouse(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 벽
    final wallPaint = Paint()
      ..color = const Color(0xFF1A2B4A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.5, w * 0.8, h * 0.5),
        const Radius.circular(4),
      ),
      wallPaint,
    );

    // 지붕 (티어 색상)
    final roofPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(w * 0.0, h * 0.5)
      ..lineTo(w * 0.5, h * 0.08)
      ..lineTo(w * 1.0, h * 0.5)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // 창문
    final winPaint = Paint()
      ..color = AppColors.goldLight.withValues(
        alpha: 0.6 + glowIntensity * 0.35,
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.6, w * 0.3, h * 0.2),
        const Radius.circular(3),
      ),
      winPaint,
    );

    // 문
    final doorPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, h * 0.75, w * 0.2, h * 0.25),
        const Radius.circular(3),
      ),
      doorPaint,
    );

    // 글로우
    final glowPaint = Paint()
      ..color = tierColor.withValues(alpha: glowIntensity * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
  }

  void _drawSkyscraper(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Section definitions: [leftFrac, widthFrac, topFrac, heightFrac]
    final sections = [
      [0.07, 0.86, 0.72, 0.28], // BASE
      [0.14, 0.72, 0.54, 0.20], // LOWER-MID
      [0.22, 0.56, 0.37, 0.18], // MID
      [0.30, 0.40, 0.23, 0.16], // UPPER-MID
      [0.37, 0.26, 0.11, 0.14], // UPPER
      [0.42, 0.16, 0.03, 0.09], // CROWN
    ];

    for (int s = 0; s < sections.length; s++) {
      final sd = sections[s];
      final left = w * sd[0];
      final sw = w * sd[1];
      final top = h * sd[2];
      final sh = h * sd[3];
      final rect = Rect.fromLTWH(left, top, sw, sh);

      // Wall — horizontal gradient (darker at edges, lighter in center)
      final wallShader = LinearGradient(
        colors: [
          const Color(0xFF0C1220),
          Color.lerp(const Color(0xFF162240), tierColor.withValues(alpha: 0.20), 0.4)!,
          const Color(0xFF0C1220),
        ],
      ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        Paint()..shader = wallShader,
      );

      // Corner light strips
      final cornerPaint = Paint()
        ..color = tierColor.withValues(alpha: 0.09)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(left, top, 2, sh), cornerPaint);
      canvas.drawRect(Rect.fromLTWH(left + sw - 2, top, 2, sh), cornerPaint);

      // Gold ledge at top of each section
      final ledgePaint = Paint()
        ..color = tierColor.withValues(alpha: 0.72)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(left, top - 1.5, sw, 2.5), ledgePaint);

      // Windows
      if (sh > 10) {
        _drawSectionWindows(canvas, left, top, sw, sh, s);
      }
    }

    // Lobby entrance at base
    final bs = sections[0];
    final baseLeft = w * bs[0];
    final baseW = w * bs[1];
    final baseTop = h * bs[2];
    final baseH = h * bs[3];
    final doorW = baseW * 0.34;
    final doorX = baseLeft + (baseW - doorW) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(doorX, baseTop + baseH * 0.58, doorW, baseH * 0.42),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF050810),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(doorX + 2, baseTop + baseH * 0.60, doorW * 0.45, baseH * 0.38),
        const Radius.circular(1),
      ),
      Paint()..color = tierColor.withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(doorX + doorW * 0.55, baseTop + baseH * 0.60, doorW * 0.43, baseH * 0.38),
        const Radius.circular(1),
      ),
      Paint()..color = tierColor.withValues(alpha: 0.08),
    );

    // Spire
    _drawGoldSpire(canvas, w, h * sections.last[2]);

    // Ground glow
    final groundGlowPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.22 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.15, h - 6, w * 0.70, 10),
      groundGlowPaint,
    );

    // Overall building glow
    final glowPaint = Paint()
      ..color = tierColor.withValues(alpha: glowIntensity * 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.18, h * 0.03, w * 0.64, h * 0.92),
      glowPaint,
    );
  }

  void _drawSectionWindows(Canvas canvas, double left, double top, double sw, double sh, int section) {
    final rng = Random(section * 1337 + 42);
    final rows = (sh / 9).floor().clamp(1, 4);
    final cols = (sw / 10).floor().clamp(2, 9);
    final winW = (sw - 4) / cols;
    final rowH = sh / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final lit = rng.nextDouble() > 0.28;
        final alpha = lit ? 0.55 + rng.nextDouble() * 0.20 : 0.0;
        if (lit) {
          final winPaint = Paint()
            ..color = const Color(0xFFFFC83C).withValues(alpha: alpha)
            ..style = PaintingStyle.fill;
          final wx = left + 2 + col * winW + 1;
          final wy = top + 2 + row * rowH + 1;
          final wh = (rowH - 4).clamp(3.0, 7.0);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(wx, wy, winW - 3, wh),
              const Radius.circular(0.8),
            ),
            winPaint,
          );
          // Subtle window glow
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(wx, wy, winW - 3, wh),
              const Radius.circular(0.8),
            ),
            Paint()
              ..color = const Color(0xFFFFC83C).withValues(alpha: 0.12)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
          );
        } else {
          final wx = left + 2 + col * winW + 1;
          final wy = top + 2 + row * rowH + 1;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(wx, wy, winW - 3, (rowH - 4).clamp(3.0, 7.0)),
              const Radius.circular(0.8),
            ),
            Paint()..color = const Color(0xFF090E1A),
          );
        }
      }
    }
  }

  void _drawGoldSpire(Canvas canvas, double w, double crownTopY) {
    final spireX = w / 2;
    final spireH = (crownTopY * 0.12).clamp(8.0, 22.0);
    final spireTop = crownTopY - spireH;

    // Spire shaft
    final spirePaint = Paint()
      ..color = tierColor.withValues(alpha: 0.88)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(spireX, crownTopY + 1), Offset(spireX, spireTop + 3), spirePaint);

    // Beacon glow ring
    canvas.drawCircle(
      Offset(spireX, spireTop + 2),
      5.5,
      Paint()
        ..color = tierColor.withValues(alpha: glowIntensity * 0.70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Beacon center dot
    canvas.drawCircle(
      Offset(spireX, spireTop + 2),
      2.2,
      Paint()..color = const Color(0xFFFFF8CC).withValues(alpha: 0.92 + glowIntensity * 0.08),
    );
  }

  @override
  bool shouldRepaint(_TowerPainter old) =>
      old.floors != floors ||
      old.tier != tier ||
      old.tierColor != tierColor ||
      (old.glowIntensity - glowIntensity).abs() > 0.01;
}

// ── 스카이라인 배경 ─────────────────────────────────────────────────────────────
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D1A30)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    final rng = Random(42);
    final buildings = 12;
    final segW = size.width / buildings;

    for (int i = 0; i < buildings; i++) {
      final bH = rng.nextDouble() * size.height * 0.7 + size.height * 0.1;
      final bW = segW * (0.5 + rng.nextDouble() * 0.5);
      final bX = i * segW;
      path.lineTo(bX, size.height - bH);
      path.lineTo(bX + bW, size.height - bH);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // 창문 점들
    final winPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final rng2 = Random(i * 7);
      canvas.drawRect(
        Rect.fromLTWH(
          rng2.nextDouble() * size.width,
          rng2.nextDouble() * size.height * 0.7 + 10,
          3,
          4,
        ),
        winPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 미리보기용 뾰족 지붕 페인터 ─────────────────────────────────────────────
class _PreviewPointedRoofPainter extends CustomPainter {
  final Color color;
  const _PreviewPointedRoofPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.45),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PreviewPointedRoofPainter old) => old.color != color;
}
