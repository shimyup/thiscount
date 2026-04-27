import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/letter.dart';
import '../../../models/direct_message.dart';
import '../../../state/app_state.dart';
import '../widgets/letter_read_screen.dart';
import '../../map/screens/letter_detail_map_screen.dart';
import '../../dm/dm_conversation_screen.dart';

// 포지셔닝 변경 + Build 183 에서 brand 제거, general 추가.
//   all · general · coupon · voucher
// 배송 상태(read/inTransit/waitingPickup) 는 각 편지 카드의 뱃지에서 확인.
// 필터는 "편지의 종류"만 다룸. 기존 enum 값은 유지 (코드베이스 호환성),
// 필터 바의 표시 목록에서만 빠진다.
enum LetterFilterType { all, read, inTransit, waitingPickup, brand, coupon, voucher, general }

/// Build 169: 수집첩 정렬 옵션. Build 183 에서 `usedOnly` 추가 + 아이콘 전용
/// 렌더링. 사용 완료된 편지를 따로 조회해 "쿠폰 히스토리" 처럼 쓸 수 있게 함.
enum InboxSortType {
  newest,        // 최신 도착순 (기본)
  expiringSoon,  // 만료 임박순 — redemptionExpiresAt 오름차순, null 은 끝
  byBrand,       // 브랜드명 가나다순
  byCategory,    // 카테고리별 (general → coupon → voucher)
  usedOnly,      // 사용 완료된 편지만 (markRedeemed 처리된 것)
}

/// 필터 바에 노출되는 4개 타입. Build 183: brand 제거, general 추가.
const List<LetterFilterType> _visibleFilters = [
  LetterFilterType.all,
  LetterFilterType.general,
  LetterFilterType.coupon,
  LetterFilterType.voucher,
];

// 필터별 empty state 이모지. 수집첩이 비었을 때 어떤 종류의 편지를 찾고
// 있었는지 시각적으로 힌트를 준다. (예: 할인권 필터에서 비면 🎟)
String _emptyEmojiForFilter(LetterFilterType f) {
  switch (f) {
    case LetterFilterType.coupon:
      return '🎟';
    case LetterFilterType.voucher:
      return '🎁';
    case LetterFilterType.brand:
      return '🏢';
    case LetterFilterType.general:
      return '✉️';
    case LetterFilterType.read:
      return '📖';
    case LetterFilterType.inTransit:
      return '✈️';
    case LetterFilterType.waitingPickup:
      return '📬';
    case LetterFilterType.all:
      return '📭';
  }
}

// 필터가 "헌트 모드"인지 판정. 할인권 · 교환권 · 브랜드 편지는 유저가
// 지도에서 주워야 얻는 것이므로 빈 상태 CTA를 "편지 쓰기"가 아닌
// "지도에서 찾기"로 바꾼다.
bool _isHuntFilter(LetterFilterType f) {
  return f == LetterFilterType.coupon ||
      f == LetterFilterType.voucher ||
      f == LetterFilterType.brand;
}

