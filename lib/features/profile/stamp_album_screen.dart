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

    // 받은 편지에서 발신 국가 수집.
    // Build 305: containsKey + `!` 대신 local var 로 null safety 강제 보강 —
    // analyzer 가 flow 를 못 따라가 false-positive 가 잡힐 위험 차단.
    final Map<String, _StampEntry> stamps = {};
    for (final letter in inbox) {
      final key = letter.senderCountry;
      final arrived = letter.arrivedAt ?? letter.sentAt;
      final existing = stamps[key];
      if (existing != null) {
        existing.count++;
        if (arrived.isAfter(existing.lastReceivedAt)) {
          existing.lastReceivedAt = arrived;
        }
        if (arrived.isBefore(existing.firstReceivedAt)) {
          existing.firstReceivedAt = arrived;
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
    // Build 477: 진행 바 기준 — 최다 수집 국가 대비 비율(상대 진척).
    final maxCount = stampList.fold<int>(
      0,
      (m, s) => s.count > m ? s.count : m,
    );

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          tooltip: l.koEn('뒤로', 'Back'),
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
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 32),
                    itemCount: stampList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _buildStampRow(
                      context,
                      stampList[i],
                      l,
                      langCode,
                      maxCount,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── 헤더 (v5 stat 카드 — UPPERCASE eyebrow + 큰 숫자) ──────────────────────
  Widget _buildHeader(int countryCount, int totalLetters, AppL10n l) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 14),
      padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 18),
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

  // Build 477: 국가별 고정 색(쿠폰 팔레트) — 컬러풀한 우표 수집 느낌.
  static const List<Color> _stampPalette = [
    AppColors.coupon, // coral
    AppColors.teal, // lime-teal
    AppColors.gold,
    Color(0xFF5BA4F6), // blue
    Color(0xFFC77DFF), // purple
  ];

  // ── 스탬프 행 (Build 477: 쿠폰 티켓형) — 국기 패널 + 절취 점선 + 진행 바 ─────
  Widget _buildStampRow(
    BuildContext context,
    _StampEntry stamp,
    AppL10n l,
    String langCode,
    int maxCount,
  ) {
    final color = _stampPalette[stamp.country.hashCode.abs() % _stampPalette.length];
    final progress = maxCount > 0 ? (stamp.count / maxCount).clamp(0.0, 1.0) : 0.0;
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showStampDetail(context, stamp, l, langCode),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 좌측 국기 패널 (카테고리 색 틴트)
              Container(
                width: 60,
                alignment: Alignment.center,
                color: color.withValues(alpha: 0.12),
                child: Text(stamp.flag, style: const TextStyle(fontSize: 30)),
              ),
              // 절취 점선
              _StampDashLine(
                color: AppColors.textMuted.withValues(alpha: 0.32),
              ),
              // 국가명 + 최근일 + 진행 바
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        CountryL10n.localizedName(stamp.country, langCode),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _relativeDate(stamp.lastReceivedAt, l),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: AppColors.bgSurface,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 카운트 (우측)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 14, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stamp.count}',
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.koEn('수집', 'COLLECTED'),
                      style: const TextStyle(
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
        padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 32),
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
              // Build 409 (sim P2 L330): 영어 전용 'LAST' → 현지화.
              label: l.koEn('최근', 'LAST'),
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

// Build 477: 스탬프 티켓 카드 좌/우 절취 세로 점선.
class _StampDashLine extends StatelessWidget {
  final Color color;
  const _StampDashLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      child: CustomPaint(painter: _StampDashPainter(color)),
    );
  }
}

class _StampDashPainter extends CustomPainter {
  final Color color;
  _StampDashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    double y = 6;
    while (y < size.height - 6) {
      canvas.drawLine(Offset(0.5, y), Offset(0.5, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _StampDashPainter old) => old.color != color;
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
