import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_keys.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/purchase_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../state/app_state.dart';

class PremiumScreen extends StatelessWidget {
  /// [isWelcomeMode] : 최초 가입 후 플랜 선택 화면으로 열릴 때 true.
  /// 뒤로가기 대신 "나중에" 버튼이 표시되며 누르면 /home 으로 이동합니다.
  final bool isWelcomeMode;
  const PremiumScreen({super.key, this.isWelcomeMode = false});

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  void _showPurchaseResultToast(
    BuildContext context, {
    required bool success,
    required String? message,
  }) {
    final fallback = success
        ? '구매가 완료되었습니다.'
        : '구매를 진행하지 못했습니다. 잠시 후 다시 시도해주세요.';
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
        final autoRenewDateText = purchase.nextBillingDate != null
            ? _formatDate(purchase.nextBillingDate!)
            : null;
        final premiumFeatures = state.useValueBasedPremiumCopy
            ? const [
                '🚀  하루 3통 제한 해제 → 최대 30통 발송',
                '📬  더 많이 보내고 답장 기회 최대 10배 확장',
                '📸  이미지+링크 편지로 응답률 강화 (하루 20통)',
                '⚡  특급 배송 하루 3통 + 커스텀 타워로 존재감 강화',
              ]
            : const [
                '✉️  하루 30통 편지 발송',
                '📸  이미지+링크 편지 (하루 20통)',
                '🗼  타워 커스텀 색상 & 이모지',
                '⚡  특급 배송 (하루 3통)',
              ];

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            backgroundColor: AppColors.bgDeep,
            elevation: 0,
            leading: isWelcomeMode
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
            title: Text(
              isWelcomeMode ? '🎉 ${l.premiumPlanTitle}' : 'Letter Go Premium',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 현재 상태 배너 또는 히어로 배너
                if (isPremium || isBrand) ...[
                  _ActivePlanBanner(isBrand: isBrand),
                  const SizedBox(height: 12),
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
                const SizedBox(height: 24),

                // 디버그 전용: 프리미엄 상태 토글
                if (kDebugMode) ...[
                  _DebugPremiumToggle(purchase: purchase),
                  const SizedBox(height: 16),
                ],

                // 플랜 카드 — Free / Premium / Brand
                _PlanCard(
                  emoji: '🆓',
                  name: 'Free',
                  price: '₩0',
                  period: '',
                  badge: isFree ? l.premiumCurrentPlan : '',
                  badgeColor: AppColors.teal,
                  features: const [
                    '✉️  하루 3통 발송 · 월 100통',
                    '🗺️  지도 열람 · 기본 편지 기능',
                  ],
                  isActive: false,
                  onTap: (isFree || purchase.loading)
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.bgCard,
                              title: const Text(
                                '무료 플랜으로 전환',
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
                                    '다음 결제일부터 무료 플랜으로 전환됩니다.\n현재 구독 기간은 계속 이용 가능합니다.',
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
                                    child: const Text(
                                      '💡 실제 해지는 앱스토어 → 설정 → 구독에서 진행해야 합니다',
                                      style: TextStyle(
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
                                  child: const Text(
                                    '취소',
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
                                  child: const Text(
                                    '다운그레이드',
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
                  actionLabel: '다운그레이드',
                ),
                const SizedBox(height: 16),

                _PlanCard(
                  emoji: '⭐',
                  name: 'Premium',
                  price: '₩4,900',
                  period: '/월',
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
                              price: '₩4,900/월',
                              description:
                                  '하루 30통 발송 · 이미지+링크 편지\n타워 커스텀 · 특급 배송',
                            );
                            if (!ok || !context.mounted) return;
                          }
                          final bought = await purchase.buyPremium();
                          if (!context.mounted) return;
                          _showPurchaseResultToast(
                            context,
                            success: bought,
                            message: bought ? null : purchase.errorMessage,
                          );
                        },
                  loading: isBuyingPremium,
                  color: AppColors.gold,
                  actionLabel: isBrand ? '다운그레이드 불가' : '구독 시작 하기',
                ),
                const SizedBox(height: 16),
                _PlanCard(
                  emoji: '🏷️',
                  name: 'Brand / Creator',
                  price: '₩99,000',
                  period: '/월',
                  badge: isBrand ? l.premiumCurrentPlan : '',
                  badgeColor: const Color(0xFFFF8A5C),
                  features: const [
                    '✉️  하루 200통 발송 · 월 10,000통',
                    '💳  추가 발송권 구매 (1,000통 ₩15,000)',
                    '🌍  복수 나라 동시 대량 발송',
                    '✅  공식 인증 배지 표시',
                    '🚫  편지에 신고 버튼 미표시',
                    '⭐  Premium 모든 기능 포함',
                  ],
                  isActive: isBrand,
                  onTap: (isBrand || purchase.loading)
                      ? null
                      : isPremium
                      ? () {
                          final userEmail =
                              state.currentUser.email?.toLowerCase() ?? '';
                          _showBrandUpgradeDialog(
                            context: context,
                            purchase: purchase,
                            userEmail: userEmail,
                          );
                        }
                      : () async {
                          if (purchase.isTestMode) {
                            final ok = await _confirmTestPurchase(
                              context,
                              emoji: '🏷️',
                              productName: 'Brand / Creator',
                              price: '₩99,000/월',
                              description:
                                  '하루 200통 · 인증 배지 · 대량 발송\nPremium 모든 기능 포함',
                            );
                            if (!ok || !context.mounted) return;
                          }
                          final bought = await purchase.buyBrand();
                          if (!context.mounted) return;
                          _showPurchaseResultToast(
                            context,
                            success: bought,
                            message: bought ? null : purchase.errorMessage,
                          );
                        },
                  loading: isBuyingBrand,
                  color: const Color(0xFFFF8A5C),
                  actionLabel: isPremium ? '브랜드 변경 예약' : '구독 시작 하기',
                ),
                const SizedBox(height: 24),

                // 브랜드 추가 발송권 (브랜드 회원만 표시)
                if (isBrand) ...[
                  _SectionTitle(l.premiumSectionExtra),
                  const SizedBox(height: 12),
                  _BrandExtraTile(purchase: purchase),
                  const SizedBox(height: 24),
                ],

                // 선물권 섹션
                _SectionTitle(l.premiumSectionGift),
                const SizedBox(height: 12),
                _GiftCardTile(purchase: purchase),
                const SizedBox(height: 24),

                _SectionTitle('친구 초대 리워드'),
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
                                title: const Text(
                                  '구매 복원',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: const Text(
                                  'iOS에서는 복원 시 Apple 계정 로그인 창이 표시될 수 있습니다.\n동일 Apple ID로 구매한 내역만 복원됩니다.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text(
                                      '취소',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      '복원',
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
                                message: '구매 내역을 복원했습니다.',
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
                        ? '자동갱신일은 구독 시작 후 표시됩니다.'
                        : autoRenewDateText != null
                        ? '자동갱신 예정일: $autoRenewDateText'
                        : '자동갱신일 동기화 중',
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
              ],
            ),
          ),
        );
      },
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
    final color = isBrand ? const Color(0xFFFF8A5C) : AppColors.gold;
    final icon = isBrand ? '🏷️' : '👑';
    final label = isBrand ? 'Brand / Creator 이용 중' : 'Premium 이용 중';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.premiumActivePlan,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.12),
            AppColors.gold.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('👑', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          const Text(
            'Letter Go Premium',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.premiumHeroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (badge.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: TextStyle(
                                color: color,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: period,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 기능 목록 + 버튼
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: isActive
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: color,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppL10n.of(
                                  context
                                      .read<AppState>()
                                      .currentUser
                                      .languageCode,
                                ).premiumActivePlanLabel,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: AppColors.bgDeep,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.bgDeep,
                                  ),
                                )
                              : Text(
                                  actionLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
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
                        productName: '1개월 선물권',
                        price: '₩8,910',
                        description: '친구에게 1개월 프리미엄 선물\n(일반가 ₩9,900, 10% 할인)',
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
              foregroundColor: Colors.white,
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
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
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
          const Text(
            '아래 코드를 친구에게 전달하세요.\n친구가 앱에서 코드를 입력하면\n1개월 프리미엄이 활성화돼요.',
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
                const Text(
                  '유효기간 30일',
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
                    '🎁 Letter Go 프리미엄 선물권\n'
                    '코드: $code\n\n'
                    '앱에서 코드를 입력하면 1개월 프리미엄이 활성화돼요!\n'
                    '✉️ 전 세계 편지로 인연을 만들어보세요.\n'
                    '📲 https://lettergo.app/gift/$code';
                await _showShareOptions(
                  context,
                  shareText,
                  '🎁 Letter Go 프리미엄 선물권 (코드: $code)',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('친구에게 공유하기'),
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
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('코드가 복사되었어요! 친구에게 전달해 주세요 🎁'),
                    backgroundColor: AppColors.teal,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('코드만 복사'),
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
            child: const Text(
              '닫기',
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
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case InviteCodeApplyResult.success:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('친구 초대 리워드가 지급됐어요! 보너스 5통이 추가되었습니다 🎉'),
            backgroundColor: AppColors.teal,
          ),
        );
        break;
      case InviteCodeApplyResult.self:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('내 초대 코드는 직접 입력할 수 없어요.'),
            backgroundColor: AppColors.error,
          ),
        );
        break;
      case InviteCodeApplyResult.alreadyUsed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('초대 코드는 계정당 1회만 사용할 수 있어요.'),
            backgroundColor: AppColors.warning,
          ),
        );
        break;
      case InviteCodeApplyResult.invalid:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('코드 형식을 확인해주세요. (영문/숫자 6자리)'),
            backgroundColor: AppColors.error,
          ),
        );
        break;
      case InviteCodeApplyResult.serverUnavailable:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('서버 연결이 필요해요. 로그인/Firebase 설정을 확인해주세요.'),
            backgroundColor: AppColors.warning,
          ),
        );
        break;
      case InviteCodeApplyResult.networkError:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('서버 검증 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.'),
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
                      '친구 초대 시 보너스 발송권 지급',
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
                      '보유 ${state.inviteRewardCredits}통',
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
              const Text(
                '코드 적용은 서버 검증 후 지급됩니다. (계정당 1회)',
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
                        '내 초대 코드: $inviteCode',
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
                        await Clipboard.setData(
                          ClipboardData(text: inviteCode),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('초대 코드가 복사되었어요.'),
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
                      child: const Text(
                        '복사',
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
                            '✉️ Letter Go — 전 세계와 편지로 연결되는 앱\n\n'
                            '내 초대 코드 👉 $inviteCode\n\n'
                            '코드 입력하면 보너스 발송권 지급!\n'
                            '지도 위 편지가 실시간으로 여행하고,\n'
                            '낯선 이에게 닿는 특별한 경험을 해보세요 🌍\n\n'
                            '📲 앱 다운로드 → https://lettergo.app/invite/$inviteCode';
                        await _showShareOptions(
                          context,
                          shareText,
                          '✉️ Letter Go 초대장 — 코드: $inviteCode',
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
                      label: const Text(
                        '공유',
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
                  hintText: '친구 초대 코드 입력 (예: A1B2C3)',
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
                    foregroundColor: Colors.white,
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
                      : const Text(
                          '초대 코드 적용',
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
    const rows = [
      ['기능', 'Free', 'Premium', 'Brand'],
      ['일일 편지', '3통', '30통', '200통'],
      ['월 편지', '100통', '500통', '10,000통'],
      ['이미지+링크', '✗', '1일 20통', '전부 포함'],
      ['특급 배송', '✗', '1일 3통', '5분 즉시·대량'],
      ['편지 스타일', '기본', '특별', '브랜드'],
      ['대량 발송', '✗', '✗', '✓'],
      ['타워 커스텀', '✗', '✓', '✓'],
      ['인증 배지', '✗', '✗', '✓'],
      ['신고 버튼', '표시', '표시', '미표시'],
      ['월 가격', '무료', '₩4,900', '₩99,000'],
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
            const Text(
              '플랜을 무료로 변경하면:\n'
              '• 현재 결제 기간 종료 후 무료로 전환됩니다\n'
              '• 다음 결제일부터 요금이 청구되지 않아요\n'
              '• 현재 기간 동안은 모든 기능을 계속 이용하실 수 있어요',
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
              child: const Text(
                '💡 실제 해지는 앱스토어 → 설정 → 구독에서 진행해야 합니다',
                style: TextStyle(
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
                const Text(
                  '다음 결제일부터 무료 플랜으로 전환됩니다',
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
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final formatted =
        '${changeDate.year}.${changeDate.month.toString().padLeft(2, '0')}.${changeDate.day.toString().padLeft(2, '0')}';
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
                  isFreeTarget ? '무료 플랜 전환 예정' : 'Brand / Creator 변경 예정',
                  style: TextStyle(
                    color: isFreeTarget ? AppColors.error : AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFreeTarget
                      ? '$formatted 이후 무료로 변경됩니다'
                      : '$formatted 이후 Brand / Creator로 변경됩니다',
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
                const Color(0xFFFF8A5C).withValues(alpha: 0.08),
                const Color(0xFFFF6B35).withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF8A5C).withValues(alpha: 0.3),
            ),
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
                      color: const Color(0xFFFF8A5C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFFFF8A5C),
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
                      color: const Color(0xFFFF8A5C),
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
                      label: '이번 달 한도',
                      value: '${_formatNum(monthlyTotal)}통',
                      sub: extraPacks > 0
                          ? '기본 10,000 + 추가 ${_formatNum(appState.brandExtraMonthlyQuota)}'
                          : '기본 한도',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuotaStat(
                      label: '남은 발송량',
                      value: '${_formatNum(remaining)}통',
                      sub: '이번 달 기준',
                      highlight: remaining < 2000,
                    ),
                  ),
                  if (extraPacks > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuotaStat(
                        label: '추가 구매',
                        value: '$extraPacks팩',
                        sub:
                            '${_formatNum(appState.brandExtraMonthlyQuota)}통 추가',
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '1,000통이 추가되었습니다 ✓',
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
                      backgroundColor: const Color(0xFFFF8A5C),
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                '1,000통 추가 구매 · ₩15,000',
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
              const Center(
                child: Text(
                  '이번 달 말 초기화 · 미사용 발송권 소멸',
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
      return '${(n / 10000).toStringAsFixed(n % 10000 == 0 ? 0 : 1)}만';
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}천';
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
            '🔧 개발자 도구 (DEBUG 전용)',
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
                  userEmail == DebugConstants.testBrandEmail;
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
                          foregroundColor: const Color(0xFFFF8A5C),
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
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
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
            child: const Text(
              '🧪 테스트 모드 — 실제 결제 없음',
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
              child: const Text(
                '구매 (테스트)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
  final effectiveDate =
      purchase.nextBillingDate ?? DateTime.now().add(const Duration(days: 30));
  final formatted =
      '${effectiveDate.year}.${effectiveDate.month.toString().padLeft(2, '0')}.${effectiveDate.day.toString().padLeft(2, '0')}';

  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text(
        '브랜드 플랜으로 변경',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        '$formatted 이후 다음 결제부터 Brand / Creator 플랜(₩99,000/월)으로 변경됩니다.\n\n현재 구독은 $formatted까지 유지됩니다.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            '변경 예약',
            style: TextStyle(
              color: Color(0xFFFF8A5C),
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
        price: '₩99,000/월',
        description: '$formatted 이후 변경 예약\nPremium → Brand 플랜 업그레이드',
      );
      if (!ok) return;
    }
    await purchase.scheduleUpgradeToBrand(userEmail: userEmail);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? '🏷️ Brand / Creator로 변경됐어요! (테스트 즉시 적용)'
                : '⏰ $formatted 이후 Brand / Creator로 변경됩니다.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF8A5C),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '공유하기',
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
                  label: '카카오톡',
                  sublabel: '카카오톡으로 친구에게 보내기',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await Clipboard.setData(ClipboardData(text: shareText));
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
                            content: const Text('카카오톡이 없어요. 텍스트가 복사됐어요 📋'),
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
                  label: '이메일',
                  sublabel: '이메일로 전송하기',
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
                label: '문자 메시지',
                sublabel: isKorean ? '연락처에서 받는 사람 선택' : 'SMS로 전송하기',
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
                label: '링크 복사',
                sublabel: '클립보드에 복사하기',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('클립보드에 복사됐어요 📋'),
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
