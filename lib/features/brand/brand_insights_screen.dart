import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/redemption_code.dart';
import '../../models/brand_insights.dart';
import '../../state/app_state.dart';

/// Build 323: Brand 사용자 전용 1화면 ROI 대시보드.
///
/// 사용자가 한눈에 캠페인 효과를 파악할 수 있도록 단순화:
///   1. 헤드라인 — 사용 전환률 % + 한 줄 평가
///   2. 단계별 funnel — 발송 → 픽업 → 사용 (3 KPI)
///   3. 캠페인 list — 각각 conversion + 코칭 메시지
///
/// 진입점은 profile_screen 의 Brand 전용 카드.
///
/// Build 324 (audit fix): StatefulWidget 으로 변경 — initState 에서
///   `refreshBrandInsightsFromServer()` 호출해 Firestore 의 atomic 집계
///   (pickupCount + redeemedCount) 를 fetch. 이전엔 local _inbox 만 봐서
///   다른 회원의 픽업/사용이 카운트 안 돼 ROI 항상 0% 표시되던 critical bug.
class BrandInsightsScreen extends StatefulWidget {
  static const String routeName = '/brand_insights';
  const BrandInsightsScreen({super.key});

  @override
  State<BrandInsightsScreen> createState() => _BrandInsightsScreenState();
}

