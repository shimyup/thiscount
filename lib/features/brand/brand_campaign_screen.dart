import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
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

  // ── 보낸 캠페인 탭 ──────────────────────────────────────────────────────────
  Widget _buildSentTab(AppState state, AppL10n l) {
    final sentByNewest = [...state.sent]
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    // 카테고리 필터 적용.
    final filtered = sentByNewest.where(_matchesCat).toList();
    final activeSent = filtered.where((l) => !l.isExpired).toList();
    final endedSent = filtered.where((l) => l.isExpired).toList();
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
                  (letter) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CampaignRow(letter: letter, l: l),
                  ),
                ),
          ],
          if (endedSent.isNotEmpty) ...[
            if (activeSent.isNotEmpty) const SizedBox(height: 24),
            _SectionHeader(title: l.brandCampaignEnded),
            const SizedBox(height: 8),
            ...endedSent.take(50).map(
                  (letter) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CampaignRow(letter: letter, l: l),
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
    // Build 437 (device #2): 캠페인 카드 compact 가로형 — 업종 이모지 + 1줄 내용
    //   + 인라인 통계. 이전 세로 2줄+칩 카드(~100pt)는 한 화면에 몇 개 못 보여
    //   "스크롤만 되고 보기 어렵다" 회귀 → 높이 ~절반(화면당 ~2배 노출).
    return Container(
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
                Text(
                  letter.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
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
