import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/redemption_code.dart';
import '../../core/utils/secure_clipboard.dart';
import '../../models/direct_message.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';
import '../compose/screens/compose_screen.dart';
import '../dm/dm_conversation_screen.dart';
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
/// Build 446: 보낸 캠페인 카테고리 필터.
enum _CampaignCatFilter { all, general, coupon, voucher }

class BrandCampaignScreen extends StatefulWidget {
  const BrandCampaignScreen({super.key});

  @override
  State<BrandCampaignScreen> createState() => _BrandCampaignScreenState();
}

class _BrandCampaignScreenState extends State<BrandCampaignScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  _CampaignCatFilter _cat = _CampaignCatFilter.all;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool _matchesCat(Letter l) {
    switch (_cat) {
      case _CampaignCatFilter.all:
        return true;
      case _CampaignCatFilter.general:
        return l.category == LetterCategory.general;
      case _CampaignCatFilter.coupon:
        return l.category == LetterCategory.coupon;
      case _CampaignCatFilter.voucher:
        return l.category == LetterCategory.voucher;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    // 받은 DM 미읽음 합계 → 탭 배지.
    final dmUnread = state.totalDMUnread;

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
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.coupon,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.coupon,
          labelStyle:
              const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          tabs: [
            Tab(text: l.brandCampaignSentTab),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.brandCampaignDmTab),
                  if (dmUnread > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        dmUnread > 99 ? '99+' : '$dmUnread',
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
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildSentTab(state, l),
          _buildDmTab(state, l),
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

  // Build 449: 대량발송 캠페인 그룹화 — 같은 campaignId(1인당1회 ON) 또는
  //   같은 본문+코드+업종(brandUniquePerUser OFF) letter 들을 1개 캠페인 행으로
  //   묶고 'N통 발송'으로 집계. 사용자가 "대량발송했는데 1개만 보인다"고 느끼던
  //   회귀(중복 N행 또는 글로벌 산포)를 한 행 + 정확한 발송 수로 해소.
  static String _groupKey(Letter l) {
    if (l.campaignId != null && l.campaignId!.isNotEmpty) return l.campaignId!;
    return '${l.content}${l.redemptionCode ?? ''}${l.categoryTag ?? ''}';
  }

  static List<_CampaignGroup> _group(List<Letter> letters) {
    final map = <String, _CampaignGroup>{};
    final order = <String>[];
    for (final l in letters) {
      final k = _groupKey(l);
      final g = map.putIfAbsent(k, () {
        order.add(k);
        return _CampaignGroup(rep: l);
      });
      g.count += 1;
      g.pickup += l.readCount;
      if (l.redeemedAt != null) g.redeemed += 1;
      // 대표 letter 는 가장 최근 발송으로 유지.
      if (l.sentAt.isAfter(g.rep.sentAt)) g.rep = l;
    }
    return [for (final k in order) map[k]!];
  }

  // ── 보낸 캠페인 탭 ──────────────────────────────────────────────────────────
  Widget _buildSentTab(AppState state, AppL10n l) {
    final sentByNewest = [...state.sent]
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    // 카테고리 필터 적용.
    final filtered = sentByNewest.where(_matchesCat).toList();
    final activeSent = _group(filtered.where((l) => !l.isExpired).toList());
    final endedSent = _group(filtered.where((l) => l.isExpired).toList());
    final mostRecentlyPickedUp = state.brandMostRecentlyPickedUpLetter;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        _QuotaSummaryCard(state: state, l: l),
        const SizedBox(height: 12),
        _QuickComposeCard(l: l),
        const SizedBox(height: 16),
        if (mostRecentlyPickedUp != null) ...[
          _RecentPickupHighlight(letter: mostRecentlyPickedUp, l: l),
          const SizedBox(height: 16),
        ],
        // Build 446: 카테고리 필터 칩 — 전체/일반/할인권/교환권.
        _CategoryFilterRow(
          selected: _cat,
          l: l,
          onSelect: (c) => setState(() => _cat = c),
        ),
        const SizedBox(height: 12),
        if (sentByNewest.isEmpty) ...[
          _SectionHeader(title: l.brandCampaignRecentSent),
          const SizedBox(height: 8),
          _EmptySentCampaigns(l: l),
        ] else if (filtered.isEmpty) ...[
          _SectionHeader(title: l.brandCampaignRecentSent),
          const SizedBox(height: 8),
          _EmptyFiltered(l: l),
        ] else ...[
          if (activeSent.isNotEmpty) ...[
            _SectionHeader(title: l.brandCampaignActive),
            const SizedBox(height: 8),
            ...activeSent.take(50).map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CampaignRow(group: g, l: l),
                  ),
                ),
          ],
          if (endedSent.isNotEmpty) ...[
            if (activeSent.isNotEmpty) const SizedBox(height: 24),
            _SectionHeader(title: l.brandCampaignEnded),
            const SizedBox(height: 8),
            ...endedSent.take(50).map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CampaignRow(group: g, l: l),
                  ),
                ),
          ],
        ],
      ],
    );
  }

  // ── 받은 DM 탭 ─────────────────────────────────────────────────────────────
  Widget _buildDmTab(AppState state, AppL10n l) {
    // 미읽음 우선 → 최근 생성 순.
    final sessions = state.chatSessions.values.toList()
      ..sort((a, b) {
        if ((a.unreadCount > 0) != (b.unreadCount > 0)) {
          return a.unreadCount > 0 ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    if (sessions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 90),
        children: [_EmptyDm(l: l)],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _DmRow(session: sessions[i], state: state, l: l),
    );
  }
}

// Build 446: 카테고리 필터 칩 행.
class _CategoryFilterRow extends StatelessWidget {
  final _CampaignCatFilter selected;
  final AppL10n l;
  final ValueChanged<_CampaignCatFilter> onSelect;
  const _CategoryFilterRow({
    required this.selected,
    required this.l,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(_CampaignCatFilter, String)>[
      (_CampaignCatFilter.all, l.inboxFilterAll),
      (_CampaignCatFilter.general, l.composeBrandCategoryGeneral),
      (_CampaignCatFilter.coupon, l.composeBrandCategoryCoupon),
      (_CampaignCatFilter.voucher, l.composeBrandCategoryVoucher),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (cat, label) = items[i];
          final active = cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.coupon.withValues(alpha: 0.16)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? AppColors.coupon.withValues(alpha: 0.7)
                      : AppColors.bgSurface,
                  width: active ? 1.3 : 1.0,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.coupon : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Build 446: 받은 DM 한 행 — 상대 닉네임/국기 + 마지막 메시지 미리보기 + 미읽음.
class _DmRow extends StatelessWidget {
  final ChatSession session;
  final AppState state;
  final AppL10n l;
  const _DmRow({required this.session, required this.state, required this.l});

  @override
  Widget build(BuildContext context) {
    final msgs = state.getDMConversation(session.partnerId);
    final last = msgs.isNotEmpty ? msgs.last : null;
    final hasUnread = session.unreadCount > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DmConversationScreen(
            partnerId: session.partnerId,
            partnerName: session.partnerName,
            partnerFlag: session.partnerFlag,
          ),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasUnread
                  ? AppColors.coupon.withValues(alpha: 0.5)
                  : AppColors.bgSurface,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(session.partnerFlag,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      last?.content ?? l.brandCampaignDmNoMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    session.unreadCount > 99 ? '99+' : '${session.unreadCount}',
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
        ),
      ),
    );
  }
}

// Build 446: 받은 DM 빈 상태.
class _EmptyDm extends StatelessWidget {
  final AppL10n l;
  const _EmptyDm({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        children: [
          const Text('💬', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            l.brandCampaignDmEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.brandCampaignDmEmptySub,
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

// Build 446: 필터 결과 없음.
class _EmptyFiltered extends StatelessWidget {
  final AppL10n l;
  const _EmptyFiltered({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Center(
        child: Text(
          l.brandCampaignFilterEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

/// Build 407 (PR-QQ7): 구독 플랜 + 남은 발송 가능 수 요약 카드.
///   Brand: ExactDrop 크레딧 + (베타면 무제한 안내). Premium: 특급 잔여.
class _QuotaSummaryCard extends StatelessWidget {
  final AppState state;
  final AppL10n l;
  const _QuotaSummaryCard({required this.state, required this.l});

  @override
  Widget build(BuildContext context) {
    final isBrand = state.currentUser.isBrand;
    final planLabel = isBrand
        ? 'Brand'
        : (state.currentUser.isPremium ? 'Premium' : 'Free');
    final planColor = isBrand
        ? AppColors.coupon
        : (state.currentUser.isPremium ? AppColors.gold : AppColors.textMuted);
    // 베타 무료 Brand 면 ExactDrop 무제한, 아니면 크레딧 수.
    final exactDropFree = state.exactDropFreeForBeta;
    final credits = state.brandExactDropCredits;
    // Build 408 (QQ7): 일별 발송 잔여 — "남은 발송 가능 쿠폰 수" 사용자 요구.
    final dailyRemaining = state.remainingDailySendCount;
    final dailyLimit = state.dailySendLimit;
    final dailyPct = dailyLimit > 0 ? dailyRemaining / dailyLimit : 0.0;
    final dailyColor = dailyPct > 0.4
        ? AppColors.teal
        : (dailyPct > 0.15 ? AppColors.gold : AppColors.error);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: planColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: planColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              planLabel,
              style: TextStyle(
                color: planColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.brandCampaignQuotaLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                // 주 지표: 오늘 남은 발송 가능 수 (사용자 요구 핵심).
                Text(
                  l.brandCampaignDailyRemaining(dailyRemaining, dailyLimit),
                  style: TextStyle(
                    color: dailyColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                // 부 지표: ExactDrop(정밀 발송) 잔여 / 베타 무제한.
                Text(
                  exactDropFree
                      ? l.brandCampaignQuotaUnlimited
                      : l.brandCampaignQuotaCredits(credits),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.bolt_rounded,
            color: AppColors.coupon,
            size: 20,
          ),
        ],
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

// Build 449: 대량발송 캠페인 그룹 — 같은 캠페인 letter N통의 대표 + 집계.
class _CampaignGroup {
  Letter rep;
  int count = 0;
  int pickup = 0;
  int redeemed = 0;
  _CampaignGroup({required this.rep});
}

class _CampaignRow extends StatelessWidget {
  final _CampaignGroup group;
  final AppL10n l;
  const _CampaignRow({required this.group, required this.l});

  @override
  Widget build(BuildContext context) {
    final letter = group.rep;
    // Build 449: 그룹 집계 — 대량발송 N통을 1행으로 묶어 발송 수/픽업/사용 합산.
    final sentCount = group.count;
    final pickedUp = group.pickup;
    final redeemed = group.redeemed;
    final hasCode = letter.redemptionCode != null;
    // Build 437 (device #2): 캠페인 카드 compact 가로형 — 업종 이모지 + 1줄 내용
    //   + 인라인 통계. 이전 세로 2줄+칩 카드(~100pt)는 한 화면에 몇 개 못 보여
    //   "스크롤만 되고 보기 어렵다" 회귀 → 높이 ~절반(화면당 ~2배 노출).
    // Build 449: 탭하면 상세 시트 → 발급된 매장 코드(할인코드) 확인/복사.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.bgSurface),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  bizCategoryEmoji(letter.categoryTag),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            letter.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Build 449: 대량발송이면 'N통' 발송 수 배지.
                        if (sentCount > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coupon.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l.composeCountUnit(sentCount),
                              style: const TextStyle(
                                color: AppColors.coupon,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '🛍 $pickedUp',
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '✅ $redeemed',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
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
              ),
              // 할인코드 발급 표식 + 화살표.
              if (hasCode) ...[
                const SizedBox(width: 6),
                const Icon(Icons.qr_code_2_rounded,
                    size: 16, color: AppColors.coupon),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // Build 449: 캠페인 상세 — 발급된 할인코드(매장 코드)를 크게 보여주고 복사.
  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CampaignDetailSheet(group: group, l: l),
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

// Build 449: 캠페인 상세 바텀시트 — 발급된 할인코드(매장 코드)를 크게 노출 + 복사.
//   사용자 요구: "발급된 매장코드는 내 캠페인에서 보낸 편지를 클릭하면 볼 수 있게".
class _CampaignDetailSheet extends StatelessWidget {
  final _CampaignGroup group;
  final AppL10n l;
  const _CampaignDetailSheet({required this.group, required this.l});

  @override
  Widget build(BuildContext context) {
    final letter = group.rep;
    final code = letter.redemptionCode;
    final sentCount = group.count;
    final pickedUp = group.pickup;
    final redeemed = group.redeemed;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 업종 이모지 + 카테고리 배지.
          Row(
            children: [
              Text(bizCategoryEmoji(letter.categoryTag),
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              _catBadge(letter.category),
            ],
          ),
          const SizedBox(height: 12),
          // 본문.
          Text(
            letter.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // ── 발급된 할인코드 ──
          if (code != null) ...[
            Text(
              l.redemptionPreviewHeader,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            _CodeBox(code: code, l: l),
            const SizedBox(height: 8),
            Text(
              l.composeBrandCouponAutoCodeNote,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.brandNoCodesYet,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // ── 성과 요약 ── Build 449: 발송 수(N통) 포함.
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _miniStat('📮', '$sentCount', l.koEn('발송', 'Sent')),
              _miniStat('🛍', '$pickedUp', l.koEn('픽업', 'Pickup')),
              _miniStat('✅', '$redeemed', l.koEn('사용', 'Used')),
              if (letter.redemptionExpiresAt != null)
                _miniStat(
                  '⏳',
                  '',
                  _expiryLabel(letter.redemptionExpiresAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _catBadge(LetterCategory c) {
    final (label, color) = switch (c) {
      LetterCategory.coupon => (l.composeBrandCategoryCoupon, AppColors.coupon),
      LetterCategory.voucher => (l.composeBrandCategoryVoucher, AppColors.gold),
      _ => (l.composeBrandCategoryGeneral, AppColors.teal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          if (value.isNotEmpty) ...[
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _expiryLabel(DateTime exp) {
    final d = exp.difference(DateTime.now());
    if (d.isNegative) return l.koEn('만료됨', 'Expired');
    if (d.inDays >= 1) return l.expiresDaysShort(d.inDays);
    if (d.inHours >= 1) return l.expiresHoursShort(d.inHours);
    return l.expiresMinutesShort(d.inMinutes);
  }
}

// Build 449: 코드 박스 — 큰 monospace 코드 + 복사 버튼.
class _CodeBox extends StatelessWidget {
  final String code;
  final AppL10n l;
  const _CodeBox({required this.code, required this.l});

  @override
  Widget build(BuildContext context) {
    final formatted = RedemptionCode.formatForDisplay(code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coupon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coupon.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatted,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await SecureClipboard.copyEphemeral(formatted);
              if (!context.mounted) return;
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coupon.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.coupon.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded,
                      size: 14, color: AppColors.coupon),
                  const SizedBox(width: 5),
                  Text(
                    l.redemptionCodeCopy,
                    style: const TextStyle(
                      color: AppColors.coupon,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

// Build 437 (device #2): compact 카드 전환으로 현재 미사용 — 향후 재사용 대비 보존.
// ignore: unused_element
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
