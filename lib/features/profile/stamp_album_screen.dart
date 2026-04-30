import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';

class StampAlbumScreen extends StatelessWidget {
  const StampAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // inbox 리스트만 구독 → 다른 AppState 변경에는 rebuild 안 함
    final inbox = context.select<AppState, List<Letter>>((s) => s.inbox);
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l = AppL10n.of(langCode);

    // 받은 편지에서 발신 국가 수집 (중복 제거, 나라별 편지 수)
    final Map<String, _StampEntry> stamps = {};
    for (final letter in inbox) {
      final key = letter.senderCountry;
      if (stamps.containsKey(key)) {
        stamps[key]!.count++;
      } else {
        stamps[key] = _StampEntry(
          country: letter.senderCountry,
          flag: letter.senderCountryFlag,
          count: 1,
          firstReceivedAt: letter.arrivedAt ?? DateTime.now(),
        );
      }
    }
    final stampList = stamps.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold],
          ).createShader(b),
          child: Text(
            l.stampAlbumTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 여권 표지 스타일 헤더
          _buildPassportHeader(
            context,
            stampList.length,
            inbox.length,
            l,
          ),
          // 스탬프 그리드
          Expanded(
            child: stampList.isEmpty
                ? _buildEmpty(context, l)
                : _buildStampGrid(context, stampList, l, langCode),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportHeader(
    BuildContext context,
    int countryCount,
    int totalLetters,
    AppL10n l,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // 여권 아이콘
          Container(
            width: 64,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.letter,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌍', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  l.labelPassport,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appName,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.stampAlbumSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _headerStat('🌏', l.stampCountriesCount(countryCount), l.stampVisited),
                    const SizedBox(width: 16),
                    _headerStat('💌', l.stampLettersCount(totalLetters), l.stampReceived),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String emoji, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStampGrid(BuildContext context, List<_StampEntry> stamps, AppL10n l, String langCode) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: stamps.length,
      itemBuilder: (context, index) {
        final stamp = stamps[index];
        return _buildStamp(context, stamp, index, l, langCode);
      },
    );
  }

  Widget _buildStamp(BuildContext context, _StampEntry stamp, int index, AppL10n l, String langCode) {
    return GestureDetector(
      onTap: () => _showStampDetail(context, stamp, l, langCode),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stamp.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                CountryL10n.localizedName(stamp.country, langCode),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                l.stampLettersCount(stamp.count).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStampDetail(BuildContext context, _StampEntry stamp, AppL10n l, String langCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(stamp.flag, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              CountryL10n.localizedName(stamp.country, langCode),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _detailStat('💌', l.stampReceivedCount(stamp.count)),
                const SizedBox(width: 24),
                _detailStat('📅', l.stampFirstReceived(_formatDate(stamp.firstReceivedAt))),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildEmpty(BuildContext context, AppL10n l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            l.stampEmptyTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.stampEmptyBody,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StampEntry {
  final String country;
  final String flag;
  int count;
  final DateTime firstReceivedAt;

  _StampEntry({
    required this.country,
    required this.flag,
    required this.count,
    required this.firstReceivedAt,
  });
}

class _StampBorderPainter extends CustomPainter {
  final Color color;
  _StampBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dotSize = 4.0;
    const gap = 6.0;

    for (double x = dotSize; x < size.width - dotSize; x += dotSize + gap) {
      canvas.drawCircle(Offset(x, 3), 2, paint..style = PaintingStyle.fill);
    }
    for (double x = dotSize; x < size.width - dotSize; x += dotSize + gap) {
      canvas.drawCircle(
        Offset(x, size.height - 3),
        2,
        paint..style = PaintingStyle.fill,
      );
    }
    for (double y = dotSize; y < size.height - dotSize; y += dotSize + gap) {
      canvas.drawCircle(Offset(3, y), 2, paint..style = PaintingStyle.fill);
    }
    for (double y = dotSize; y < size.height - dotSize; y += dotSize + gap) {
      canvas.drawCircle(
        Offset(size.width - 3, y),
        2,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_StampBorderPainter old) => false;
}
