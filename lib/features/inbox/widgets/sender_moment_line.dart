import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';

/// Emotional sender-context line — "🌙 밤 11시에 쓴 편지" etc.
///
/// Uses the sender's longitude as a crude timezone proxy (lng / 15 ≈ hours
/// offset from UTC). That misses DST and political zones, but is precise
/// enough to say "late night" vs "early morning" for the emotional framing
/// we want (we are NOT scheduling anything off this number).
class SenderMomentLine extends StatelessWidget {
  final Letter letter;

  const SenderMomentLine({super.key, required this.letter});

  int _senderLocalHour() {
    final lng = letter.originLocation.longitude;
    // crude TZ offset — longitude / 15 rounded to nearest hour
    final offsetHours = (lng / 15).round();
    final utc = letter.sentAt.toUtc();
    final localHour = (utc.hour + offsetHours) % 24;
    return localHour < 0 ? localHour + 24 : localHour;
  }

  String _partOfDayEmoji(int hour) {
    if (hour >= 5 && hour < 11) return '☀️';
    if (hour >= 11 && hour < 17) return '🌤️';
    if (hour >= 17 && hour < 21) return '🌆';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    // 내가 보낸 편지엔 표시하지 않음
    if (letter.senderId == state.currentUser.id) {
      return const SizedBox.shrink();
    }
    // 시스템/웰컴 편지는 "실시간 시각" 감성이 맞지 않으므로 제외
    if (letter.senderId == 'letter_go_welcome' ||
        letter.senderId.startsWith('ai_') ||
        letter.senderId.startsWith('mock_')) {
      return const SizedBox.shrink();
    }

    final l10n = AppL10n.of(state.currentUser.languageCode);
    final hour = _senderLocalHour();
    final emoji = _partOfDayEmoji(hour);
    final text = l10n.senderMomentLine(hour);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
