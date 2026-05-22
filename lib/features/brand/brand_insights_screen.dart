import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
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
class BrandInsightsScreen extends StatelessWidget {
  static const String routeName = '/brand_insights';
  const BrandInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final insights = state.brandInsights;
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        title: const Text(
          '📊 캠페인 인사이트',
          style: TextStyle(
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
    return Row(
      children: [
        Expanded(child: _kpiCard('발송', i.totalSent.toString(), null)),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiCard(
            '픽업',
            i.totalPickup.toString(),
            '${(i.pickupRate * 100).toStringAsFixed(0)}%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiCard(
            '사용',
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
            '발송 ${c.sent} · 픽업 ${c.pickup} · 사용 ${c.redeemed}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (c.coachingTip.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '💡 ${c.coachingTip}',
              style: const TextStyle(
                color: AppColors.coupon,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
