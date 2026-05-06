import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';

/// v5 Stamp Album.
///
/// 이전 (Build 198): emoji 만 큰 grid 3-col → 컨텐츠 식별 어렵고 시각적으로 답답.
/// 신규 (Build 200): 리스트 뷰 — 작은 flag + 큰 국가명 + 편지 수 + 최근 수신일.
/// 정보 밀도와 가독성 우선.
class StampAlbumScreen extends StatelessWidget {
  const StampAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = context.select<AppState, List<Letter>>((s) => s.inbox);
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l = AppL10n.of(langCode);

    // 받은 편지에서 발신 국가 수집
    final Map<String, _StampEntry> stamps = {};
    for (final letter in inbox) {
      final key = letter.senderCountry;
      final arrived = letter.arrivedAt ?? letter.sentAt;
      if (stamps.containsKey(key)) {
        stamps[key]!.count++;
        if (arrived.isAfter(stamps[key]!.lastReceivedAt)) {
          stamps[key]!.lastReceivedAt = arrived;
        }
        if (arrived.isBefore(stamps[key]!.firstReceivedAt)) {
          stamps[key]!.firstReceivedAt = arrived;
        }
      } else {
        stamps[key] = _StampEntry(
          country: letter.senderCountry,
          flag: letter.senderCountryFlag,
          count: 1,
          firstReceivedAt: arrived,
          lastReceivedAt: arrived,
        );
      }
    }
    final stampList = stamps.values.toList()
      ..sort((a, b) => b.lastReceivedAt.compareTo(a.lastReceivedAt));

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.stampAlbumTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: stampList.isEmpty
          ? _buildEmpty(context, l)
          : Column(
              children: [
                _buildHeader(stampList.length, inbox.length, l),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: stampList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _buildStampRow(context, stampList[i], l, langCode),
                  ),
                ),
              ],
            ),
    );
  }

  // ── 헤더 (v5 stat 카드 — UPPERCASE eyebrow + 큰 숫자) ──────────────────────
  Widget _buildHeader(int countryCount, int totalLetters, AppL10n l) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              value: '$countryCount',
              label: l.stampVisited,
              color: AppColors.gold,
            ),
          ),
          Container(width: 0.5, height: 32, color: AppColors.bgSurface),
          Expanded(
            child: _statCell(
              value: '$totalLetters',
              label: l.stampReceived,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ── 스탬프 행 — flag + 국가명 + 편지 수 + 최근 수신일 ──────────────────────
  Widget _buildStampRow(
    BuildContext context,
    _StampEntry stamp,
    AppL10n l,
    String langCode,
  ) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showStampDetail(context, stamp, l, langCode),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // 작은 원형 flag
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                ),
                child: Text(stamp.flag, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              // 국가명 + 메타 (왼쪽)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CountryL10n.localizedName(stamp.country, langCode),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeDate(stamp.lastReceivedAt, l),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 카운트 (오른쪽)
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${stamp.count}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const TextSpan(
                      text: '\nLETTERS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 상세 시트 ─────────────────────────────────────────────────────────────
  void _showStampDetail(
    BuildContext context,
    _StampEntry stamp,
    AppL10n l,
    String langCode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.bgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(stamp.flag, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CountryL10n.localizedName(stamp.country, langCode),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stamp.count} ${l.stampReceived}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow(
              label: l.stampFirstReceived(_formatDate(stamp.firstReceivedAt))
                  .split(' ')
                  .first,
              value: _formatDate(stamp.firstReceivedAt),
            ),
            const SizedBox(height: 12),
            _detailRow(
              label: 'LAST',
              value: _formatDate(stamp.lastReceivedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  String _relativeDate(DateTime dt, AppL10n l) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final lc = l.languageCode;
    final isKo = lc == 'ko';
    if (diff.inMinutes < 60) {
      return isKo ? '${diff.inMinutes}분 전' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isKo ? '${diff.inHours}시간 전' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return isKo ? '${diff.inDays}일 전' : '${diff.inDays}d ago';
    }
    return _formatDate(dt);
  }

  Widget _buildEmpty(BuildContext context, AppL10n l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.collections_bookmark_outlined,
                color: AppColors.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.stampEmptyTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.stampEmptyBody,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StampEntry {
  final String country;
  final String flag;
  int count;
  DateTime firstReceivedAt;
  DateTime lastReceivedAt;

  _StampEntry({
    required this.country,
    required this.flag,
    required this.count,
    required this.firstReceivedAt,
    required this.lastReceivedAt,
  });
}