// 필터별 이름. inboxEmptyForFilter() 에 전달해 "아직 받은 할인권이 없어요"
// 식으로 쓰인다. 사용자가 어떤 필터를 켜놨는지 empty state 제목에서 즉시 인지.
String _filterName(LetterFilterType f, AppL10n l10n) {
  switch (f) {
    case LetterFilterType.coupon:
      return l10n.inboxFilterCoupon;
    case LetterFilterType.voucher:
      return l10n.inboxFilterVoucher;
    case LetterFilterType.brand:
      return l10n.inboxFilterBrand;
    case LetterFilterType.general:
      return l10n.inboxFilterGeneral;
    case LetterFilterType.read:
      return l10n.inboxRead;
    case LetterFilterType.inTransit:
      return l10n.inboxFilterInTransit;
    case LetterFilterType.waitingPickup:
      return l10n.inboxFilterWaiting;
    case LetterFilterType.all:
      return l10n.inboxFilterAll;
  }
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _inboxScrollController = ScrollController();
  LetterFilterType _inboxFilter = LetterFilterType.all;
  LetterFilterType _sentFilter = LetterFilterType.all;
  // Build 169: 수집첩 정렬 상태 (받은 편지 탭 전용).
  InboxSortType _inboxSort = InboxSortType.newest;
  String _searchQuery = '';
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();

  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

  /// Build 169: 정렬 적용 — 원본 list 복사해 sort.
  List<Letter> _applySort(List<Letter> letters, InboxSortType sort) {
    final sorted = List<Letter>.from(letters);
    switch (sort) {
      case InboxSortType.newest:
        // 기본 — 이미 `.reversed` 상태로 넘어옴, 건드리지 않음.
        return sorted;
      case InboxSortType.expiringSoon:
        // redemptionExpiresAt null 은 맨 뒤, 있는 것끼리 오름차순.
        sorted.sort((a, b) {
          final ax = a.redemptionExpiresAt;
          final bx = b.redemptionExpiresAt;
          if (ax == null && bx == null) return 0;
          if (ax == null) return 1;
          if (bx == null) return -1;
          return ax.compareTo(bx);
        });
        return sorted;
      case InboxSortType.byBrand:
        sorted.sort((a, b) =>
            a.senderName.toLowerCase().compareTo(b.senderName.toLowerCase()));
        return sorted;
      case InboxSortType.byCategory:
        int k(Letter l) => l.category.index;
        sorted.sort((a, b) => k(a).compareTo(k(b)));
        return sorted;
      case InboxSortType.usedOnly:
        // Build 183: 사용 완료된 편지만 — AppState 로 isLetterRedeemed 체크.
        final state = context.read<AppState>();
        return sorted
            .where((l) => state.isLetterRedeemed(l.id))
            .toList();
    }
  }

  List<Letter> _applySearch(List<Letter> letters) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return letters;
    return letters.where((l) {
      if (l.content.toLowerCase().contains(q)) return true;
      if (l.senderCountry.toLowerCase().contains(q)) return true;
      if (l.senderCountryFlag.contains(q)) return true;
      // 별칭 검색 (CountryL10n: 14개 언어 전체 매칭)
      if (CountryL10n.matchesSearch(l.senderCountry, q)) return true;
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // DM 탭 제거로 2개 탭만 운영. (받은/보낸)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inboxScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToFirstUnread(List<Letter> letters) {
    final idx = letters.indexWhere((l) => l.status == DeliveryStatus.delivered);
    if (idx < 0) return;
    // 필터바 높이(56) + 체인배너(0 or 80) + 카드 높이 추정(110px)
    const double filterBarH = 56.0;
    const double itemH = 110.0;
    final double target = filterBarH + idx * itemH;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inboxScrollController.hasClients) {
        _inboxScrollController.animateTo(
          target.clamp(0.0, _inboxScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Letter> _applyFilter(
    List<Letter> letters, {
    required LetterFilterType filter,
    required bool isInbox,
  }) {
    // 검색어가 있으면 먼저 검색 필터 적용
    final searched = _applySearch(letters);
    if (filter == LetterFilterType.all) return searched;
    return searched.where((letter) {
      switch (filter) {
        case LetterFilterType.read:
          return isInbox
              ? letter.status == DeliveryStatus.read
              : (letter.status == DeliveryStatus.read ||
                    letter.isReadByRecipient);
        case LetterFilterType.inTransit:
          return letter.status == DeliveryStatus.inTransit ||
              letter.status == DeliveryStatus.nearYou;
        case LetterFilterType.waitingPickup:
          return letter.status == DeliveryStatus.deliveredFar;
        case LetterFilterType.brand:
          return letter.senderIsBrand ||
              letter.letterType == LetterType.brandExpress;
        case LetterFilterType.coupon:
          return letter.category == LetterCategory.coupon;
        case LetterFilterType.voucher:
          return letter.category == LetterCategory.voucher;
        case LetterFilterType.general:
          // Build 183: 일반 = 브랜드 발신 여부와 무관하게 category 가 general.
          return letter.category == LetterCategory.general;
        case LetterFilterType.all:
          return true;
      }
    }).toList();
  }

  // Build 115: 팔로우한 브랜드의 편지는 인박스 상단에 고정. stable sort 라
  // 같은 follow/non-follow 그룹 내부의 시간 역순은 보존된다.
  List<Letter> _sortFollowedFirst(AppState state, List<Letter> letters) {
    if (state.followedBrandIds.isEmpty) return letters;
    final followed = <Letter>[];
    final rest = <Letter>[];
    for (final l in letters) {
      if (l.senderIsBrand && state.isBrandFollowed(l.senderId)) {
        followed.add(l);
      } else {
        rest.add(l);
      }
    }
    return [...followed, ...rest];
  }

  void _toggleSearch() {
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppTimeColors.of(context).bgDeep,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                // 포지셔닝 힌트 — "주변에서 할인·이벤트 편지를 주우면 혜택이
                // 있어요" 메시지 한 줄. 브랜드 포지셔닝 변경으로 브랜드도
                // 줍기 가능해졌기에 모든 등급에 표시.
                Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🎟', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppL10n.of(state.currentUser.languageCode)
                                .inboxHuntHint,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 만료 사이렌 (Build 115, Build 116 에서 탭 가능) — 24h 이내
                // 만료되는 쿠폰/교환권이 있을 때만 붉은 배너 노출. 탭 시
                // 쿠폰 필터로 즉시 전환 + 받은 편지 탭으로 이동해 사용 유도.
                Builder(builder: (ctx) {
                  final expiring = state.expiringSoonLetters;
                  if (expiring.isEmpty) return const SizedBox.shrink();
                  final l10n = AppL10n.of(state.currentUser.languageCode);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _inboxFilter = LetterFilterType.coupon;
                        _tabController.animateTo(0);
                      });
                    },
                    child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFFF5A4B).withValues(alpha: 0.18),
                          AppColors.coupon.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF5A4B).withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.expirySirenTitle(expiring.length),
                            style: const TextStyle(
                              color: AppColors.coupon,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.expirySirenCta,
                          style: const TextStyle(
                            color: Color(0xFFFF5A4B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  );
                }),
                // Build 179: 3-stat card (new/transit/total) 을 한 줄 compact
                // pill 로 축소. 수직 공간 ~60px 회수.
                Builder(builder: (ctx) {
                  final newCount = state.inbox.where((l) => l.status == DeliveryStatus.delivered).length;
                  final transitCount = state.inbox.where((l) => l.status == DeliveryStatus.inTransit || l.status == DeliveryStatus.nearYou).length;
                  final l10n = AppL10n.of(state.currentUser.languageCode);
                  if (newCount == 0 && transitCount == 0) {
                    return const SizedBox(height: 6);
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (newCount > 0) ...[
                          Text(
                            '📩 ${l10n.inboxStatNew} $newCount',
                            style: AppText.caption.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (transitCount > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 2, height: 2,
                              decoration: const BoxDecoration(
                                color: AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ],
                        if (transitCount > 0)
                          Text(
                            '🚀 ${l10n.inboxStatTransit} $transitCount',
                            style: AppText.caption.copyWith(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _InboxTab(
                        letters: _applySort(
                          _applyFilter(
                            // 뮤트된 브랜드 편지는 인박스 리스트에서 숨김
                            // (카드 자체 제거 — 필터와 무관하게 모든 탭에서).
                            // Build 115: 팔로우한 브랜드 편지는 상단 고정.
                            _sortFollowedFirst(
                              state,
                              state.inbox
                                  .where((l) => !(l.senderIsBrand &&
                                      state.isBrandMuted(l.senderId)))
                                  .toList()
                                  .reversed
                                  .toList(),
                            ),
                            filter: _inboxFilter,
                            isInbox: true,
                          ),
                          _inboxSort,
                        ),
                        activeFilter: _inboxFilter,
                        onFilterChanged: (next) {
                          setState(() => _inboxFilter = next);
                        },
                        // Build 169: 정렬 상태 + 변경 콜백.
                        activeSort: _inboxSort,
                        onSortChanged: (next) {
                          setState(() => _inboxSort = next);
                        },
                        onTap: (letter) => _openLetter(context, letter, state),
                        sentSinceLastUnlock: state.sentSinceLastUnlock,
                        canViewNext: state.canViewNextLetter,
                        scrollController: _inboxScrollController,
                      ),
                      _SentTab(
                        letters: _applyFilter(
                          state.sent.reversed.toList(),
                          filter: _sentFilter,
                          isInbox: false,
                        ),
                        activeFilter: _sentFilter,
                        onFilterChanged: (next) {
                          setState(() => _sentFilter = next);
                        },
                      ),
                      // DM 탭 제거 — 포지셔닝 변경으로 DM 기능 숨김.
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  /// Build 153: 이번 달(로컬 타임존) 수령 편지 수 집계.
  /// 월 경계는 `arrivedAt.year == now.year && month == now.month` 기준.
  int _countThisMonth(List<Letter> letters) {
    final now = DateTime.now();
    return letters.where((l) {
      final a = l.arrivedAt;
      if (a == null) return false;
      return a.year == now.year && a.month == now.month;
    }).length;
  }

  Widget _buildHeader(BuildContext ctx, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    return Padding(
      // Build 179: 세로 패딩 축소 (16→12), 내부 구조 단일화.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Build 179: title fontSize 26→22, subtitle caps 제거.
                    // 전체 수집 수가 제목 옆에 "· 30" 형식으로 바로 노출.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                          ).createShader(b),
                          child: Text(
                            l10n.navCollection,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${state.inbox.length}',
                          style: AppText.small.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Build 179: Monthly progress 만 남김 (subtitle caps + total 수 제거 — title 옆으로 흡수).
                    _MonthlyProgressBar(
                      collected: _countThisMonth(state.inbox),
                      target: 50,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              // 검색 버튼
              IconButton(
                onPressed: _toggleSearch,
                icon: Icon(
                  _searchMode ? Icons.search_off_rounded : Icons.search_rounded,
                  color: _searchMode ? AppColors.gold : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              if (!_searchMode && state.unreadCount > 0)
                GestureDetector(
                  onTap: () {
                    _tabController.animateTo(0);
                    final letters = _applyFilter(
                      state.inbox.reversed.toList(),
                      filter: _inboxFilter,
                      isInbox: true,
                    );
                    _scrollToFirstUnread(letters);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📩', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '${state.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_downward_rounded,
                          color: AppColors.gold,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // 검색 바 (검색 모드일 때만 표시)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axisAlignment: -1,
              child: child,
            ),
            child: _searchMode
                ? Padding(
                    key: const ValueKey('searchbar'),
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: l10n.inboxSearchHint,
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.bgCard,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('nosearch')),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.bgDeep,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
        tabs: [
          Tab(text: _l10n(context).inboxTabReceived),
          Tab(text: _l10n(context).inboxTabSent),
        ],
      ),
    );
  }

  void _openLetter(BuildContext ctx, Letter letter, AppState state) {
    // Block opening deliveredFar letters
    if (letter.status == DeliveryStatus.deliveredFar) {
      final l10n = _l10n(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.inboxLocalOnly),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    // Chain rule: first unread letter is always free to open
    if (letter.status == DeliveryStatus.delivered) {
      final unread = state.inbox
          .where((l) => l.status == DeliveryStatus.delivered)
          .toList();
      // The first unread (oldest) is always free; subsequent ones need chain rule
      final bool isFirstUnread =
          unread.isNotEmpty && unread.first.id == letter.id;
      if (!isFirstUnread && !state.canViewNextLetter) {
        _showChainRuleDialog(ctx, state);
        return;
      }
      if (!isFirstUnread && state.canViewNextLetter) {
        state.consumeLetterUnlock();
      }
    }
    state.readLetter(letter.id);
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LetterReadScreen(
          letter: letter,
          userLanguageCode: state.currentUser.languageCode,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showChainRuleDialog(BuildContext ctx, AppState state) {
    final l10n = _l10n(ctx);
    final remaining = 3 - state.sentSinceLastUnlock;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '📬 ${l10n.inboxLetterLocked}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.inboxSendMoreToRead(remaining),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.sentSinceLastUnlock / 3.0,
                backgroundColor: AppColors.bgSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inboxLettersSent(state.sentSinceLastUnlock, 3),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(l10n.inboxConfirm, style: const TextStyle(color: AppColors.bgDeep)),
          ),
        ],
      ),
    );
  }
}

void _confirmDelete(
  BuildContext ctx,
  AppState state,
  String letterId, {
  required bool isInbox,
}) {
  final l10n = AppL10n.of(state.currentUser.languageCode);
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.inboxDeleteTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        l10n.inboxDeleteBody,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.inboxCancel, style: const TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            if (isInbox)
              state.deleteFromInbox(letterId);
            else
              state.deleteFromSent(letterId);
          },
          child: Text(
            l10n.inboxDelete,
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

// ── 받은 편지 탭 ──────────────────────────────────────────────────────────────
class _InboxTab extends StatelessWidget {
  final List<Letter> letters;
  final LetterFilterType activeFilter;
  final ValueChanged<LetterFilterType> onFilterChanged;
  // Build 169: 정렬 상태.
  final InboxSortType activeSort;
  final ValueChanged<InboxSortType> onSortChanged;
  final void Function(Letter) onTap;
  final int sentSinceLastUnlock;
  final bool canViewNext;
  final ScrollController? scrollController;

  const _InboxTab({
    required this.letters,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.activeSort,
    required this.onSortChanged,
    required this.onTap,
    required this.sentSinceLastUnlock,
    required this.canViewNext,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // 체인 룰 해제 — "3통 보내야 읽기" 게이트와 🔒 배너 모두 제거됨.
    // (unread / showChainBanner 계산이 필요 없어져 삭제.)
    return Column(
      children: [
        _LetterFilterBar(
          activeFilter: activeFilter,
          onChanged: onFilterChanged,
        ),
        // Build 169: 정렬 선택 칩 row — 필터 아래 얇은 띠.
        _InboxSortBar(
          activeSort: activeSort,
          onChanged: onSortChanged,
          l10n: l10n,
        ),
        if (letters.isEmpty)
          Expanded(
            child: Builder(builder: (ctx) {
              // Build 115 — "지금 근처에 N통 있어요" 실시간 카운터를 부제에
              // 덧붙여 empty state 가 "죽은 공간" 이 되지 않게 한다.
              final state = ctx.read<AppState>();
              final nearby = state.nearbyLetters.length;
              final baseSub = l10n.inboxEmptyReceivedSub;
              final sub = nearby > 0
                  ? '$baseSub\n${l10n.inboxEmptyNearbyCount(nearby)}'
                  : baseSub;
              return _EmptyState(
                emoji: _emptyEmojiForFilter(activeFilter),
                title: activeFilter == LetterFilterType.all
                    ? l10n.inboxEmptyReceived
                    : l10n.inboxEmptyForFilter(_filterName(activeFilter, l10n)),
                subtitle: sub,
                // 헌트 모드(쿠폰·교환권·브랜드)에서는 편지 쓰기 대신 지도로
                // 유도한다 — "없는 편지"를 사용자가 직접 주우러 가야 하므로.
                ctaLabel: _isHuntFilter(activeFilter)
                    ? l10n.emptyStateExploreCta
                    : l10n.emptyStateWriteCta,
                onCtaTap: () => _isHuntFilter(activeFilter)
                    ? Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home', (route) => false)
                    : Navigator.of(context).pushNamed('/compose'),
              );
            }),
          )
        else ...[
          // "🔒 3통 보내야 다음 읽기" 체인 배너 제거 — 답장 무제한 정책과
          // 정합 맞추기. `sentSinceLastUnlock` 카운터는 통계용으로 유지.
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: letters.length,
              itemBuilder: (ctx, i) {
                final letter = letters[i];
                // 체인 룰 해제로 잠금 표시 항상 false.
                const isLocked = false;
                // Build 183: 받은 편지 카드 양방향 스와이프 —
                //   → (startToEnd): 사용 완료 (초록)
                //   ← (endToStart): 삭제 (빨강)
                // mark-used 는 dismissible 이 아니라 일반 swipe callback 으로
                // 처리. dismissed 되면 카드가 사라지지만 mark used 후에도
                // 카드는 유지해야 하므로 `confirmDismiss` false 반환 + 별도
                // markRedeemed 호출로 상태 갱신.
                final alreadyUsed =
                    ctx.read<AppState>().isLetterRedeemed(letter.id);
                return Dismissible(
                  key: ValueKey(letter.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(
                      color: alreadyUsed
                          ? const Color(0xFF435448)
                          : const Color(0xFF1A6B45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alreadyUsed
                              ? l10n.inboxAlreadyUsed
                              : l10n.inboxMarkUsed,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1A1A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.inboxDelete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // 사용 완료 토글: 이미 사용됐으면 무시 (snackbar 로 알림).
                      if (alreadyUsed) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(l10n.inboxAlreadyUsedSnack),
                            backgroundColor: const Color(0xFF1A2332),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return false;
                      }
                      ctx.read<AppState>().markLetterRedeemed(letter.id);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(l10n.inboxMarkedUsed),
                          backgroundColor: const Color(0xFF1A6B45),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      return false; // 카드 제거 안 함 — 상태만 바뀜.
                    }
                    // 삭제 확인 다이얼로그
                    return await showDialog<bool>(
                          context: ctx,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: const Color(0xFF1A2332),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              l10n.inboxDeleteTitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              l10n.inboxDeleteConfirm,
                              style: const TextStyle(color: Color(0xFF8899AA)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, false),
                                child: Text(
                                  l10n.inboxCancel,
                                  style: const TextStyle(color: Color(0xFF8899AA)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: Text(
                                  l10n.inboxDelete,
                                  style: const TextStyle(color: Color(0xFFFF6B6B)),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      ctx.read<AppState>().deleteFromInbox(letter.id);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(l10n.inboxDeleted),
                          backgroundColor: const Color(0xFF1A2332),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  child: _LetterCard(
                    letter: letter,
                    isInbox: true,
                    isLocked: isLocked,
                    onTap: () => onTap(letter),
                    onDelete: () => _confirmDelete(
                      ctx,
                      ctx.read<AppState>(),
                      letter.id,
                      isInbox: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── 보낸 편지 탭 ──────────────────────────────────────────────────────────────
class _SentTab extends StatelessWidget {
  final List<Letter> letters;
  final LetterFilterType activeFilter;
  final ValueChanged<LetterFilterType> onFilterChanged;

  const _SentTab({
    required this.letters,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Column(
      children: [
        _LetterFilterBar(
          activeFilter: activeFilter,
          onChanged: onFilterChanged,
        ),
        if (letters.isEmpty)
          Expanded(
            child: _EmptyState(
              emoji: activeFilter == LetterFilterType.all
                  ? '📮'
                  : _emptyEmojiForFilter(activeFilter),
              title: activeFilter == LetterFilterType.all
                  ? l10n.inboxEmptySent
                  : l10n.inboxEmptyForFilter(_filterName(activeFilter, l10n)),
              subtitle: l10n.inboxEmptySentSub,
              ctaLabel: l10n.emptyStateWriteCta,
              onCtaTap: () => Navigator.of(context).pushNamed('/compose'),
              // 발송함의 "헌트 모드" 필터(할인권·교환권·브랜드)는 발송 이력
              // 기반이므로 CTA는 "편지 쓰기"로 유지 (수신함과 다름).
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: letters.length,
              itemBuilder: (ctx, i) {
                final letter = letters[i];
                return Dismissible(
                  key: ValueKey(letter.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1A1A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.inboxDelete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: ctx,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: const Color(0xFF1A2332),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              l10n.inboxDeleteTitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              l10n.inboxDeleteConfirm,
                              style: const TextStyle(color: Color(0xFF8899AA)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, false),
                                child: Text(
                                  l10n.inboxCancel,
                                  style: const TextStyle(color: Color(0xFF8899AA)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: Text(
                                  l10n.inboxDelete,
                                  style: const TextStyle(color: Color(0xFFFF6B6B)),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) {
                    ctx.read<AppState>().deleteFromSent(letter.id);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(l10n.inboxDeleted),
                        backgroundColor: const Color(0xFF1A2332),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: _LetterCard(
                    letter: letter,
                    isInbox: false,
                    onTap: () => _showSentDetail(ctx, letter),
                    onDelete: () => _confirmDelete(
                      ctx,
                      ctx.read<AppState>(),
                      letter.id,
                      isInbox: false,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showSentDetail(BuildContext ctx, Letter letter) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SentDetailSheet(
        letter: letter,
        onTrackTap:
            (letter.status == DeliveryStatus.inTransit ||
                letter.status == DeliveryStatus.nearYou)
            ? () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => LetterTrackingScreen(letterId: letter.id),
                ),
              )
            : null,
      ),
    );
  }
}

// ── 편지 카드 ─────────────────────────────────────────────────────────────────
class _LetterCard extends StatelessWidget {
  final Letter letter;
  final bool isInbox;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _LetterCard({
    required this.letter,
    required this.isInbox,
    this.isLocked = false,
    required this.onTap,
    this.onDelete,
  });

  bool get _isUnread => isInbox && letter.status == DeliveryStatus.delivered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.bgCard.withValues(alpha: 0.4)
                  : AppColors.bgCard,
              borderRadius: BorderRadius.circular(22),
              border: _isUnread
                  ? Border.all(color: AppColors.gold, width: 1.5)
                  : null,
              boxShadow: _isUnread && !isLocked
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 국가 플래그
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isInbox
                          ? letter.senderCountryFlag
                          : letter.destinationCountryFlag,
                      style: const TextStyle(fontSize: 26),
                    ),
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
                              isInbox
                                  ? (letter.isAnonymous
                                        ? l10n.inboxAnonymousLetter
                                        : letter.senderName)
                                  : '→ ${CountryL10n.localizedName(letter.destinationCountry, l10n.languageCode)}',
                              style: TextStyle(
                                color: _isUnread
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: _isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 브랜드 뱃지 — category 가 coupon/voucher 면 쿠폰
                          // 색조(teal)로, 일반편지는 기존 오렌지 그라디언트로.
                          if (letter.senderIsBrand ||
                              letter.letterType == LetterType.brandExpress) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: letter.category ==
                                            LetterCategory.coupon ||
                                        letter.category ==
                                            LetterCategory.voucher
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF00BFA5),
                                          Color(0xFF4DD0E1),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8C00),
                                          Color(0xFFFFB347),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    letter.category == LetterCategory.coupon
                                        ? '🎟'
                                        : letter.category ==
                                                LetterCategory.voucher
                                            ? '🎁'
                                            : '🏢',
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    letter.category == LetterCategory.coupon
                                        ? l10n.inboxFilterCoupon
                                        : letter.category ==
                                                LetterCategory.voucher
                                            ? l10n.inboxFilterVoucher
                                            : l10n.labelBrand,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (letter.letterType ==
                                      LetterType.brandExpress) ...[
                                    const SizedBox(width: 2),
                                    const Text(
                                      '⚡',
                                      style: TextStyle(fontSize: 9),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (letter.senderId.startsWith('ai_')) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🤖',
                                      style: TextStyle(fontSize: 9)),
                                  const SizedBox(width: 2),
                                  Text(
                                    l10n.labelAiCurated,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        letter.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isUnread
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // 발송지
                          Text(
                            '${letter.senderCountryFlag} ${CountryL10n.localizedName(letter.senderCountry, l10n.languageCode)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          // 보낸 편지 읽음 여부
                          if (!isInbox && letter.isReadByRecipient)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ ${l10n.inboxRead}',
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // 상태
                          _StatusBadge(status: letter.status, isInbox: isInbox),
                        ],
                      ),
                      // 배송 게이지 (보낸 편지 + 배송 중)
                      if (!isInbox &&
                          letter.status == DeliveryStatus.inTransit) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: letter.overallProgress,
                            backgroundColor: AppColors.bgSurface,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.teal,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${letter.currentTransport.emoji} ${(letter.overallProgress * 100).toStringAsFixed(0)}% · ${letter.etaLabel} ${l10n.inboxEta}',
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 잠금 오버레이 (chain rule)
          if (isLocked)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.inboxSend3ToOpen,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 삭제 버튼 (우상단)
          if (onDelete != null && !isLocked)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 15,
                  ),
                ),
              ),
            ),
          // 현지 수령 필요 오버레이 (deliveredFar)
          if (letter.status == DeliveryStatus.deliveredFar)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 브랜드 편지는 카테고리 맞춤 이모지로 "어떤 편지인지" 표시.
                      Text(
                        letter.senderIsBrand ? letter.category.brandEmoji : '📬',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.inboxLocalOnly,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Build 169: 수집첩 정렬 선택 바 — 4 가지 옵션 수평 chip.
/// Filter 바 아래 얇은 띠로 배치. 기본 선택은 최신순.
class _InboxSortBar extends StatelessWidget {
  final InboxSortType activeSort;
  final ValueChanged<InboxSortType> onChanged;
  final AppL10n l10n;

  const _InboxSortBar({
    required this.activeSort,
    required this.onChanged,
    required this.l10n,
  });

  /// Build 183: 툴팁용 라벨 (accessibility + hover). 화면에는 이모지만.
  String _label(InboxSortType type) {
    switch (type) {
      case InboxSortType.newest:
        return l10n.inboxSortNewest;
      case InboxSortType.expiringSoon:
        return l10n.inboxSortExpiring;
      case InboxSortType.byBrand:
        return l10n.inboxSortByBrand;
      case InboxSortType.byCategory:
        return l10n.inboxSortByCategory;
      case InboxSortType.usedOnly:
        return l10n.inboxSortUsedOnly;
    }
  }

  String _emoji(InboxSortType type) {
    switch (type) {
      case InboxSortType.newest:
        return '🕐';
      case InboxSortType.expiringSoon:
        return '⏰';
      case InboxSortType.byBrand:
        return '🏢';
      case InboxSortType.byCategory:
        return '🎟';
      case InboxSortType.usedOnly:
        return '✅';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build 183: 아이콘 전용 — 라벨은 Tooltip/Semantics 로만 노출. 화면을
    // 깔끔하게 유지 + 공간 회수. 활성 아이콘은 gold tint + 굵은 테두리.
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final type in InboxSortType.values) ...[
            Tooltip(
              message: _label(type),
              child: Semantics(
                label: _label(type),
                button: true,
                selected: activeSort == type,
                child: InkWell(
                  onTap: () => onChanged(type),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    width: 34,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activeSort == type
                          ? AppColors.gold.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: activeSort == type
                            ? AppColors.gold.withValues(alpha: 0.65)
                            : AppColors.textMuted.withValues(alpha: 0.2),
                        width: activeSort == type ? 1.3 : 0.8,
                      ),
                    ),
                    child: Text(
                      _emoji(type),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
            if (type != InboxSortType.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _LetterFilterBar extends StatelessWidget {
  final LetterFilterType activeFilter;
  final ValueChanged<LetterFilterType> onChanged;

  const _LetterFilterBar({required this.activeFilter, required this.onChanged});

  String _label(LetterFilterType type, AppL10n l10n) {
    switch (type) {
      case LetterFilterType.all:
        return l10n.inboxFilterAll;
      case LetterFilterType.read:
        return l10n.inboxRead;
      case LetterFilterType.inTransit:
        return l10n.inboxFilterInTransit;
      case LetterFilterType.waitingPickup:
        return l10n.inboxFilterWaiting;
      case LetterFilterType.brand:
        return '🏢 ${l10n.inboxFilterBrand}';
      case LetterFilterType.coupon:
        return '🎟 ${l10n.inboxFilterCoupon}';
      case LetterFilterType.voucher:
        return '🎁 ${l10n.inboxFilterVoucher}';
      case LetterFilterType.general:
        return '✉️ ${l10n.inboxFilterGeneral}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        // 4개만 렌더 (_visibleFilters) — 나머지 enum 값(read/inTransit/waiting) 숨김
        children: _visibleFilters.map((type) {
          final selected = type == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _label(type, l10n),
                style: TextStyle(
                  color: selected ? AppColors.bgDeep : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: selected,
              onSelected: (_) => onChanged(type),
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.bgCard,
              side: BorderSide(
                color: selected
                    ? AppColors.gold.withValues(alpha: 0.75)
                    : const Color(0xFF304256),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DeliveryStatus status;
  final bool isInbox;

  const _StatusBadge({required this.status, required this.isInbox});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    Color color;
    String label;

    if (!isInbox) {
      switch (status) {
        case DeliveryStatus.inTransit:
          color = AppColors.teal;
          label = '✈️ ${l10n.inboxStatusInTransit}';
          break;
        case DeliveryStatus.nearYou:
          color = AppColors.gold;
          label = '📍 ${l10n.inboxStatusNearby}';
          break;
        case DeliveryStatus.deliveredFar:
          color = AppColors.warning;
          label = '📬 ${l10n.inboxStatusWaiting}';
          break;
        case DeliveryStatus.delivered:
        case DeliveryStatus.read:
          color = AppColors.success;
          label = '✅ ${l10n.inboxStatusDelivered}';
          break;
        default:
          color = AppColors.textMuted;
          label = '—';
      }
    } else {
      switch (status) {
        case DeliveryStatus.deliveredFar:
          color = AppColors.warning;
          label = '📬 ${l10n.inboxStatusWaiting}';
          break;
        case DeliveryStatus.delivered:
          color = AppColors.gold;
          label = '📩 ${l10n.inboxStatusNewLetter}';
          break;
        case DeliveryStatus.read:
          color = AppColors.textMuted;
          label = '✓ ${l10n.inboxRead}';
          break;
        default:
          color = AppColors.textMuted;
          label = '—';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── 빈 상태 ──────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCtaTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(ctaLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 보낸 편지 상세 ───────────────────────────────────────────────────────────
class _SentDetailSheet extends StatelessWidget {
  final Letter letter;
  final VoidCallback? onTrackTap;

  const _SentDetailSheet({required this.letter, this.onTrackTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 28),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Builder(
                  builder: (_) {
                    final raw = letter.deliveryEmoji;
                    if (raw == null || raw.isEmpty) {
                      return const Icon(
                        Icons.flight_rounded,
                        color: AppColors.teal,
                        size: 18,
                      );
                    }
                    // "|" 구분 포맷 → 선택된 이모티콘만 모아 표시
                    final parts = raw.split('|');
                    final selected = parts.where((e) => e.isNotEmpty).toList();
                    if (selected.isEmpty) {
                      return const Icon(
                        Icons.flight_rounded,
                        color: AppColors.teal,
                        size: 18,
                      );
                    }
                    return Text(
                      selected.join(' '),
                      style: const TextStyle(fontSize: 18),
                    );
                  },
                ),
              ),
              Text(
                letter.destinationCountryFlag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '→ ${CountryL10n.localizedName(letter.destinationCountry, l10n.languageCode)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (letter.destinationCity != null &&
                        letter.destinationCity!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            letter.destinationCity!,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      letter.currentStageLabel,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: letter.overallProgress,
            backgroundColor: AppColors.bgSurface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(letter.overallProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.inboxEtaRemaining(letter.etaLabel),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 배송 경로
          ...letter.segments.asMap().entries.map(
            (e) => _RouteStep(
              segment: e.value,
              isActive: e.key <= letter.currentSegmentIndex,
              isCurrent: e.key == letter.currentSegmentIndex,
              isLastSegment: e.key == letter.segments.length - 1,
              destinationDisplayAddress: letter.destinationDisplayAddress,
            ),
          ),
          // 지도에서 배송 추적 버튼 (배송 중일 때만)
          if (onTrackTap != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onTrackTap!();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded, color: AppColors.teal, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '🗺️ ${l10n.inboxTrackOnMap}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RouteStep extends StatelessWidget {
  final RouteSegment segment;
  final bool isActive;
  final bool isCurrent;
  final bool isLastSegment;
  final String? destinationDisplayAddress;

  const _RouteStep({
    required this.segment,
    required this.isActive,
    required this.isCurrent,
    this.isLastSegment = false,
    this.destinationDisplayAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : isActive
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? AppColors.gold
                    : isActive
                    ? AppColors.teal.withValues(alpha: 0.4)
                    : AppColors.bgSurface,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                segment.mode.emoji,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${segment.fromName} → ${(isLastSegment && destinationDisplayAddress != null) ? destinationDisplayAddress! : segment.toName}',
              style: TextStyle(
                color: isCurrent
                    ? AppColors.gold
                    : isActive
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrent)
            const Icon(Icons.circle, size: 8, color: AppColors.gold),
          if (!isCurrent && isActive)
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

// ── DM 탭 ─────────────────────────────────────────────────────────────────────
class _DMTab extends StatelessWidget {
  const _DMTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final sessions =
            state.chatSessions.values
                .where(
                  (s) =>
                      s.status == ChatStatus.chatting ||
                      s.status == ChatStatus.pendingAgreement,
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💬', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  l10n.inboxNoDM,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.inboxNoDMSub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (_, i) {
            final session = sessions[i];
            final messages = state.getDMConversation(session.partnerId);
            final lastMsg = messages.isNotEmpty ? messages.last : null;

            return GestureDetector(
              onTap: () {
                if (session.status == ChatStatus.pendingAgreement) {
                  // Show agreement dialog
                  showDialog(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        '${session.partnerFlag} ${l10n.inboxDMChatWith(session.partnerName)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        l10n.inboxDMStartPrompt,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.declineChatInvite(session.partnerId);
                          },
                          child: Text(
                            l10n.inboxCancel,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.acceptChatInvite(session.partnerId);
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => DmConversationScreen(
                                  partnerId: session.partnerId,
                                  partnerName: session.partnerName,
                                  partnerFlag: session.partnerFlag,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            l10n.inboxStartChat,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => DmConversationScreen(
                        partnerId: session.partnerId,
                        partnerName: session.partnerName,
                        partnerFlag: session.partnerFlag,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: session.unreadCount > 0
                        ? AppColors.teal.withValues(alpha: 0.4)
                        : AppColors.bgSurface,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          session.partnerFlag,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                session.partnerName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (session.status == ChatStatus.pendingAgreement)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.inboxInvite,
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lastMsg?.content ??
                                (session.status == ChatStatus.pendingAgreement
                                    ? l10n.inboxMutualFollow
                                    : l10n.inboxStartConversation),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (session.unreadCount > 0)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${session.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── 팔로잉/팔로워 탭 (향후 소셜 기능 확장 시 사용) ─────────────────────────
// ignore: unused_element
class _FollowListTab extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final Map<String, dynamic> sessions;

  const _FollowListTab({
    required this.title,
    required this.userIds,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final isFollowing = title == l10n.inboxFollowing;
    if (userIds.isEmpty) {
      return _EmptyState(
        emoji: isFollowing ? '🔭' : '🌟',
        title: isFollowing ? l10n.inboxNoFollowing : l10n.inboxNoFollowers,
        subtitle: isFollowing
            ? l10n.inboxNoFollowingSub
            : l10n.inboxNoFollowersSub,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: userIds.length,
      itemBuilder: (ctx, i) {
        final uid = userIds[i];
        final session = sessions[uid];
        final name = session?.partnerName ?? uid;
        final flag = session?.partnerFlag ?? '🌍';
        final country = session?.partnerCountry ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bgSurface),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (country.isNotEmpty)
                      Text(
                        '$flag $country',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (session != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '💬 DM',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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


/// Build 153: 이번 달 수령 편지 진척도 막대.
/// 50통 목표 대비 현재까지 수집 비율 + 색상 티어링:
///   < 50% : teal
///   50–99%: gold
///   >= 100%: gold 애니메이션 (달성)
class _MonthlyProgressBar extends StatelessWidget {
  final int collected;
  final int target;
  final AppL10n l10n;
  const _MonthlyProgressBar({
    required this.collected,
    required this.target,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : (collected / target).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final reached = collected >= target;
    final color = reached
        ? AppColors.gold
        : (ratio >= 0.5 ? AppColors.gold : AppColors.teal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.inboxMonthlyGoalLabel(collected, target),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              reached ? "🏆 $pct%" : "$pct%",
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
