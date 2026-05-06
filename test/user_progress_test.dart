import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/features/progression/user_progress.dart';

void main() {
  group('UserProgress.calcXp', () {
    test('all-zero activity = 0 XP', () {
      expect(
        UserProgress.calcXp(
          pickedCount: 0,
          sentCount: 0,
          sumPickupKm: 0,
          sumSentKm: 0,
        ),
        0,
      );
    });

    test('picks contribute 10 XP each', () {
      expect(
        UserProgress.calcXp(
          pickedCount: 5,
          sentCount: 0,
          sumPickupKm: 0,
          sumSentKm: 0,
        ),
        50,
      );
    });

    test('sends contribute 5 XP each', () {
      expect(
        UserProgress.calcXp(
          pickedCount: 0,
          sentCount: 10,
          sumPickupKm: 0,
          sumSentKm: 0,
        ),
        50,
      );
    });

    test('pickup distance contributes 0.1 XP per km', () {
      expect(
        UserProgress.calcXp(
          pickedCount: 0,
          sentCount: 0,
          sumPickupKm: 10000,
          sumSentKm: 0,
        ),
        1000,
      );
    });

    test('sent distance contributes 0.05 XP per km', () {
      expect(
        UserProgress.calcXp(
          pickedCount: 0,
          sentCount: 0,
          sumPickupKm: 0,
          sumSentKm: 10000,
        ),
        500,
      );
    });

    test('combined example: 10 picks, 3 sends, 8000km pickup, 10000km sent', () {
      expect(
        UserProgress.calcXp(
          pickedCount: 10,
          sentCount: 3,
          sumPickupKm: 8000,
          sumSentKm: 10000,
        ),
        // 100 + 15 + 800 + 500 = 1415
        1415,
      );
    });
  });

  group('UserProgress.calcLevel', () {
    test('0 XP → level 1', () {
      expect(UserProgress.calcLevel(0), 1);
    });

    test('49 XP → level 1 (just below threshold)', () {
      expect(UserProgress.calcLevel(49), 1);
    });

    test('50 XP → level 2 (exact threshold)', () {
      expect(UserProgress.calcLevel(50), 2);
    });

    test('800 XP → level 5 (threshold = (5-1)^2 × 50)', () {
      expect(UserProgress.calcLevel(800), 5);
    });

    test('4,050 XP → level 10', () {
      expect(UserProgress.calcLevel(4050), 10);
    });

    test('120,050 XP → level 50 (threshold = 49^2 × 50)', () {
      expect(UserProgress.calcLevel(120050), 50);
    });

    test('500,000 XP → still 50 (hard cap)', () {
      expect(UserProgress.calcLevel(500000), 50);
    });

    test('negative XP (defensive) → level 1', () {
      expect(UserProgress.calcLevel(-10), 1);
    });
  });

  group('UserProgress.xpToNextLevel', () {
    test('level 50 returns null (capped)', () {
      expect(UserProgress.xpToNextLevel(125000), isNull);
    });

    test('at level 1 (0 XP) needs 50 XP to hit level 2', () {
      expect(UserProgress.xpToNextLevel(0), 50);
    });

    test('halfway into level 2 needs < 150 more XP to hit level 3', () {
      // level 3 threshold = 200. At XP 100 (level 2), remaining = 100.
      expect(UserProgress.xpToNextLevel(100), 100);
    });
  });

  group('UserProgress.levelProgress', () {
    test('at level 1 start → 0.0', () {
      expect(UserProgress.levelProgress(0), 0.0);
    });

    test('at level 50 cap → 1.0', () {
      expect(UserProgress.levelProgress(125000), 1.0);
    });

    test('level 2 half-way → about 0.5', () {
      // level 2 starts at 50, level 3 at 200. midpoint = 125 → progress ≈ 0.5
      final p = UserProgress.levelProgress(125);
      expect(p, closeTo(0.5, 0.01));
    });
  });

  group('xpLevelLabel', () {
    test('level 1 → 새내기 카운터', () {
      expect(xpLevelLabel(1), contains('새내기 카운터'));
    });

    test('level 10 → 숙련 헌터', () {
      expect(xpLevelLabel(10), contains('숙련 헌터'));
    });

    test('level 50 → 전설의 카운터', () {
      expect(xpLevelLabel(50), contains('전설의 카운터'));
    });

    test('level 44 → 세계의 카운터장 (floor 40 bucket)', () {
      expect(xpLevelLabel(44), contains('세계의 카운터장'));
    });
  });
}
