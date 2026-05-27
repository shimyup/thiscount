import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';
import '../compose/screens/compose_screen.dart';
import 'brand_insights_screen.dart';

/// Build 405 (PR-NN4): Brand 계정 전용 메인 화면.
///
/// 일반 회원의 [InboxScreen] 자리를 대체한다. Brand 는 "받는 인박스" 보다
/// "내가 보낸 캠페인 + 픽업 결과" 가 더 의미 있으므로 다음 3 영역으로 구성:
///
/// 1. 빠른 발송 CTA — 큰 버튼 한 개. compose 즉시 진입.
/// 2. 가장 최근 픽업된 캠페인 highlight — 가장 좋은 피드백 카드.
/// 3. 최근 발송 캠페인 목록 — 시간 역순. 탭 시 letter detail.
/// 4. 분석 화면으로 이동하는 sticky FAB.
///
/// 일반 회원의 [InboxScreen] 과 데이터/스토리지를 공유 (state.sent 와
/// state.inbox 같은 source) 하지만 표시 방식이 완전히 다르다. NN5 에서
/// 공유 시스템 documentation 으로 명확화.
class BrandCampaignScreen extends StatelessWidget {
  const BrandCampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    // 가장 최근 발송 → 가장 오래된 순으로 정렬한 사본.
    final sentByNewest = [...state.sent]
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final mostRecentlyPickedUp = state.brandMostRecentlyPickedUpLetter;
    // Build 406 (PR-OO7 시뮬레이션 P1 #1): Brand 사용자가 zone letter 등 픽업
    //   시 _inbox 에 들어가지만 BrandCampaignScreen 미노출 → invisible 누수.
    //   여기서 최근 5개 받은 letter 도 노출 (picked-up). 일반 회원의 InboxScreen
    //   과 동일 source (state.inbox) 사용 — 공유 시스템 일관성.
    final receivedByNewest = [...state.inbox]
      ..sort((a, b) {
        final at = a.arrivedAt ?? a.sentAt;
        final bt = b.arrivedAt ?? b.sentAt;
        return bt.compareTo(at);
      });

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Text(
          l.brandCampaignTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l.brandCampaignAnalytics,
            icon: const Icon(
              Icons.insights_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BrandInsightsScreen(),
              ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          _QuickComposeCard(l: l),
          const SizedBox(height: 16),
          if (mostRecentlyPickedUp != null) ...[
            _RecentPickupHighlight(letter: mostRecentlyPickedUp, l: l),
            const SizedBox(height: 16),
          ],
          _SectionHeader(title: l.brandCampaignRecentSent),
          const SizedBox(height: 8),
          if (sentByNewest.isEmpty)
            _EmptySentCampaigns(l: l)
          else
            ...sentByNewest.take(20).map(
                  (letter) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CampaignRow(letter: letter, l: l),
                  ),
                ),
          // Build 406 (PR-OO7): Brand 도 zone letter 픽업 가능 → 받은 letter
          //   섹션을 별도로 노출. 비어있으면 hide (Brand 대부분 케이스).
          if (receivedByNewest.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: l.brandCampaignReceived),
            const SizedBox(height: 8),
            ...receivedByNewest.take(5).map(
                  (letter) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CampaignRow(letter: letter, l: l),
                  ),
                ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coupon,
        foregroundColor: AppColors.bgDeep,
        icon: const Icon(Icons.send_rounded),
        label: Text(
          l.brandCampaignQuickSend,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ComposeScreen(),
        )),
      ),
    );
  }
}

class _QuickComposeCard extends StatelessWidget {
  final AppL10n l;
  const _QuickComposeCard({required this.l});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ComposeScreen(),
        )),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.coupon.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.coupon.withValues(alpha: 0.4),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              const Text('📣', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.brandCampaignQuickComposeTitle,
                      style: const TextStyle(
                        color: AppColors.coupon,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.brandCampaignQuickComposeSub,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.coupon,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentPickupHighlight extends StatelessWidget {
  final Letter letter;
  final AppL10n l;
  const _RecentPickupHighlight({required this.letter, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                l.brandCampaignLatestPickup,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            letter.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (letter.destinationCountry.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${letter.destinationCountryFlag} ${letter.destinationCountry}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.coupon,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.coupon,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final Letter letter;
  final AppL10n l;
  const _CampaignRow({required this.letter, required this.l});

  @override
  Widget build(BuildContext context) {
    // Letter 모델은 readCount (unique 픽업 인원) 와 redeemedAt (본인 사용
    // 시각, 단건) 만 노출. campaign-level "사용됨" 집계는 별도 path 필요 →
    // 우선 readCount 만 표시. 후속 PR (Cloud Function) 에서 redeem 집계 추가.
    final pickedUp = letter.readCount;
    final redeemed = letter.redeemedAt != null ? 1 : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            letter.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(
                icon: Icons.local_mall_outlined,
                label: '$pickedUp',
                tooltip: l.brandCampaignPicked,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                label: '$redeemed',
                tooltip: l.brandCampaignRedeemed,
              ),
              const Spacer(),
              Text(
                _shortAge(letter.sentAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortAge(DateTime sentAt) {
    final d = DateTime.now().difference(sentAt);
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySentCampaigns extends StatelessWidget {
  final AppL10n l;
  const _EmptySentCampaigns({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            l.brandCampaignEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.brandCampaignEmptySub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
