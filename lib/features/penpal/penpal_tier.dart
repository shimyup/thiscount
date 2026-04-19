import '../../models/letter.dart';

/// Pen-pal tier is a function of how many letters you've received from the
/// same sender. Tiers unlock small emotional recognitions that the reader
/// and the sender have an ongoing exchange, not a one-off drop.
///
/// Tiers:
///   none      <3   — still just "that person who once wrote to you"
///   budding   3-4  — 🌱 "something is starting"
///   regular   5-9  — 🕊️ "this is a pen pal"
///   longtime  10+  — 📜 "the long-running thread"
enum PenpalTier { none, budding, regular, longtime }

class PenpalStats {
  final int exchanges;
  final PenpalTier tier;

  const PenpalStats({required this.exchanges, required this.tier});

  static PenpalTier _tierFor(int exchanges) {
    if (exchanges >= 10) return PenpalTier.longtime;
    if (exchanges >= 5) return PenpalTier.regular;
    if (exchanges >= 3) return PenpalTier.budding;
    return PenpalTier.none;
  }

  /// Counts letters received from the given sender. AI, mock and system
  /// letters are excluded so those floors can't be juked by auto-seeded
  /// content.
  static PenpalStats forSender(String senderId, List<Letter> inbox) {
    if (senderId.isEmpty ||
        senderId.startsWith('ai_') ||
        senderId.startsWith('mock_') ||
        senderId == 'letter_go_welcome' ||
        senderId == 'system') {
      return const PenpalStats(exchanges: 0, tier: PenpalTier.none);
    }
    int n = 0;
    for (final l in inbox) {
      if (l.senderId == senderId) n++;
    }
    return PenpalStats(exchanges: n, tier: _tierFor(n));
  }
}

String penpalTierEmoji(PenpalTier tier) {
  switch (tier) {
    case PenpalTier.budding:
      return '🌱';
    case PenpalTier.regular:
      return '🕊️';
    case PenpalTier.longtime:
      return '📜';
    case PenpalTier.none:
      return '';
  }
}
