import 'dart:math' as math;

/// XP 및 레벨 계산 (Free · Premium 전용).
///
/// Brand 계정은 이 시스템에서 제외 — 호출 쪽(AppState)에서 `isBrand` 분기로
/// 게이팅한다. 여기 함수들은 순수 계산만 담당하므로 Brand 여부를 받지 않는다.
///
/// XP 원천 3가지 (사용자 지시):
///  1. 편지를 주운 횟수 (pickup count)
///  2. 편지를 보낸 횟수 (sent count)
///  3. 편지의 거리 (pickup km + sent km)
///
/// 희귀도·요일테마·스트릭 등 다른 가중치는 넣지 않는다. 단순함이 설계 목표.
class UserProgress {
  /// 누적 XP 를 3가지 원천으로 계산.
  static int calcXp({
    required int pickedCount,
    required int sentCount,
    required double sumPickupKm,
    required double sumSentKm,
  }) {
    final raw =
        (pickedCount * 10) +
        (sentCount * 5) +
        (sumPickupKm * 0.1) +
        (sumSentKm * 0.05);
    if (raw <= 0) return 0;
    return raw.floor();
  }

  /// XP → 레벨. 1 부터 시작, 50 에서 캡.
  ///
  /// 공식: level = 1 + floor(sqrt(xp / 50))
  /// - 0 XP → 1
  /// - 50 XP → 2
  /// - 1,250 → 5
  /// - 5,000 → 10
  /// - 125,000 → 50 (이후 cap)
  static int calcLevel(int xp) {
    if (xp <= 0) return 1;
    final raw = 1 + math.sqrt(xp / 50).floor();
    return raw.clamp(1, 50);
  }

  /// 다음 레벨 도달에 필요한 XP. 현재 레벨이 이미 50 이면 null.
  static int? xpToNextLevel(int currentXp) {
    final currentLevel = calcLevel(currentXp);
    if (currentLevel >= 50) return null;
    final threshold = xpThresholdForLevel(currentLevel + 1);
    return threshold - currentXp;
  }

  /// 특정 레벨 도달에 필요한 최소 XP. calcLevel 의 역함수.
  /// level 1 = 0 XP, level 2 = 50, level 5 = 1,250, level 50 = 120,050.
  static int xpThresholdForLevel(int level) {
    if (level <= 1) return 0;
    final clamped = level.clamp(1, 50);
    return (clamped - 1) * (clamped - 1) * 50;
  }

  /// 현재 레벨 내에서의 진척도 (0.0 ~ 1.0). UI 진행 바에 사용.
  static double levelProgress(int currentXp) {
    final level = calcLevel(currentXp);
    if (level >= 50) return 1.0;
    final curBase = xpThresholdForLevel(level);
    final nextBase = xpThresholdForLevel(level + 1);
    final span = nextBase - curBase;
    if (span <= 0) return 1.0;
    return ((currentXp - curBase) / span).clamp(0.0, 1.0);
  }
}

/// 레벨별 인 게임 명칭. 5 레벨마다 tier 가 진화.
/// UI 에서만 사용 — 로직 분기 금지.
/// Build 238: Thiscount 리브랜드 — 우편/편지 테마 → 혜택 헌트 테마.
const Map<int, String> _levelNameByFloor = {
  0: '🎟 새내기 탐험가',
  5: '🎫 초보 헌터',
  10: '🏷️ 숙련 헌터',
  15: '🛍 마을 쇼핑러',
  20: '🎯 도시 발견러',
  25: '💎 보물 발견러',
  30: '🏆 혜택 마스터',
  35: '⭐ 슈퍼 헌터',
  40: '🌍 글로벌 픽업 리더',
  45: '👑 전설의 혜택 헌터',
};

String xpLevelLabel(int level) {
  // 가장 가까운 하위 floor 찾기 (45 ≤ level ≤ 50 → "전설의 혜택 헌터")
  for (final floor in [45, 40, 35, 30, 25, 20, 15, 10, 5, 0]) {
    if (level >= floor) return _levelNameByFloor[floor]!;
  }
  return _levelNameByFloor[0]!;
}
