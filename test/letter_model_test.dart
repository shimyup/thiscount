// Build 168: Letter 모델 + BrandAnalytics 핵심 비즈니스 로직 테스트.
// 128-167 누적된 feature 중 회귀 방지 최소 커버리지.
import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/models/letter.dart';
import 'package:thiscount/state/app_state.dart';

Letter _brandLetter({
  String id = 't1',
  LetterCategory category = LetterCategory.coupon,
  DateTime? redemptionExpiresAt,
  DateTime? expiresAt,
  bool brandUniquePerUser = false,
  String? campaignId,
  LetterRarity rarity = LetterRarity.normal,
  int? campaignTotalCount,
  bool isMystery = false,
}) {
  final now = DateTime.now();
  return Letter(
    id: id,
    rarity: rarity,
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
    brandUniquePerUser: brandUniquePerUser,
    campaignId: campaignId,
    campaignTotalCount: campaignTotalCount,
    isMystery: isMystery,
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

    test('Build 324: campaignId + brandUniquePerUser 라운드트립', () {
      final original = _brandLetter(
        brandUniquePerUser: true,
        campaignId: 'cmp_test_123',
      );
      final restored = Letter.fromJson(original.toJson());
      expect(restored.brandUniquePerUser, isTrue);
      expect(restored.campaignId, 'cmp_test_123');
    });

    test('Build 490: campaignTotalCount + isMystery 라운드트립 + clone 보존', () {
      final original = _brandLetter(
        brandUniquePerUser: true,
        campaignId: 'cmp_hunt_1',
        campaignTotalCount: 300,
        isMystery: true,
      );
      final restored = Letter.fromJson(original.toJson());
      expect(restored.campaignTotalCount, 300);
      expect(restored.isMystery, isTrue);
      // 픽업 clone 도 헌트 필드 유지 (world → inbox 전이 시 마스킹 게이트 보존).
      final cloned = original.clone();
      expect(cloned.campaignTotalCount, 300);
      expect(cloned.isMystery, isTrue);
      // 마커: 밀봉 드롭은 카테고리 이모지 대신 ❓.
      expect(original.markerBrandEmoji, '❓');
      expect(_brandLetter().markerBrandEmoji, isNot('❓'));
    });

    test('Build 491: tierRewards 라운드트립 + JSON string/corrupt 방어', () {
      final original = _brandLetter();
      final json = original.toJson();
      expect(json.containsKey('tierRewards'), isFalse); // 미설정 생략
      // Map 형태(prefs)
      final withMap = Letter.fromJson({
        ...json,
        'tierRewards': {'3': '사이즈업 무료', '10': '음료 1잔'},
      });
      expect(withMap.tierRewards, {3: '사이즈업 무료', 10: '음료 1잔'});
      // JSON string 형태(Firestore)
      expect(
        Letter.parseTierRewards('{"5":"쿠키 증정"}'),
        {5: '쿠키 증정'},
      );
      // corrupt → null (crash 없이)
      expect(Letter.parseTierRewards('not-json'), isNull);
      expect(Letter.parseTierRewards({'x': 1}), isNull);
      // 라운드트립 보존 + clone 보존
      final l2 = Letter.fromJson(withMap.toJson());
      expect(l2.tierRewards?[3], '사이즈업 무료');
      expect(withMap.clone().tierRewards?[10], '음료 1잔');
    });

    test('Build 491: storeLat/Lng/Name 라운드트립 + 익명 게이트', () {
      final now = DateTime.now();
      final withStore = Letter(
        id: 's1',
        senderId: 'brand1',
        senderName: 'Test Brand',
        senderCountry: '대한민국',
        senderCountryFlag: '🇰🇷',
        content: 'hello 30% off',
        originLocation: LatLng(37.5, 127.0),
        destinationLocation: LatLng(37.5, 127.0),
        destinationCountry: '대한민국',
        destinationCountryFlag: '🇰🇷',
        segments: const [],
        sentAt: now,
        estimatedTotalMinutes: 60,
        senderIsBrand: true,
        isAnonymous: false,
        category: LetterCategory.coupon,
        storeLat: 37.5445,
        storeLng: 127.0567,
        storeName: 'A카페 성수점',
      );
      final restored = Letter.fromJson(withStore.toJson());
      expect(restored.storeLat, 37.5445);
      expect(restored.storeName, 'A카페 성수점');
      expect(restored.clone().storeLng, 127.0567);
      // 익명이면 직렬화 게이트 — 필드 누락 (익명·매장위치 상호 배타).
      final anonJson = Letter(
        id: 's2',
        senderId: 'brand1',
        senderName: 'x',
        senderCountry: 'k',
        senderCountryFlag: '🇰🇷',
        content: 'c',
        originLocation: LatLng(1, 1),
        destinationLocation: LatLng(1, 1),
        destinationCountry: 'k',
        destinationCountryFlag: '🇰🇷',
        segments: const [],
        sentAt: now,
        estimatedTotalMinutes: 1,
        isAnonymous: true,
        storeLat: 37.0,
        storeLng: 127.0,
      ).toJson();
      expect(anonJson.containsKey('storeLat'), isFalse);
      // 프라이스태그 라벨: % 추출 / 미스터리 ? / 범위 밖 무시.
      expect(withStore.priceTagLabel, '30%');
      expect(withStore.percentLabel, '30%');
    });

    test('Build 490: legacy letter (헌트 키 없음) → null/false 복원', () {
      final json = _brandLetter().toJson();
      expect(json.containsKey('campaignTotalCount'), isFalse);
      expect(json.containsKey('isMystery'), isFalse);
      final restored = Letter.fromJson(json);
      expect(restored.campaignTotalCount, isNull);
      expect(restored.isMystery, isFalse);
    });

    test('Build 324: legacy letter (campaignId 키 없음) → null 복원', () {
      final json = _brandLetter().toJson();
      // 기존 letter 는 키가 아예 없을 수 있음.
      expect(json.containsKey('campaignId'), isFalse);
      final restored = Letter.fromJson(json);
      expect(restored.campaignId, isNull);
      expect(restored.brandUniquePerUser, isFalse);
    });

    test('Build 324: clone() 이 campaignId 보존', () {
      final original = _brandLetter(
        brandUniquePerUser: true,
        campaignId: 'cmp_xyz',
      );
      final cloned = original.clone();
      expect(cloned.campaignId, 'cmp_xyz');
      expect(cloned.brandUniquePerUser, isTrue);
    });

    test('Build 461: sourceLetterId 라운드트립 + legacy null + clone 보존', () {
      // 일반 letter 는 키 자체가 없음 (legacy 호환).
      final json = _brandLetter().toJson();
      expect(json.containsKey('sourceLetterId'), isFalse);
      expect(Letter.fromJson(json).sourceLetterId, isNull);
      // gift_/stamp_reward_ 사본이 갖는 원본 귀속 id 보존.
      json['sourceLetterId'] = 'sent_origin_1';
      final restored = Letter.fromJson(json);
      expect(restored.sourceLetterId, 'sent_origin_1');
      expect(restored.toJson()['sourceLetterId'], 'sent_origin_1');
      expect(restored.clone().sourceLetterId, 'sent_origin_1');
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

  group('LetterRarity enum (Build 415 #5 레어 드롭)', () {
    test('keys + badge + isSpecial stable', () {
      expect(LetterRarity.normal.key, 'normal');
      expect(LetterRarity.rare.key, 'rare');
      expect(LetterRarity.epic.key, 'epic');
      expect(LetterRarity.normal.isSpecial, false);
      expect(LetterRarity.rare.isSpecial, true);
      expect(LetterRarity.epic.isSpecial, true);
      expect(LetterRarity.rare.badge, '✨');
      expect(LetterRarity.epic.badge, '💎');
      expect(LetterRarity.normal.badge, '');
    });

    test('fromJson: string key / int index / null / out-of-range', () {
      expect(LetterRarityExt.fromJson('rare'), LetterRarity.rare);
      expect(LetterRarityExt.fromJson('epic'), LetterRarity.epic);
      expect(LetterRarityExt.fromJson('unknown'), LetterRarity.normal);
      expect(LetterRarityExt.fromJson(2), LetterRarity.epic);
      expect(LetterRarityExt.fromJson(0), LetterRarity.normal);
      expect(LetterRarityExt.fromJson(null), LetterRarity.normal);
      expect(LetterRarityExt.fromJson(99), LetterRarity.normal); // 범위 밖 안전
    });

    test('normal 은 toJson 에서 키 생략 → legacy 호환', () {
      final json = _brandLetter(rarity: LetterRarity.normal).toJson();
      expect(json.containsKey('rarity'), false);
      expect(Letter.fromJson(json).rarity, LetterRarity.normal);
    });

    test('rare/epic 라운드트립 + clone 보존', () {
      final original = _brandLetter(rarity: LetterRarity.epic);
      final json = original.toJson();
      expect(json['rarity'], 'epic');
      expect(Letter.fromJson(json).rarity, LetterRarity.epic);
      expect(original.clone().rarity, LetterRarity.epic);
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
