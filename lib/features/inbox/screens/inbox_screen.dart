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

// all · read · inTransit · waitingPickup · brand (기존)
//   + coupon · voucher (브랜드 발송 편지의 카테고리별 쿠폰함 섹션용)
enum LetterFilterType { all, read, inTransit, waitingPickup, brand, coupon, voucher }

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
  String _searchQuery = '';
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();

  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

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
    _tabController = TabController(length: 3, vsync: this);
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
        case LetterFilterType.all:
          return true;
      }
    }).toList();
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
                Builder(builder: (ctx) {
                  final newCount = state.inbox.where((l) => l.status == DeliveryStatus.delivered).length;
                  final transitCount = state.inbox.where((l) => l.status == DeliveryStatus.inTransit || l.status == DeliveryStatus.nearYou).length;
                  final totalCount = state.inbox.length;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1F2D44)),
                    ),
                    child: Row(
                      children: [
                        _buildStatChip('새 편지', newCount.toString(), AppColors.gold),
                        const Expanded(child: SizedBox()),
                        Container(width: 1, height: 28, color: const Color(0xFF1F2D44)),
                        const Expanded(child: SizedBox()),
                        _buildStatChip('배달중', transitCount.toString(), AppColors.teal),
                        const Expanded(child: SizedBox()),
                        Container(width: 1, height: 28, color: const Color(0xFF1F2D44)),
                        const Expanded(child: SizedBox()),
                        _buildStatChip('총 수신', totalCount.toString(), AppColors.textSecondary),
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
                        letters: _applyFilter(
                          state.inbox.reversed.toList(),
                          filter: _inboxFilter,
                          isInbox: true,
                        ),
                        activeFilter: _inboxFilter,
                        onFilterChanged: (next) {
                          setState(() => _inboxFilter = next);
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
                      const _DMTab(),
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

  Widget _buildHeader(BuildContext ctx, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.gold],
                      ).createShader(b),
                      child: Text(
                        l10n.inbox,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      l10n.inboxSubtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l10n.inboxTotalReceived(state.inbox.length),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
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
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2D44)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: '📬 ${_l10n(context).inboxTabReceived}'),
          Tab(text: '📤 ${_l10n(context).inboxTabSent}'),
          Tab(text: '💬 ${_l10n(context).inboxTabDM}'),
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
  final void Function(Letter) onTap;
  final int sentSinceLastUnlock;
  final bool canViewNext;
  final ScrollController? scrollController;

  const _InboxTab({
    required this.letters,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onTap,
    required this.sentSinceLastUnlock,
    required this.canViewNext,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final unread = letters
        .where((l) => l.status == DeliveryStatus.delivered)
        .toList();
    final showChainBanner = unread.length > 1 && !canViewNext;
    return Column(
      children: [
        _LetterFilterBar(
          activeFilter: activeFilter,
          onChanged: onFilterChanged,
        ),
        if (letters.isEmpty)
          Expanded(
            child: _EmptyState(
              emoji: '📭',
              title: l10n.inboxEmptyReceived,
              subtitle: l10n.inboxEmptyReceivedSub,
              ctaLabel: l10n.emptyStateWriteCta,
              onCtaTap: () => Navigator.of(context).pushNamed('/compose'),
            ),
          )
        else ...[
          if (showChainBanner)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.inboxSendMoreToRead(3 - sentSinceLastUnlock),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: sentSinceLastUnlock / 3.0,
                            backgroundColor: AppColors.bgSurface,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.gold,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$sentSinceLastUnlock/3',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: letters.length,
              itemBuilder: (ctx, i) {
                final letter = letters[i];
                // 첫 번째 미읽음 이후 편지는 잠금 표시
                final isLocked =
                    showChainBanner &&
                    letter.status == DeliveryStatus.delivered &&
                    (unread.isNotEmpty && unread.last.id != letter.id);
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
              emoji: '📮',
              title: l10n.inboxEmptySent,
              subtitle: l10n.inboxEmptySentSub,
              ctaLabel: l10n.emptyStateWriteCta,
              onCtaTap: () => Navigator.of(context).pushNamed('/compose'),
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.bgCard.withValues(alpha: 0.4)
                  : _isUnread
                  ? AppColors.bgCard
                  : AppColors.bgCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLocked
                    ? AppColors.textMuted.withValues(alpha: 0.3)
                    : _isUnread
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : const Color(0xFF1F2D44),
                width: _isUnread ? 1.5 : 1.0,
              ),
              boxShadow: _isUnread && !isLocked
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
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
                      const Text('📬', style: TextStyle(fontSize: 24)),
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
        children: LetterFilterType.values.map((type) {
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
        border: Border.all(color: const Color(0xFF1F2D44)),
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
                    : const Color(0xFF1F2D44),
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
                        : const Color(0xFF1F2D44),
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
            border: Border.all(color: const Color(0xFF1F2D44)),
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
