import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/secure_clock.dart';
import '../../core/utils/redemption_code.dart';
import '../../core/utils/secure_clipboard.dart';
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
  // Build 446: 프로필의 '인사이트' 하위 탭에서 본문만 임베드할 때 true → Scaffold/
  //   AppBar 없이 ListView 만 반환(상위 탭 AppBar 와 중복 방지).
  final bool embedded;
  const BrandInsightsScreen({super.key, this.embedded = false});

  @override
  State<BrandInsightsScreen> createState() => _BrandInsightsScreenState();
}

class _BrandInsightsScreenState extends State<BrandInsightsScreen> {
  bool _refreshing = false;
  // Build 459: '지표 읽는 법' 푸터 dismiss 영속.
  static const _kHelpDismissed = 'insights_help_dismissed_v1';
  bool _helpDismissed = true; // 로딩 전 미노출(깜빡임 방지)

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(
            () => _helpDismissed = p.getBool(_kHelpDismissed) ?? false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  Future<void> _dismissHelp() async {
    setState(() => _helpDismissed = true);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kHelpDismissed, true);
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
    // Build 409 (sim P1.24): 비-Korean Brand 가 한국어 고정 문구를 보던 헤드라인/
    //   빈 상태/도움말을 l 로 현지화 (koEn 토글). l 을 helper 들에 전달.
    final l = AppL10n.of(state.currentUser.languageCode);
    final body = ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
      children: [
        // Build 448: ROI 전환율 + 단계 퍼널을 한 카드로 통합 → 스크롤 없이 핵심
        //   지표를 한눈에. (이전엔 헤드라인 카드 + 퍼널 카드 분리로 스크롤 길었음)
        _buildSummaryCard(insights, l),
        const SizedBox(height: 14),
        // "발급된 매장 코드" dedup 섹션.
        ..._buildActiveCodesSection(insights),
        // 캠페인 list — Build 449: 섹션 헤더로 구분(정리).
        if (insights.campaigns.isEmpty)
          _buildEmpty(l)
        else ...[
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                l.insightsCampaignPerf,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...insights.campaigns.take(10).map(_buildCampaignCard),
        ],
        const SizedBox(height: 16),
        // Build 459 (UI 다이어트): 지표 읽는 법 — 닫기 가능(1회성 교육).
        if (!_helpDismissed) _buildHelpFooter(l),
      ],
    );
    // Build 446: 임베드 모드면 본문만 반환(상위 탭이 Scaffold/AppBar 보유).
    if (widget.embedded) return body;
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
      body: body,
    );
  }

  // Build 448: ROI 전환율 헤드라인 + 4단계 퍼널을 한 카드로 통합.
  // Build 461: 팔로워 수 KPI 추가 (followerCount — toggleBrandFollow 서버 집계).
  Widget _buildSummaryCard(BrandInsights i, AppL10n l) {
    final pct = (i.redeemRate * 100).toStringAsFixed(1);
    final noData = i.totalSent == 0 || i.totalPickup == 0;
    // 퍼널 단계 — 단조감소 clamp(표시 전용).
    final pSent = i.totalSent;
    final pPickup = i.totalPickup.clamp(0, pSent <= 0 ? i.totalPickup : pSent);
    final pReveal = i.totalRevealed.clamp(0, pPickup);
    final pRedeem = i.totalRedeemed.clamp(0, pReveal);
    final stages = <_FunnelStage>[
      _FunnelStage('\u{1F4EE}', l.brandAnalyticsSent, pSent, AppColors.textMuted),
      _FunnelStage('\u{1F3AF}', l.brandAnalyticsPicked, pPickup, AppColors.teal),
      _FunnelStage('\u{1F6D2}', l.brandFunnelReveal, pReveal, AppColors.coupon),
      _FunnelStage('\u2705', l.brandFunnelRedeem, pRedeem, AppColors.gold),
    ];
    final maxCount = i.totalSent <= 0 ? 1 : i.totalSent;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.16),
            AppColors.gold.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROI 전환율 헤드라인 ──
          Text(
            l.insightsHeadline,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                noData ? '\u2014' : '$pct%',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    noData
                        ? l.insightsCollecting
                        : '${i.healthEmoji} ${i.healthLabelL10n(l)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // ── 팔로워 KPI (Build 461) — 단골 채널이 처음으로 측정 가능해짐 ──
          Builder(builder: (context) {
            final followers = context.watch<AppState>().brandFollowerCount;
            if (followers < 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Text('👥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    l.insightsFollowers(followers),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.gold.withValues(alpha: 0.18)),
          const SizedBox(height: 12),
          // ── 4단계 전환 퍼널 ──
          for (int s = 0; s < stages.length; s++)
            _funnelRow(
              stages[s],
              maxCount,
              s == 0 ? null : _stepRate(stages[s].count, stages[s - 1].count),
            ),
        ],
      ),
    );
  }

  /// 직전 단계 대비 전환율 (0~1, clamp). 분모 0 이면 null.
  double? _stepRate(int count, int prev) {
    if (prev <= 0) return null;
    return (count / prev).clamp(0.0, 1.0);
  }

  Widget _funnelRow(_FunnelStage stage, int maxCount, double? stepRate) {
    // 막대 폭 = 발송 대비 비율. count>0 인데 막대가 안 보이지 않도록 최소 6%.
    final raw = maxCount <= 0 ? 0.0 : stage.count / maxCount;
    final widthFactor = stage.count == 0 ? 0.0 : (raw < 0.06 ? 0.06 : raw);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 라벨 (이모지 + 단계명)
          SizedBox(
            width: 76,
            child: Row(
              children: [
                Text(stage.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    stage.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 비율 막대 + 수치
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: stage.color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        stage.count.toString(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 단계 전환율
          SizedBox(
            width: 52,
            child: Text(
              stepRate == null
                  ? '—'
                  : '${(stepRate * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: stepRate == null ? AppColors.textMuted : AppColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
    final l = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    if (groups.isEmpty) {
      // Build 341 (PR-S12 2차 시뮬레이션 P2): 캠페인은 있지만 코드 발급된
      //   letter 가 없는 경우 안내 1줄 — 사용자가 "왜 코드 섹션 없지?" 혼란 해소.
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.brandNoCodesYet,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }
    final list = groups.values.toList()
      ..sort((a, b) => b.letterCount.compareTo(a.letterCount));
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
        SecureClock.now().isAfter(g.expiresAt!);
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
                        await SecureClipboard.copyEphemeral(formatted);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l.redemptionCodeCopied,
                              style: const TextStyle(color: AppColors.tealInk),
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
    final d = exp.difference(SecureClock.now());
    if (d.inDays >= 1) return l.expiresDaysShort(d.inDays);
    if (d.inHours >= 1) return l.expiresHoursShort(d.inHours);
    return l.expiresMinutesShort(d.inMinutes);
  }

  // Build 449: 캠페인 카드 compact — 미니 퍼널 막대 3개 제거(상단 요약 카드의
  //   퍼널과 중복 + 카드 높이↑로 스크롤 길어짐). 1줄 헤더 + 1줄 stat 으로 압축,
  //   코칭 팁은 있을 때만. 화면당 노출 ~2배.
  Widget _buildCampaignCard(CampaignInsight c) {
    final hasMetric = c.pickup > 0;
    final pct = (c.redeemRate * 100).toStringAsFixed(0);
    // Build 420 (sim100 iter5): 캠페인 카드도 메인 퍼널과 동일하게 단조감소 clamp.
    //   mixed-source 집계로 redeemed>revealed>pickup 같은 비논리 표시 차단(표시 전용).
    final cPickup = c.pickup.clamp(0, c.sent <= 0 ? c.pickup : c.sent);
    final cReveal = c.revealed.clamp(0, cPickup);
    final cRedeem = c.redeemed.clamp(0, cReveal);
    final l = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    final tip = c.coachingTip(l);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.healthEmoji, style: const TextStyle(fontSize: 15)),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            // Build 331 (PR-S3): 4단계 표시 — 노출 (🛒) 추가.
            '📮 ${c.sent} · 🎯 $cPickup · 🛒 $cReveal · ✅ $cRedeem',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          if (tip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '💡 $tip',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.coupon,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppL10n l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            l.insightsEmptyTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.insightsEmptySub,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpFooter(AppL10n l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.insightsHelpTitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismissHelp,
                child: const Icon(Icons.close_rounded,
                    size: 15, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.insightsHelpBody,
            style: const TextStyle(
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
/// Build 415 (#8 ROI 퍼널): 퍼널 한 단계의 표시 데이터 (이모지·라벨·수치·색).
class _FunnelStage {
  final String emoji;
  final String label;
  final int count;
  final Color color;
  const _FunnelStage(this.emoji, this.label, this.count, this.color);
}

class _CodeAggregate {
  final String code;
  int letterCount = 0;
  int totalPickup = 0;
  int totalRevealed = 0;
  int totalRedeemed = 0;
  DateTime? expiresAt;
  _CodeAggregate({required this.code});
}
