// Build 252: 사용자 ID 기반 stable 인물 이모지 매핑.
// 지도 마커 / 인박스 카드 / 인포 시트 등 모든 화면에서 동일 사용자 = 동일 이모지.
// landmark 티어(최고)는 항상 👑.
//
// 사용 예:
//   final emoji = personEmojiForId(letter.senderId);
//   final emoji = personEmojiForId(mapUser.id, isLandmark: true);

const List<String> _personEmojis = [
  '🧑', '👨', '👩', '🧒', '🧓',
  '🧑‍🦱', '👨‍🦰', '👩‍🦱', '🧑‍🦳', '👨‍🦲',
  '🧑‍🎓', '🧑‍💼', '🧑‍🚀', '🧑‍🎨', '🧑‍🍳',
  '🥷', '🧙', '🦸', '🧝', '🤴',
];

/// 사용자/발신자 ID 해시 기반으로 인물 이모지 1종 반환. 같은 ID 는 항상 같은
/// 이모지 → 사용자 식별 시각 일관성.
/// [isLandmark] true 면 풀 무시하고 👑 (최고 티어) 반환.
String personEmojiForId(String id, {bool isLandmark = false}) {
  if (isLandmark) return '👑';
  if (id.isEmpty) return _personEmojis[0];
  final idx = id.hashCode.abs() % _personEmojis.length;
  return _personEmojis[idx];
}
