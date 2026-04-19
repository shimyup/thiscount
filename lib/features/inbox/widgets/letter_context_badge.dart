import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';

/// 편지 상세 화면에 작은 개인 맥락 배지 표시.
/// "당신의 N번째 받은 편지 · 이집트에서 온 첫 편지" 같은 문구로
/// 개인화된 여정 감정 형성.
///
/// 조건부 렌더링:
/// - 받은 편지만 (내 발송 편지는 스킵)
/// - 2통 이상 받은 이후 노출 (첫 편지는 이미 감동)
class LetterContextBadge extends StatelessWidget {
  final Letter letter;

  const LetterContextBadge({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    // 내가 보낸 편지엔 표시 안 함
    if (letter.senderId == state.currentUser.id) {
      return const SizedBox.shrink();
    }

    final inbox = state.inbox;
    if (inbox.length < 2) return const SizedBox.shrink();

    // 이 편지가 몇 번째로 받은 편지인지 (수신 시각 순서)
    final sortedInbox = List.of(inbox)
      ..sort((a, b) {
        final aTime = a.arrivedAt ?? a.sentAt;
        final bTime = b.arrivedAt ?? b.sentAt;
        return aTime.compareTo(bTime);
      });
    final ordinal = sortedInbox.indexWhere((l) => l.id == letter.id) + 1;
    if (ordinal <= 0) return const SizedBox.shrink();

    // 해당 발신국에서 온 편지가 몇 통째인지
    final fromSameCountry = inbox
        .where((l) => l.senderCountry == letter.senderCountry)
        .toList()
      ..sort((a, b) {
        final aTime = a.arrivedAt ?? a.sentAt;
        final bTime = b.arrivedAt ?? b.sentAt;
        return aTime.compareTo(bTime);
      });
    final countryOrdinal =
        fromSameCountry.indexWhere((l) => l.id == letter.id) + 1;

    final langCode = state.currentUser.languageCode;
    final l10n = AppL10n.of(langCode);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('📬', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.letterContextReceivedOrdinal(ordinal),
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (countryOrdinal > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    countryOrdinal == 1
                        ? l10n.letterContextFirstFromCountry(
                            letter.senderCountry,
                          )
                        : l10n.letterContextNthFromCountry(
                            countryOrdinal,
                            letter.senderCountry,
                          ),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
