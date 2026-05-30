import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_keys.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/purchase_service.dart';
import '../../core/utils/secure_clipboard.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/config/app_links.dart';
import '../../state/app_state.dart';

class PremiumScreen extends StatefulWidget {
  /// [isWelcomeMode] : 최초 가입 후 플랜 선택 화면으로 열릴 때 true.
  /// 뒤로가기 대신 "나중에" 버튼이 표시되며 누르면 /home 으로 이동합니다.
  final bool isWelcomeMode;
  const PremiumScreen({super.key, this.isWelcomeMode = false});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // Build 403 (PR-LL2): "현재 tier 의 다음 단계" 1장만 default 노출.
  //   Free → Premium 카드, Premium → Brand 카드, Brand → 활성 카드 + invite.
  //   "모든 플랜 보기" 토글 시 3장 전체 expand. scroll fatigue + 인지 부담 감소.
  bool _showAllPlans = false;

  @override
  void initState() {
    super.initState();
    // Build 215: 이전 buy 시도가 남긴 stale 에러 클리어 — 화면 다시 들어오면 깨끗.
    // Build 285: 동시에 RevenueCat offerings 강제 refresh — 구독 변경 시 상품
    // 정보가 stale 또는 null 이라 "상품 정보를 불러올 수 없습니다" 가 뜨던 회귀
    // 차단.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final purchase = context.read<PurchaseService>();
      purchase.clearError();
      purchase.refreshOfferings();
    });
  }

  String _formatDate(DateTime date, String langCode) {
    return DateFormat.yMd(langCode).format(date);
  }

  /// Build 271: Premium 결제 직후 1회 혜택 안내 다이얼로그.
  /// Build 273: 한·영 분기 → 14개 언어 풀 번역 (AppL10n 사용).
  Future<void> _showPremiumBenefitsDialog(BuildContext ctx) async {
    final l = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.premiumActivatedTitle,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BenefitRow(emoji: '📍', label: l.benefitPickup),
            const SizedBox(height: 10),
            _BenefitRow(emoji: '⏱', label: l.benefitCooldown),
            const SizedBox(height: 10),
            _BenefitRow(emoji: '📸', label: l.benefitPhoto),
            const SizedBox(height: 10),
            _BenefitRow(emoji: '🎨', label: l.benefitCustom),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF1A1300),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(
              l.premiumActivatedCta,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseResultToast(
    BuildContext context, {
    required bool success,
    required String? message,
  }) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final fallback = success
        ? l10n.premiumPurchaseSuccess
        : l10n.premiumPurchaseFail;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message?.isNotEmpty == true ? message! : fallback),
        backgroundColor: success ? AppColors.teal : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PurchaseService, AppState>(
      builder: (context, purchase, state, _) {
        final isPremium = purchase.isPremium || state.currentUser.isPremium;
        final isBrand = purchase.isBrand || state.currentUser.isBrand;
        final isFree = !isPremium && !isBrand;
        final l = AppL10n.of(state.currentUser.languageCode);
        final isBuyingPremium = purchase.isOperationInProgress(
          PurchaseOperation.premium,
        );
        final isBuyingBrand = purchase.isOperationInProgress(
          PurchaseOperation.brand,
        );
        final isRestoring = purchase.isOperationInProgress(
          PurchaseOperation.restore,
        );
        final langCode = state.currentUser.languageCode;
        final autoRenewDateText = purchase.nextBillingDate != null
            ? _formatDate(purchase.nextBillingDate!, langCode)
            : null;
        // Build 137: Premium 의 핵심 가치는 "본인 홍보 편지 발송" 이라는
        // 유저 결정에 맞춰 순서 재조정. 📸 사진 + 🔗 링크 편지를 최상단으로
        // 올려 "Premium = 나를 알리는 도구" 포지셔닝을 1스캔에 전달.
        // Free 는 줍기만 — 보내기 탭 자체가 Premium Gate.
        final premiumFeatures = [
          '📸  ${l.premiumFeature3}', // 하루 30통 + 사진·링크 (promotion primary)
          '📍  ${l.premiumFeature1}', // 줍기 반경 1km
          '⏱  ${l.premiumFeature2}', // 쿨다운 10분
          // Build 185: 🎨 이모지는 l10n 본문에 포함됨. prefix 제거.
          l.premiumFeature4,
        ];

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            backgroundColor: AppColors.bgDeep,
            elevation: 0,
            leading: widget.isWelcomeMode
                ? TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/home'),
                    child: Text(
                      l.premiumLater,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
            // Build 247: 이전 Premium 서브브랜드 라벨 제거 — 사용자 요청.
            // 'Thiscount Premium' 단일 라벨로 정리.
            title: Text(
              widget.isWelcomeMode
                  ? '🎉 ${l.premiumPlanTitle}'
                  : 'Thiscount Premium',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 현재 상태 배너 또는 히어로 배너
                if (isPremium || isBrand) ...[
                  _ActivePlanBanner(isBrand: isBrand),
                  const SizedBox(height: 12),
                  // Build 271: trial 활성 시 종료일 + 자동결제 경고 배너.
                  // 사용자가 "언제 끝나는지" / "자동결제 되는지" 명확히 인지.
                  // Build 272: trialExpiry null safety — isTrialActive 가 true 라도
                  // RevenueCat 동기화 지연으로 trialExpiry == null 일 가능성 차단.
                  if (purchase.isTrialActive && purchase.trialExpiry != null)
                    _TrialExpiryBanner(
                      expiry: purchase.trialExpiry!,
                      hoursRemaining: purchase.trialHoursRemaining,
                    ),
                  if (purchase.isPendingPlanChange &&
                      purchase.scheduledPlanChangeDate != null &&
                      purchase.scheduledPlanTarget != null)
                    _PendingPlanChangeBanner(
                      changeDate: purchase.scheduledPlanChangeDate!,
                      target: purchase.scheduledPlanTarget!,
                      onCancel: () => purchase.cancelScheduledDowngrade(),
                    ),
                ] else
                  _PremiumHeroBanner(),
                const SizedBox(height: 20),

                // Build 215: 베타 시뮬레이터 안내. Build 271: 두 줄 → 한 줄로.
                if (purchase.isBetaUpgradeSimulator && !isPremium && !isBrand)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🧪', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '베타 · 결제 없이 즉시 활성화',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Build 285: 컬렉션 3섹션 (Aurora/Harvest/Postmaster) 노출
                // 제거 — 플랜 카드 직접 노출이 의사결정 더 빠름.

                // 디버그 전용: 프리미엄 상태 토글
                if (kDebugMode) ...[
                  _DebugPremiumToggle(purchase: purchase),
                  const SizedBox(height: 16),
                ],

                // Build 403 (PR-LL2): 플랜 카드 1장만 default 노출.
                //   현재 tier 의 "다음 단계" 우선 표시 + "모든 플랜 보기" 토글.
                //
                //   Free 사용자: Premium 카드만 (Brand 까지 가는 conversion 0%
                //     이므로 hide). Free 카드 자체는 "현재 사용 중" 정보이지만
                //     의사결정 액션이 없어 default 에서 hide.
                //   Premium 사용자: Brand 카드 (다음 단계). Free 다운그레이드는
                //     destructive 액션이라 toggle 뒤로 숨김.
                //   Brand 사용자: 활성 카드만 노출 (다운그레이드는 toggle 뒤).
                //
                //   _showAllPlans=true 면 3장 전체 노출 (legacy 흐름).
                if (_showAllPlans)
                _PlanCard(
                  emoji: '🆓',
                  name: 'Free',
                  price: '₩0',
                  period: '',
                  badge: isFree
                      ? l.premiumCurrentPlan
                      : purchase.isTrialActive
                      ? '체험 종료 시 자동'
                      : '',
                  badgeColor: AppColors.teal,
                  features: [
                    // Build 118: Free 플랜도 픽업 제약 (반경·쿨다운) 부터
                    // 노출해 Premium 업그레이드 동기를 시각적으로 만든다.
                    '📍  ${l.premiumFreeFeature1}',
                    '✉️  ${l.premiumFreeFeature2}',
                  ],
                  // Build 215: 현재 Free 사용자면 active 로 표시 → "현재 사용 중"
                  // 라벨이 뜨고 "해지 예약" 버튼이 안 뜸. 이전엔 항상 false 라
                  // Free 인 사용자에게 의미 없는 다운그레이드 버튼이 노출됨.
                  // Build 271: trial 중에는 onTap 비활성화 — trial 종료 시 자동
                  // Free 복귀하므로 다운그레이드 예약이 redundant. 라벨도 명확화.
                  isActive: isFree || purchase.isTrialActive,
                  onTap: (isFree || purchase.isTrialActive || purchase.loading)
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.bgCard,
                              title: Text(
                                l.premiumSwitchToFree,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l.premiumSwitchToFreeDesc,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '💡 ${l.premiumCancelViaStore}',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 11,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    l.premiumCancel,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: Text(
                                    l.premiumDowngradeBtn,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await purchase.scheduleDowngradeToFree();
                          }
                        },
                  loading: false,
                  color: AppColors.textMuted,
                  actionLabel: l.premiumDowngradeBtn,
                ),
                if (_showAllPlans) const SizedBox(height: 16),

                // Build 403 (PR-LL2): Premium 카드 — Free 또는 Premium active
                //   사용자에게 노출. Brand 사용자는 default 에서 hide (다운그레이드
                //   는 toggle 후).
                if (_showAllPlans || !isBrand)
                _PlanCard(
                  emoji: '⭐',
                  name: 'Premium',
                  // Build 409 (sim P1.14): 스토어 현지화 가격 우선, fallback ₩4,900.
                  price: purchase.localizedPriceFor(
                          PurchaseProductIds.premiumMonthly) ??
                      '₩4,900',
                  period: l.premiumPerMonth,
                  badge: isPremium && !isBrand ? l.premiumCurrentPlan : '',
                  badgeColor: AppColors.teal,
                  features: premiumFeatures,
                  isActive: isPremium && !isBrand,
                  onTap: (isBrand || isPremium || purchase.loading)
                      ? null
                      : () async {
                          if (purchase.isTestMode) {
                            final ok = await _confirmTestPurchase(
                              context,
                              emoji: '⭐',
                              productName: 'Premium',
                              price: '₩4,900${l.premiumPerMonth}',
                              description: l.premiumPremiumTestDesc,
                            );
                            if (!ok || !context.mounted) return;
                          } else if (purchase.isBetaFreePremium) {
                            final ok = await _confirmBetaPremium(context);
                            if (!ok || !context.mounted) return;
                          }
                          final bought = await purchase.buyPremium();
                          if (bought) {
                            FeedbackService.onPurchaseSuccess();
                          }
                          if (!context.mounted) return;
                          // Build 271: 결제 성공 시 혜택 안내 다이얼로그 1회.
                          // 사용자가 "뭐가 달라졌나" 즉시 인지하도록.
                          if (bought) {
                            await _showPremiumBenefitsDialog(context);
                          } else {
                            _showPurchaseResultToast(
                              context,
                              success: false,
                              message: purchase.errorMessage,
                            );
                          }
                        },
                  loading: isBuyingPremium,
                  color: AppColors.gold,
                  actionLabel: isBrand
                      ? l.premiumNoDowngrade
                      : l.premiumSubscribeBtn,
                ),
                if (_showAllPlans || !isBrand) const SizedBox(height: 16),
                // Build 403 (PR-LL2): Brand 카드 — 모든 사용자에게 노출 (Free 도
                //   비즈니스 계정 가입 가능). 단, 비-Brand Free 는 Premium 카드
                //   먼저 본 다음 Brand 까지 한 번에 노출은 과부하 → "더 보기"
                //   토글로 hide. Premium 사용자에겐 next-step 이므로 default 노출.
                if (_showAllPlans || isPremium || isBrand)
                Builder(
                  builder: (_) {
                    final brandEmail =
                        state.currentUser.email?.toLowerCase() ?? '';
                    // Build 411 (sim security LOW): production 출시 빌드에서는
                    //   하드코딩 admin 이메일 매칭을 무시 (isAdmin 과 동일 정책).
                    //   이전엔 ceo@airony.xyz 가 production 에서도 brand 구매 UI
                    //   활성으로 보였음 (실 entitlement 은 RC 서버 통제라 무해하나
                    //   일관성 위해 가드).
                    final isAdminBrand = !BetaConstants.isProductionBuild &&
                        (brandEmail == DebugConstants.testBrandEmail ||
                            BetaConstants.isAdmin(brandEmail));
                    // 테스터는 브랜드 구매 비활성화 (보이기만 함)
                    final brandDisabled =
                        (kDebugMode && !isAdminBrand && !isBrand) ||
                        (purchase.isBetaFreePremium && !isBrand);
                    return _PlanCard(
                      emoji: '🏷️',
                      name: 'Brand / Creator',
                      // Build 409 (sim P1.14): 스토어 현지화 가격 우선, fallback ₩99,000.
                      price: purchase.localizedPriceFor(
                              PurchaseProductIds.brandMonthly) ??
                          '₩99,000',
                      period: l.premiumPerMonth,
                      badge: isBrand
                          ? l.premiumCurrentPlan
                          : brandDisabled
                          ? purchase.isBetaFreePremium
                                ? l.koEn('베타 기간 미지원', 'Not Available in Beta')
                                : l.koEn('관리자 전용', 'Admin Only')
                          : '',
                      badgeColor: isBrand
                          ? AppColors.coupon
                          : AppColors.textMuted,
                      features: [
                        '✉️  ${l.premiumBrandFeature1}',
                        '💳  ${l.premiumBrandFeature2}',
                        '🌍  ${l.premiumBrandFeature3}',
                        '✅  ${l.premiumBrandFeature4}',
                        '🚫  ${l.premiumBrandFeature5}',
                        '⭐  ${l.premiumBrandFeature6}',
                      ],
                      isActive: isBrand,
                      onTap: (isBrand || purchase.loading || brandDisabled)
                          ? null
                          : isPremium
                          ? () {
                              _showBrandUpgradeDialog(
                                context: context,
                                purchase: purchase,
                                userEmail: brandEmail,
                              );
                            }
                          : () async {
                              if (purchase.isTestMode) {
                                final ok = await _confirmTestPurchase(
                                  context,
                                  emoji: '🏷️',
                                  productName: 'Brand / Creator',
                                  price: '₩99,000${l.premiumPerMonth}',
                                  description: l.premiumBrandTestDesc,
                                );
                                if (!ok || !context.mounted) return;
                              }
                              final bought = await purchase.buyBrand();
                              if (bought) {
                                FeedbackService.onPurchaseSuccess();
                              }
                              if (!context.mounted) return;
                              _showPurchaseResultToast(
                                context,
                                success: bought,
                                message: bought ? null : purchase.errorMessage,
                              );
                            },
                      loading: isBuyingBrand,
                      color: brandDisabled
                          ? AppColors.textMuted
                          : AppColors.coupon,
                      actionLabel: isBrand
                          ? l.premiumNoDowngrade
                          : brandDisabled
                          ? purchase.isBetaFreePremium
                                ? l.koEn(
                                    '정식 출시 후 이용 가능',
                                    'Available After Launch',
                                  )
                                : l.koEn(
                                    '관리자 승급 필요',
                                    'Admin Promotion Required',
                                  )
                          : isPremium
                          ? l.premiumBrandSchedule
                          : l.premiumSubscribeBtn,
                    );
                  },
                ),
                // Build 403 (PR-LL2): "모든 플랜 보기 / 접기" 토글.
                //   default 1장 노출 후 사용자가 비교를 원할 때만 expand.
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _showAllPlans = !_showAllPlans;
                    }),
                    icon: Icon(
                      _showAllPlans
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    label: Text(
                      _showAllPlans
                          ? l.koEn('플랜 비교 접기', 'Collapse plans')
                          : l.koEn('모든 플랜 비교', 'Compare all plans'),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 브랜드 추가 발송권 (브랜드 회원만 표시)
                if (isBrand) ...[
                  _SectionTitle(l.premiumSectionExtra),
                  const SizedBox(height: 12),
                  _BrandExtraTile(purchase: purchase),
                  const SizedBox(height: 24),
                ],

                // Build 373 (PR-DD2 P0 #2 잔여): 선물권 섹션 hide.
                //   PR-CC1 에서 buyGiftCard 자체는 차단했지만 UI 가 노출되면
                //   사용자가 클릭 → "준비 중" 에러 → 혼란. 서버 redemption 흐름
                //   (Firestore gift_codes + redeem UI) 완성될 때까지 섹션 비활성.
                // _SectionTitle(l.premiumSectionGift),
                // const SizedBox(height: 12),
                // _GiftCardTile(purchase: purchase),
                // const SizedBox(height: 24),

                _SectionTitle(l.premiumSectionInvite),
                const SizedBox(height: 12),
                const _InviteRewardTile(),
                const SizedBox(height: 24),

                // 기능 비교표
                _SectionTitle(l.premiumSectionCompare),
                const SizedBox(height: 12),
                const _FeatureCompareTable(),
                const SizedBox(height: 24),

                // 오류 메시지
                if (purchase.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      purchase.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                // 구매 복원
                Center(
                  child: TextButton(
                    onPressed: purchase.loading
                        ? null
                        : () async {
                            final shouldRestore = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.bgCard,
                                title: Text(
                                  l.premiumRestoreTitle,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  l.premiumRestoreDesc,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      l.premiumCancel,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      l.premiumRestoreBtn,
                                      style: TextStyle(
                                        color: AppColors.teal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (shouldRestore != true) return;
                            final restored = await purchase.restorePurchases();
                            if (!context.mounted) return;
                            if (restored) {
                              _showPurchaseResultToast(
                                context,
                                success: true,
                                message: l.premiumRestoreSuccess,
                              );
                            } else if (purchase.errorMessage != null) {
                              _showPurchaseResultToast(
                                context,
                                success: false,
                                message: purchase.errorMessage,
                              );
                            }
                          },
                    child: Text(
                      isRestoring
                          ? '${l.premiumRestorePurchase}...'
                          : l.premiumRestorePurchase,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    isFree
                        ? l.premiumAutoRenewAfterSub
                        : autoRenewDateText != null
                        ? '${l.premiumAutoRenewDate}: $autoRenewDateText'
                        : l.premiumAutoRenewSync,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l.premiumAutoRenew,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ),
                // Build 297 (P0 audit, Apple 3.1.2): paywall 에 Terms 와 Privacy
                // 링크 노출. 자동갱신 구독에는 두 링크가 모두 필수 (5.1.1 / 3.1.2).
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      // Build 299/300: paywall 의 Terms/Privacy 링크를 사용자
                      // 언어 (languageCode) 기준으로 분기 — country 기반은
                      // '대한민국' 거주 비한국인 사용자 등 mismatch 케이스
                      // 노출 (Apple 3.1.2 i18n 일관성).
                      onPressed: () => launchUrl(
                        Uri.parse(
                          AppLinks.termsForLanguage(
                            state.currentUser.languageCode,
                          ),
                        ),
                        mode: LaunchMode.inAppBrowserView,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l.settingsTerms,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(
                          AppLinks.privacyPolicyForLanguage(
                            state.currentUser.languageCode,
                          ),
                        ),
                        mode: LaunchMode.inAppBrowserView,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l.settingsPrivacy,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Build 271: Premium 결제 후 혜택 row ────────────────────────────────
class _BenefitRow extends StatelessWidget {
  final String emoji;
  final String label;
  const _BenefitRow({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Build 271: 무료 체험 종료 배너 ────────────────────────────────────
// Build 273: 한·영 분기 → 14개 언어 풀 번역 (AppL10n).
class _TrialExpiryBanner extends StatelessWidget {
  final DateTime expiry;
  final int hoursRemaining;

  const _TrialExpiryBanner({
    required this.expiry,
    required this.hoursRemaining,
  });

  String _formatRemaining(AppL10n l) {
    if (hoursRemaining <= 0) return l.trialExpiringSoon;
    if (hoursRemaining < 24) return l.trialHoursLeft(hoursRemaining);
    final days = (hoursRemaining / 24).ceil();
    return l.trialDaysLeft(days);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final urgent = hoursRemaining < 24;
    final color = urgent ? AppColors.coupon : AppColors.gold;
    final title = l.trialBannerTitle(_formatRemaining(l));
    final subtitle = l.trialBannerSubtitle;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Row(
        children: [
          Text(urgent ? '⚠️' : '🎁', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
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

// ── 구독 중 배너 ──────────────────────────────────────────────────────────────
class _ActivePlanBanner extends StatelessWidget {
  final bool isBrand;
  const _ActivePlanBanner({required this.isBrand});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final color = isBrand ? AppColors.coupon : AppColors.gold;
    final ink = isBrand ? const Color(0xFF1A0008) : const Color(0xFF1A1300);
    final label = isBrand
        ? 'Brand / Creator ${l.premiumActiveLabel}'
        : 'Premium ${l.premiumActiveLabel}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.66,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.premiumActivePlan,
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
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

// ── 히어로 배너 ───────────────────────────────────────────────────────────────
class _PremiumHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AIR MAIL · PREMIUM',
            style: TextStyle(
              color: Color(0xB31A1300),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.66,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Thiscount\nPremium.',
            style: TextStyle(
              color: Color(0xFF1A1300),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.premiumHeroTitle,
            style: const TextStyle(
              color: Color(0xA61A1300),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 플랜 카드 ─────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String price;
  final String period;
  final String badge;
  final Color badgeColor;
  final List<String> features;
  final VoidCallback? onTap;
  final bool loading;
  final Color color;
  final bool isActive;
  final String actionLabel;

  const _PlanCard({
    required this.emoji,
    required this.name,
    required this.price,
    required this.period,
    required this.badge,
    required this.badgeColor,
    required this.features,
    required this.onTap,
    required this.loading,
    required this.color,
    required this.actionLabel,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlight = color == AppColors.gold || color == AppColors.coupon;
    final cardBg = isHighlight ? color : AppColors.bgCard;
    final ink = isHighlight
        ? (color == AppColors.gold
              ? const Color(0xFF1A1300)
              : const Color(0xFF1A0008))
        : AppColors.textPrimary;
    final muted = isHighlight
        ? ink.withValues(alpha: 0.65)
        : AppColors.textSecondary;
    final divider = isHighlight
        ? ink.withValues(alpha: 0.16)
        : AppColors.bgSurface;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — eyebrow + 큰 가격
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.66,
                      ),
                    ),
                    if (badge.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlight ? ink : badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge.toUpperCase(),
                          style: TextStyle(
                            color: isHighlight ? cardBg : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: TextStyle(
                          color: ink,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: period,
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: divider),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 16, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: ink,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(height: 1, color: divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: isActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isHighlight
                            ? ink.withValues(alpha: 0.12)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        AppL10n.of(
                          context.read<AppState>().currentUser.languageCode,
                        ).premiumActivePlanLabel,
                        style: TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: loading ? null : onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isHighlight ? ink : AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cardBg,
                                ),
                              )
                            : Text(
                                actionLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isHighlight
                                      ? cardBg
                                      : AppColors.bgDeep,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 선물권 타일 ───────────────────────────────────────────────────────────────
class _GiftCardTile extends StatelessWidget {
  final PurchaseService purchase;
  const _GiftCardTile({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final isBuyingGift = purchase.isOperationInProgress(
      PurchaseOperation.giftCard,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.premiumGiftCard,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '₩8,910 ',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: l.premiumGiftCardDiscount,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.premiumGiftCardDesc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: purchase.loading
                ? null
                : () async {
                    // 테스트 모드: 가짜 결제 확인 다이얼로그
                    if (purchase.isTestMode) {
                      final ok = await _confirmTestPurchase(
                        context,
                        emoji: '🎁',
                        productName: l.premiumGiftCard1Month,
                        price: '₩8,910',
                        description: l.premiumGiftTestDesc,
                      );
                      if (!ok || !context.mounted) return;
                    }
                    final success = await purchase.buyGiftCard();
                    if (!context.mounted) return;
                    if (success) {
                      // 선물 코드 생성 (실제 서비스에서는 서버에서 발급)
                      final ts = DateTime.now().millisecondsSinceEpoch;
                      final code =
                          'LTGO-${ts.toString().substring(5, 10)}-PREM';
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => _GiftCardSuccessDialog(code: code),
                      );
                    } else if (purchase.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(purchase.errorMessage!),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.tealInk,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isBuyingGift
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l.premiumBuyBtn,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 선물권 구매 성공 다이얼로그 ──────────────────────────────────────────────
class _GiftCardSuccessDialog extends StatelessWidget {
  final String code;
  const _GiftCardSuccessDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            l.premiumGiftSuccess,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.premiumGiftCodeDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // 코드 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.premiumGiftValidity,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 공유 버튼 (Native Share Sheet — 카카오톡·왓츠앱·텔레그램·라인·iMessage·이메일 등)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!context.mounted) return;
                final shareText =
                    '🎁 Thiscount ${l.premiumGiftShareTitle}\n'
                    '${l.premiumGiftShareCode}: $code\n\n'
                    '${l.premiumGiftShareBody}\n'
                    '📲 https://thiscount.io/gift/$code';
                await _showShareOptions(
                  context,
                  shareText,
                  '🎁 Thiscount ${l.premiumGiftShareTitle} (${l.premiumGiftShareCode}: $code)',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: Text(l.premiumShareToFriend),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 코드 복사 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                // Build 363 (PR-BB1 hotfix): gift card 코드는 사용자가 KakaoTalk
                //   / iMessage 등으로 친구에게 공유하기 위한 결제 자산. 45s TTL
                //   ephemeral 적용은 회귀 — paste 실패 시 결제 자금 손실.
                //   copyPersistent 로 통일 (직전 ephemeral timer 는 cancel).
                await SecureClipboard.copyPersistent(code);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.premiumCodeCopied),
                    backgroundColor: AppColors.teal,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l.premiumCopyCode),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: BorderSide(color: AppColors.teal.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.premiumClose,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteRewardTile extends StatefulWidget {
  const _InviteRewardTile();

  @override
  State<_InviteRewardTile> createState() => _InviteRewardTileState();
}

class _InviteRewardTileState extends State<_InviteRewardTile> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _applyingInvite = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _showApplyResult(InviteCodeApplyResult result) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case InviteCodeApplyResult.success:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premiumInviteSuccess),
            backgroundColor: AppColors.teal,
          ),
        );
        break;
      case InviteCodeApplyResult.self:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premiumInviteSelf),
            backgroundColor: AppColors.error,
          ),
        );
        break;
      case InviteCodeApplyResult.alreadyUsed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premiumInviteAlreadyUsed),
            backgroundColor: AppColors.warning,
          ),
        );
        break;
      case InviteCodeApplyResult.invalid:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premiumInviteInvalid),
            backgroundColor: AppColors.error,
          ),
        );
        break;
      case InviteCodeApplyResult.serverUnavailable:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premiumInviteServerUnavailable),
            backgroundColor: AppColors.warning,
          ),
        );
        break;
      case InviteCodeApplyResult.networkError:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premiumInviteNetworkError),
            backgroundColor: AppColors.error,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final inviteCode = state.myInviteCode;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.premiumInviteRewardTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${l10n.premiumInviteCreditsOwned} ${state.inviteRewardCredits}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.premiumInviteOncePerAccount,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.premiumMyInviteCode}: $inviteCode',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        // Build 363 (PR-BB1 hotfix): invite code 는 친구 공유
                        //   목적 — TTL 적용은 use case 위반. paste 실패 시
                        //   추천 보너스 손실.
                        await SecureClipboard.copyPersistent(inviteCode);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.premiumInviteCodeCopied),
                            backgroundColor: AppColors.teal,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teal,
                        side: BorderSide(
                          color: AppColors.teal.withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        l10n.premiumCopy,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (!context.mounted) return;
                        final shareText =
                            '✉️ Thiscount — ${l10n.premiumInviteShareTagline}\n\n'
                            '${l10n.premiumMyInviteCode} 👉 $inviteCode\n\n'
                            '${l10n.premiumInviteShareBody}\n\n'
                            '📲 https://thiscount.io/invite/$inviteCode';
                        await _showShareOptions(
                          context,
                          shareText,
                          '✉️ Thiscount ${l10n.premiumInviteShareSubject} — ${l10n.premiumGiftShareCode}: $inviteCode',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 13),
                      label: Text(
                        l10n.premiumShare,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l10n.premiumInviteCodeHint,
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.bgDeep,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.textMuted.withValues(alpha: 0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.textMuted.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.teal,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyingInvite
                      ? null
                      : () async {
                          setState(() => _applyingInvite = true);
                          final result = await state.applyInviteCode(
                            _inviteCodeController.text,
                          );
                          if (!mounted) return;
                          if (result == InviteCodeApplyResult.success) {
                            _inviteCodeController.clear();
                          }
                          _showApplyResult(result);
                          setState(() => _applyingInvite = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.tealInk,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _applyingInvite
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.premiumApplyInviteCode,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 섹션 타이틀 ───────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── 기능 비교표 ───────────────────────────────────────────────────────────────
class _FeatureCompareTable extends StatelessWidget {
  const _FeatureCompareTable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final rows = [
      [l10n.premiumCompareFeature, 'Free', 'Premium', 'Brand'],
      [l10n.premiumCompareDailyLetters, '3', '30', '200'],
      [l10n.premiumCompareMonthlyLetters, '100', '500', '10,000'],
      [
        l10n.premiumCompareImageLink,
        '✗',
        l10n.premiumCompare20PerDay,
        l10n.premiumCompareAllIncluded,
      ],
      [
        l10n.premiumCompareExpress,
        '✗',
        l10n.premiumCompare3PerDay,
        l10n.premiumCompareInstantBulk,
      ],
      [
        l10n.premiumCompareStyle,
        l10n.premiumCompareBasic,
        l10n.premiumCompareSpecial,
        l10n.premiumCompareBrand,
      ],
      [l10n.premiumCompareBulkSend, '✗', '✗', '✓'],
      [l10n.premiumCompareTowerCustom, '✗', '✓', '✓'],
      [l10n.premiumCompareBadge, '✗', '✗', '✓'],
      [
        l10n.premiumCompareReportBtn,
        l10n.premiumCompareShown,
        l10n.premiumCompareShown,
        l10n.premiumCompareHidden,
      ],
      [
        l10n.premiumCompareMonthlyPrice,
        l10n.premiumCompareFree,
        '₩4,900',
        '₩99,000',
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isHeader = i == 0;
          final isLast = i == rows.length - 1;

          return Container(
            decoration: BoxDecoration(
              color: isHeader
                  ? AppColors.gold.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.vertical(
                top: isHeader ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              border: i > 0
                  ? Border(
                      top: BorderSide(
                        color: AppColors.textMuted.withValues(alpha: 0.1),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: row.asMap().entries.map((c) {
                final isFeatureCol = c.key == 0;
                return Expanded(
                  flex: isFeatureCol ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      c.value,
                      textAlign: isFeatureCol
                          ? TextAlign.left
                          : TextAlign.center,
                      style: TextStyle(
                        color: isHeader
                            ? AppColors.gold
                            : (isFeatureCol
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary),
                        fontSize: 12,
                        fontWeight: (isHeader || isFeatureCol)
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 플랜 해지 섹션 ────────────────────────────────────────────────────────────
class _DowngradeSection extends StatelessWidget {
  final bool isBrand;
  final PurchaseService purchase;
  const _DowngradeSection({required this.isBrand, required this.purchase});

  Future<void> _confirmDowngrade(BuildContext context) async {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.premiumDowngradeTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.premiumDowngradeDialogBody,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '💡 ${l.premiumCancelViaStore}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.premiumCancelDowngrade,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              l.premiumDowngradeBtn,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await purchase.scheduleDowngradeToFree();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.premiumDowngradeTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.premiumDowngradeNextBilling,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _confirmDowngrade(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l.premiumDowngradeBtn,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 플랜 변경 예약 배너 ───────────────────────────────────────────────────────
class _PendingPlanChangeBanner extends StatelessWidget {
  final DateTime changeDate;
  final ScheduledPlanTarget target;
  final VoidCallback onCancel;
  const _PendingPlanChangeBanner({
    required this.changeDate,
    required this.target,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = context.read<AppState>().currentUser.languageCode;
    final l = AppL10n.of(langCode);
    final formatted = DateFormat.yMd(langCode).format(changeDate);
    final isFreeTarget = target == ScheduledPlanTarget.free;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFreeTarget
            ? AppColors.error.withValues(alpha: 0.06)
            : AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFreeTarget
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Text('⏰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFreeTarget
                      ? l.premiumPendingFreeChange
                      : l.premiumPendingBrandChange,
                  style: TextStyle(
                    color: isFreeTarget ? AppColors.error : AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFreeTarget
                      ? '$formatted ${l.premiumPendingFreeAfter}'
                      : '$formatted ${l.premiumPendingBrandAfter}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              l.premiumCancelDowngrade,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 브랜드 추가 발송권 구매 타일 ────────────────────────────────────────────
class _BrandExtraTile extends StatefulWidget {
  final PurchaseService purchase;
  const _BrandExtraTile({required this.purchase});

  @override
  State<_BrandExtraTile> createState() => _BrandExtraTileState();
}

class _BrandExtraTileState extends State<_BrandExtraTile> {
  bool _buying = false;
  bool _showSuccess = false;

  Future<void> _onBuy(AppState appState) async {
    if (_buying) return;
    setState(() {
      _buying = true;
    });

    final ok = await widget.purchase.buyBrandExtra(appState);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _buying = false;
        _showSuccess = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _showSuccess = false);
    } else {
      setState(() {
        _buying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, appState, _) {
        final l10n = AppL10n.of(appState.currentUser.languageCode);
        final isBuyingBrandExtra = widget.purchase.isOperationInProgress(
          PurchaseOperation.brandExtra,
        );
        final extraPacks = appState.brandExtraMonthlyQuota ~/ 1000;
        final monthlyTotal = 10000 + appState.brandExtraMonthlyQuota;
        final remaining = appState.remainingMonthlySendCount;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.coupon.withValues(alpha: 0.08),
                AppColors.coupon.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.coupon.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coupon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.coupon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppL10n.of(
                            context.read<AppState>().currentUser.languageCode,
                          ).premiumExtraTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppL10n.of(
                            context.read<AppState>().currentUser.languageCode,
                          ).premiumExtraDesc,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 가격 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.coupon,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '₩15,000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0x20FF8A5C), height: 1),
              const SizedBox(height: 14),

              // 현재 쿼터 상태
              Row(
                children: [
                  Expanded(
                    child: _QuotaStat(
                      label: l10n.premiumQuotaMonthlyLimit,
                      value: _formatNum(monthlyTotal),
                      sub: extraPacks > 0
                          ? '${l10n.premiumQuotaBase} 10,000 + ${l10n.premiumQuotaExtra} ${_formatNum(appState.brandExtraMonthlyQuota)}'
                          : l10n.premiumQuotaBaseLimit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuotaStat(
                      label: l10n.premiumQuotaRemaining,
                      value: _formatNum(remaining),
                      sub: l10n.premiumQuotaThisMonth,
                      highlight: remaining < 2000,
                    ),
                  ),
                  if (extraPacks > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuotaStat(
                        label: l10n.premiumQuotaExtraPurchase,
                        value: '$extraPacks ${l10n.premiumQuotaPacks}',
                        sub:
                            '${_formatNum(appState.brandExtraMonthlyQuota)} ${l10n.premiumQuotaExtraAdded}',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // 구매 버튼 또는 성공 메시지
              if (_showSuccess)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade600.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        l10n.premiumExtraAdded,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (widget.purchase.loading || _buying)
                        ? null
                        : () => _onBuy(appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coupon,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.bgCard,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: (isBuyingBrandExtra || _buying)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                l10n.premiumExtraBuyBtn,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.premiumExtraResetNote,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNum(int n) {
    if (n >= 10000)
      return '${(n / 10000).toStringAsFixed(n % 10000 == 0 ? 0 : 1)}K';
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }
}

class _QuotaStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool highlight;

  const _QuotaStat({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.red.shade900.withValues(alpha: 0.15)
            : AppColors.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? Colors.red.shade700.withValues(alpha: 0.3)
              : AppColors.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.red.shade300 : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ── 디버그 전용: 프리미엄 상태 토글 ──────────────────────────────────────────
class _DebugPremiumToggle extends StatelessWidget {
  final PurchaseService purchase;
  const _DebugPremiumToggle({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Dev Tools (DEBUG)',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final userEmail =
                  context.read<AppState>().currentUser.email?.toLowerCase() ??
                  '';
              final isTestBrandAccount =
                  userEmail == DebugConstants.testBrandEmail ||
                  BetaConstants.isAdmin(userEmail);
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          purchase.debugSetPremium(premium: true, brand: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '⭐ Premium ON',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  if (isTestBrandAccount) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => purchase.debugSetPremium(
                          premium: true,
                          brand: true,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coupon,
                          side: BorderSide(
                            color: const Color(
                              0xFFFF8A5C,
                            ).withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '🏷️ Brand ON',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: BorderSide(
                            color: AppColors.textMuted.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '🏷️ Brand 🔒',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => purchase.debugSetPremium(
                        premium: false,
                        brand: false,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: BorderSide(
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Free OFF',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── 테스트 모드 구매 확인 바텀시트 ──────────────────────────────────────────────
/// 테스트 모드(디버그 빌드)에서 실제 App Store/Play Store 대신 보여주는 가짜 구매 UI.
/// confirmed: true → 구매 진행 / false → 취소
Future<bool> _confirmTestPurchase(
  BuildContext context, {
  required String emoji,
  required String productName,
  required String price,
  required String description,
}) async {
  final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        24,
        8,
        24,
        MediaQuery.of(ctx).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 테스트 모드 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              l10n.premiumTestModeBadge,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            productName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.premiumTestPurchaseBtn,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.premiumCancel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
  return result == true;
}

// ── 베타 무료 프리미엄 확인 다이얼로그 ──────────────────────────────────────────
/// 베타 테스트 기간 중 프리미엄을 무료로 활성화할 때 보여주는 확인 다이얼로그.
Future<bool> _confirmBetaPremium(BuildContext context) async {
  final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        24,
        8,
        24,
        MediaQuery.of(ctx).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 베타 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              l10n.koEn('🎉 베타 테스터 혜택', '🎉 Beta Tester Benefit'),
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('⭐', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          const Text(
            'Premium',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.koEn('무료', 'FREE'),
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.koEn(
              '베타 테스트 기간 동안 프리미엄 기능을\n무료로 체험하실 수 있습니다.\n정식 출시 후 구독이 필요합니다.',
              'You can try Premium features for free\nduring the beta test period.\nSubscription required after official launch.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.koEn('프리미엄 활성화', 'Activate Premium'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.premiumCancel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
  return result == true;
}

// ── 브랜드 업그레이드 예약 다이얼로그 ──────────────────────────────────────────
void _showBrandUpgradeDialog({
  required BuildContext context,
  required PurchaseService purchase,
  required String userEmail,
}) {
  final langCode = context.read<AppState>().currentUser.languageCode;
  final l10n = AppL10n.of(langCode);
  final effectiveDate =
      purchase.nextBillingDate ?? DateTime.now().add(const Duration(days: 30));
  final formatted = DateFormat.yMd(langCode).format(effectiveDate);
  // Build 409 (sim P1.16): production 에선 buyBrand() 가 즉시 결제됨 (PR-CC1).
  //   따라서 다이얼로그 본문/버튼도 '다음 결제일부터 예약' 이 아니라 '즉시
  //   업그레이드/결제' 로 분기해야 함. 이전엔 snackbar 만 분기되고 다이얼로그는
  //   항상 예약 카피라 production 사용자에게 거짓 안내였음. test/beta 는 예약 유지.
  final isProduction = !kDebugMode &&
      !purchase.isTestMode &&
      !purchase.isBetaUpgradeSimulator;
  final dialogBody = isProduction
      ? l10n.koEn(
          '지금 Brand/크리에이터 플랜으로 즉시 전환되며 바로 결제됩니다.',
          'You will switch to the Brand/Creator plan now and be charged immediately.',
        )
      : '${l10n.premiumBrandUpgradeDesc1} $formatted ${l10n.premiumBrandUpgradeDesc2}';
  final confirmLabel = isProduction
      ? l10n.koEn('지금 업그레이드', 'Upgrade now')
      : l10n.premiumBrandSchedule;

  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: Text(
        l10n.premiumBrandUpgradeTitle,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        dialogBody,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.premiumCancel,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: AppColors.coupon,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  ).then((confirmed) async {
    if (confirmed != true) return;
    // 테스트 모드: 실제 결제 확인 다이얼로그 (App Store/Play Store 대체)
    if (purchase.isTestMode && context.mounted) {
      final ok = await _confirmTestPurchase(
        context,
        emoji: '🏷️',
        productName: 'Brand / Creator',
        price: '₩99,000${l10n.premiumPerMonth}',
        description: '$formatted ${l10n.premiumBrandUpgradeScheduleDesc}',
      );
      if (!ok) return;
    }
    await purchase.scheduleUpgradeToBrand(userEmail: userEmail);
    if (context.mounted) {
      // Build 383 (PR-FF1 audit AA1 후속): production 에선 buyBrand() 즉시
      //   결제 (PR-CC1 P0 #1 fix 후) → schedule 카피 부정확. 결제 완료
      //   메시지로 분기. test/beta 모드만 schedule 카피 유지.
      final isProduction = !kDebugMode && !purchase.isTestMode &&
          !purchase.isBetaUpgradeSimulator;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isProduction
                ? '✅ ${l10n.premiumBrandUpgradeTestSuccess}'
                : (kDebugMode
                    ? l10n.premiumBrandUpgradeTestSuccess
                    : '⏰ $formatted ${l10n.premiumPendingBrandAfter}'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.coupon,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  });
}

// ── 로케일 기반 공유 바텀시트 ─────────────────────────────────────────────────
/// 한국 로케일이면 카카오톡+문자, 해외면 이메일+문자 옵션을 제공합니다.
Future<void> _showShareOptions(
  BuildContext context,
  String shareText,
  String subject,
) async {
  final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
  final locale = Localizations.localeOf(context);
  final isKorean = locale.languageCode == 'ko' || locale.countryCode == 'KR';

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.premiumShareTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isKorean)
                _ShareOptionTile(
                  emoji: '💬',
                  label: l10n.premiumShareKakao,
                  sublabel: l10n.premiumShareKakaoDesc,
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    // Build 365 (PR-BB4): share text 도 SecureClipboard 통일 —
                    //   직전 ephemeral timer cancel + iOS 14+ paste prompt
                    //   회피.
                    await SecureClipboard.copyPersistent(shareText);
                    final kakaoUri = Uri.parse('kakaotalk://');
                    if (await canLaunchUrl(kakaoUri)) {
                      await launchUrl(
                        kakaoUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.premiumShareKakaoMissing),
                            backgroundColor: AppColors.bgDeep,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                )
              else
                _ShareOptionTile(
                  emoji: '📧',
                  label: l10n.premiumShareEmail,
                  sublabel: l10n.premiumShareEmailDesc,
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final uri = Uri(
                      scheme: 'mailto',
                      query:
                          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(shareText)}',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              _ShareOptionTile(
                emoji: '💬',
                label: l10n.premiumShareSms,
                sublabel: l10n.premiumShareSmsDesc,
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final uri = Uri(
                    scheme: 'sms',
                    query: 'body=${Uri.encodeComponent(shareText)}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _ShareOptionTile(
                emoji: '📋',
                label: l10n.premiumShareCopyLink,
                sublabel: l10n.premiumShareCopyLinkDesc,
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  // Build 365 (PR-BB4): SecureClipboard 통일 (위와 동일 이유).
                  await SecureClipboard.copyPersistent(shareText);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.premiumClipboardCopied),
                        backgroundColor: AppColors.teal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );
}

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
