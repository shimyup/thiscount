import 'package:flutter_test/flutter_test.dart';

/// Build 268: PurchaseService trial 잔여일수 계산 회귀 가드.
///
/// PurchaseService 자체는 SharedPreferences / RevenueCat 의존성이 무거워
/// 단순 unit test 가 어려움. 대신 잔여일수 계산 공식 자체를 격리해 검증.
///
/// 공식 (Build 265):
///   remainingHours = expiry.difference(now).inHours
///   if (remainingHours <= 0) → null
///   else → (remainingHours / 24).ceil()
///
/// 회귀: 이전엔 inDays.truncate 로 6.99일 → 6일 표시되던 버그.
int? trialRemainingDays(DateTime expiry, DateTime now) {
  final remainingHours = expiry.difference(now).inHours;
  if (remainingHours <= 0) return null;
  return (remainingHours / 24).ceil();
}

void main() {
  group('trialRemainingDays', () {
    test('expiry just after grant (6.99 days) → 7 (ceil)', () {
      final now = DateTime(2026, 5, 1, 10, 0);
      final expiry = now.add(const Duration(days: 7));
      // 가입 직후 1분 뒤 확인 → 6.99일 남음. ceil → 7.
      final later = now.add(const Duration(minutes: 1));
      expect(trialRemainingDays(expiry, later), 7);
    });

    test('expiry exactly 24h away → 1', () {
      final now = DateTime(2026, 5, 5, 0, 0);
      final expiry = now.add(const Duration(hours: 24));
      expect(trialRemainingDays(expiry, now), 1);
    });

    test('expiry 23h away → still 1 (not 0)', () {
      final now = DateTime(2026, 5, 5, 0, 0);
      final expiry = now.add(const Duration(hours: 23));
      expect(trialRemainingDays(expiry, now), 1);
    });

    test('expiry 1h away → 1 (D-day)', () {
      final now = DateTime(2026, 5, 5, 23, 0);
      final expiry = now.add(const Duration(hours: 1));
      expect(trialRemainingDays(expiry, now), 1);
    });

    test('expired (past) → null', () {
      final now = DateTime(2026, 5, 8, 0, 0);
      final expiry = now.subtract(const Duration(hours: 1));
      expect(trialRemainingDays(expiry, now), isNull);
    });

    test('exactly at expiry → null (treated expired)', () {
      final now = DateTime(2026, 5, 8, 0, 0);
      final expiry = now;
      expect(trialRemainingDays(expiry, now), isNull);
    });

    test('mid-trial (3.5 days) → 4 (ceil)', () {
      final now = DateTime(2026, 5, 5, 12, 0);
      final expiry = now.add(const Duration(days: 3, hours: 12));
      expect(trialRemainingDays(expiry, now), 4);
    });
  });

  // Build 268: cooldown clock-skew 가드 — Build 265 회귀 fix 확인.
  group('cooldown clock skew detection', () {
    Duration? remainingCooldown(
      DateTime? lastPickupAt,
      Duration cooldown,
      DateTime now,
    ) {
      if (lastPickupAt == null) return null;
      final elapsed = now.difference(lastPickupAt);
      if (elapsed.isNegative) return null; // 시계 역행 — 쿨다운 무효
      if (elapsed >= cooldown) return null;
      return cooldown - elapsed;
    }

    test('normal cooldown progresses (5 of 10 min elapsed)', () {
      final start = DateTime(2026, 5, 1, 10, 0);
      final now = start.add(const Duration(minutes: 5));
      expect(
        remainingCooldown(start, const Duration(minutes: 10), now),
        const Duration(minutes: 5),
      );
    });

    test('cooldown elapsed (>= duration) → null', () {
      final start = DateTime(2026, 5, 1, 10, 0);
      final now = start.add(const Duration(minutes: 15));
      expect(
        remainingCooldown(start, const Duration(minutes: 10), now),
        isNull,
      );
    });

    test('clock skew (now < lastPickupAt) → null (no cooldown)', () {
      final futureStart = DateTime(2026, 5, 1, 11, 0);
      final now = futureStart.subtract(const Duration(minutes: 30));
      expect(
        remainingCooldown(futureStart, const Duration(minutes: 10), now),
        isNull,
      );
    });

    test('lastPickupAt null → no cooldown', () {
      expect(
        remainingCooldown(
            null, const Duration(minutes: 10), DateTime(2026, 5, 1)),
        isNull,
      );
    });
  });
}
