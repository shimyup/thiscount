// Build 168: Letter 모델 + BrandAnalytics 핵심 비즈니스 로직 테스트.
// 128-167 누적된 feature 중 회귀 방지 최소 커버리지.
import 'package:flutter_test/flutter_test.dart';
import 'package:letter_go/models/letter.dart';
import 'package:letter_go/state/app_state.dart';

Letter _brandLetter({
  String id = 't1',
  LetterCategory category = LetterCategory.coupon,
  DateTime? redemptionExpiresAt,
  DateTime? expiresAt,
}) {
  final now = DateTime.now();
  return Letter(
    id: id,
    senderId: 'brand1',
    senderName: 'Test Brand',
    senderCountry: '대한민국',
    senderCountryFlag: '🇰🇷',
    content: 'hello',
    originLocation: LatLng(37.5665, 126.978),
    destinationLocation: LatLng(37.5665, 126.978),
    destinationCountry: '대한민국',
    destinationCountryFlag: '🇰🇷',
    segments: const [],
    sentAt: now,
    estimatedTotalMinutes: 60,
    senderIsBrand: true,
    senderTier: LetterSenderTier.brand,
    category: category,
    redemptionInfo: 'CODE123',
    redemptionExpiresAt: redemptionExpiresAt,
    expiresAt: expiresAt,
    acceptsReplies: false,
  );
}

void main() {
  group('Letter.isRedemptionExpired (Build 132)', () {
    test('null redemptionExpiresAt → false', () {
      final l = _brandLetter(redemptionExpiresAt: null);
      expect(l.isRedemptionExpired, isFalse);
    });

    test('future redemptionExpiresAt → false', () {
      final future = DateTime.now().add(const Duration(days: 3));
      final l = _brandLetter(redemptionExpiresAt: future);
      expect(l.isRedemptionExpired, isFalse);
    });

    test('past redemptionExpiresAt → true', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final l = _brandLetter(redemptionExpiresAt: past);
      expect(l.isRedemptionExpired, isTrue);
    });
  });

  group('Letter.isExpired vs isRedemptionExpired', () {
    test('expiresAt (편지 자동 삭제) 과 redemptionExpiresAt (쿠폰 유효) 은 독립', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final future = DateTime.now().add(const Duration(days: 7));
      final l = _brandLetter(expiresAt: past, redemptionExpiresAt: future);
      expect(l.isExpired, isTrue);
      expect(l.isRedemptionExpired, isFalse);
    });
  });

  group('Letter.toJson / fromJson round-trip (Build 135)', () {
    test('category + redemptionExpiresAt 필드 보존', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final original = _brandLetter(
        category: LetterCategory.voucher,
        redemptionExpiresAt: future,
      );
      final json = original.toJson();
      final restored = Letter.fromJson(json);
      expect(restored.category, LetterCategory.voucher);
      expect(
        restored.redemptionExpiresAt!.millisecondsSinceEpoch,
        future.millisecondsSinceEpoch,
      );
      expect(restored.redemptionInfo, 'CODE123');
      expect(restored.senderIsBrand, isTrue);
    });

    test('redemptionInfo null 시 키 누락 해도 복원 OK', () {
      final json = _brandLetter().toJson();
      json.remove('redemptionInfo');
      final restored = Letter.fromJson(json);
      expect(restored.redemptionInfo, isNull);
    });
  });

  group('LetterCategory enum', () {
    test('keys stable (general/coupon/voucher)', () {
      expect(LetterCategory.general.key, 'general');
      expect(LetterCategory.coupon.key, 'coupon');
      expect(LetterCategory.voucher.key, 'voucher');
    });

    test('fromKey 는 missing 에 general fallback', () {
      expect(LetterCategoryExt.fromKey(null), LetterCategory.general);
      expect(LetterCategoryExt.fromKey('unknown'), LetterCategory.general);
      expect(LetterCategoryExt.fromKey('coupon'), LetterCategory.coupon);
      expect(LetterCategoryExt.fromKey('voucher'), LetterCategory.voucher);
    });
  });

  group('BrandAnalytics derived metrics (Build 138)', () {
    test('pickupReach = picked / sent, empty sent 시 0', () {
      const a = BrandAnalytics(
        totalSent: 100,
        totalPicked: 37,
        totalRedeemed: 12,
        couponSent: 60,
        voucherSent: 40,
        countryPicks: {},
      );
      expect(a.pickupReach, closeTo(0.37, 0.001));

      const b = BrandAnalytics(
        totalSent: 0,
        totalPicked: 0,
        totalRedeemed: 0,
        couponSent: 0,
        voucherSent: 0,
        countryPicks: {},
      );
      expect(b.pickupReach, 0);
    });

    test('redeemConversion = redeemed / picked, empty picked 시 0', () {
      const a = BrandAnalytics(
        totalSent: 100,
        totalPicked: 50,
        totalRedeemed: 10,
        couponSent: 0,
        voucherSent: 0,
        countryPicks: {},
      );
      expect(a.redeemConversion, closeTo(0.2, 0.001));

      const b = BrandAnalytics(
        totalSent: 100,
        totalPicked: 0,
        totalRedeemed: 0,
        couponSent: 0,
        voucherSent: 0,
        countryPicks: {},
      );
      expect(b.redeemConversion, 0);
    });
  });

  group('LatLng.distanceTo Haversine', () {
    test('same point → 0m', () {
      const p = LatLng(37.5665, 126.978);
      expect(p.distanceTo(p), lessThan(1));
    });

    test('Seoul to Busan ~325km', () {
      const seoul = LatLng(37.5665, 126.978);
      const busan = LatLng(35.1796, 129.0756);
      final meters = seoul.distanceTo(busan);
      expect(meters, greaterThan(320_000));
      expect(meters, lessThan(340_000));
    });

    test('100m offset 정확히', () {
      const base = LatLng(37.0, 127.0);
      // 0.0009 degrees ≈ 100m 북쪽
      const offset = LatLng(37.0009, 127.0);
      final d = base.distanceTo(offset);
      expect(d, greaterThan(90));
      expect(d, lessThan(110));
    });
  });
}