class _BrandInsightsScreenState extends State<BrandInsightsScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await context.read<AppState>().refreshBrandInsightsFromServer();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final insights = state.brandInsights;
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        title: Text(
          AppL10n.of(state.currentUser.languageCode).brandInsightsTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // 1) 헤드라인 — 사용 전환률 + 평가
          _buildHeadline(insights),
          const SizedBox(height: 20),
          // 2) 단계별 funnel
          _buildFunnel(insights),
          const SizedBox(height: 20),
          // Build 334 (PR-S4): "발급된 매장 코드" dedup 섹션 — 사장이 POS 에
          //   등록할 코드를 한 화면에서 확인. campaigns 가 같은 코드를 공유하면
          //   하나로 합쳐 letter 수 / 노출 / 사용 stat 합산.
          ..._buildActiveCodesSection(insights),
          // 3) 캠페인 list
          if (insights.campaigns.isEmpty)
            _buildEmpty()
          else
            ...insights.campaigns.take(10).map(_buildCampaignCard),
          const SizedBox(height: 24),
          _buildHelpFooter(),
        ],
      ),
    );
  }

  Widget _buildHeadline(BrandInsights i) {
    final pct = (i.redeemRate * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.18),
            AppColors.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 30일',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${i.healthEmoji} ${i.healthLabel}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '픽업한 사람 중 매장 사용 비율',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnel(BrandInsights i) {
    // Build 331 (PR-S3): 4단계 funnel — 발송 → 픽업 → 코드 노출 → 사용.
    //   코드 노출 (revealedCount) = 매장 도착 의도 신호. 노출→사용 drop 큰
    //   캠페인은 POS 등록 누락 가능성 → 코칭 메시지로 알림.
    return Row(
      children: [
        Expanded(child: _kpiCard('📮', i.totalSent.toString(), null)),
        const SizedBox(width: 6),
        Expanded(
          child: _kpiCard(
            '🎯',
            i.totalPickup.toString(),
            '${(i.pickupRate * 100).toStringAsFixed(0)}%',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _kpiCard(
            '🛒',
            i.totalRevealed.toString(),
            '${(i.revealRate * 100).toStringAsFixed(0)}%',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _kpiCard(
            '✅',
            i.totalRedeemed.toString(),
            '${(i.redeemRate * 100).toStringAsFixed(0)}%',
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, String? sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build 334 (PR-S4): "발급된 매장 코드" dedup 섹션 — 캠페인 list 위에 노출.
  ///   campaigns 가 같은 redemptionCode 를 공유하면 (bulk send) 하나의 카드로
  ///   묶어 letter 수 + 노출 + 사용 합산 표시. POS 등록 셋업 가이드를 같은
  ///   화면에서 확인.
  List<Widget> _buildActiveCodesSection(BrandInsights i) {
    if (i.campaigns.isEmpty) return const [];
    // dedup by code
    final groups = <String, _CodeAggregate>{};
    for (final c in i.campaigns) {
      final code = c.redemptionCode;
      if (code == null) continue;
      final g = groups.putIfAbsent(code, () => _CodeAggregate(code: code));
      g.letterCount += c.sent;
      g.totalPickup += c.pickup;
      g.totalRevealed += c.revealed;
      g.totalRedeemed += c.redeemed;
      g.expiresAt ??= c.redemptionExpiresAt;
    }
    if (groups.isEmpty) return const [];
    final list = groups.values.toList()
      ..sort((a, b) => b.letterCount.compareTo(a.letterCount));
    final l = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    return [
      Row(
        children: [
          const Text('🔑', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            l.brandActiveCodesHeader(list.length),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        l.brandActiveCodesIntro,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 10),
      ...list.map(_buildCodeCard),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildCodeCard(_CodeAggregate g) {
    final formatted = RedemptionCode.formatForDisplay(g.code);
    final expired = g.expiresAt != null &&
        DateTime.now().isAfter(g.expiresAt!);
    final accent = expired ? AppColors.textMuted : AppColors.teal;
    final l = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired
            ? AppColors.bgCard
            : AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: expired ? 0.25 : 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatted,
                  style: TextStyle(
                    color: expired ? AppColors.textMuted : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                    decoration: expired
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              InkWell(
                onTap: expired
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: formatted));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l.redemptionCodeCopied,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.teal,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        l.redemptionCodeCopy,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.brandCodeStats(
              g.letterCount,
              g.totalPickup,
              g.totalRevealed,
              g.totalRedeemed,
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (expired) ...[
            const SizedBox(height: 4),
            Text(
              l.brandCodeExpiredNote,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (g.expiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l.brandCodeExpiresIn(_formatExpiry(g.expiresAt!, l)),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatExpiry(DateTime exp, AppL10n l) {
    final d = exp.difference(DateTime.now());
    if (d.inDays >= 1) return l.expiresDaysShort(d.inDays);
    if (d.inHours >= 1) return l.expiresHoursShort(d.inHours);
    return l.expiresMinutesShort(d.inMinutes);
  }

  Widget _buildCampaignCard(CampaignInsight c) {
    final hasMetric = c.pickup > 0;
    final pct = (c.redeemRate * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                c.healthEmoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasMetric)
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            // Build 331 (PR-S3): 4단계 표시 — 노출 (🛒) 추가.
            '📮 ${c.sent} · 🎯 ${c.pickup} · 🛒 ${c.revealed} · ✅ ${c.redeemed}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Builder(builder: (ctx) {
            final l = AppL10n.of(
              ctx.read<AppState>().currentUser.languageCode,
            );
            final tip = c.coachingTip(l);
            if (tip.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '💡 $tip',
                style: const TextStyle(
                  color: AppColors.coupon,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Text('📭', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            '최근 30일 캠페인 데이터 없음',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '캠페인 화면에서 첫 캠페인을 등록해 보세요',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📚 지표 읽는 법',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '• 사용 전환률 ≥ 20%: 잘 되는 캠페인 — 동일 패턴 재집행\n'
            '• 5~20%: 보통 — 가벼운 본문 / 가격 조정\n'
            '• < 5%: 개선 필요 — 본문 / 반경 / 가격 재검토\n'
            '• 픽업 0: 반경 좁히거나 본문 매력 ↑',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Build 334 (PR-S4): 같은 redemptionCode 를 공유하는 캠페인 letter 들의 합산.
///   bulk send 100통이 코드 1개 공유 → 1 row 로 묶어 표시. POS 등록 단위 = 코드.
/// Build 340 (PR-S11 시뮬레이션): totalPickup 추가 — 코드 카드 stat 이 4단계
///   funnel (📮 → 🎯 → 🛒 → ✅) 와 일치하도록.
class _CodeAggregate {
  final String code;
  int letterCount = 0;
  int totalPickup = 0;
  int totalRevealed = 0;
  int totalRedeemed = 0;
  DateTime? expiresAt;
  _CodeAggregate({required this.code});
}
