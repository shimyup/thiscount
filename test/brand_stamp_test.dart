import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/models/brand_stamp.dart';

void main() {
  group('BrandStampCard (Build 453 단골 스탬프)', () {
    test('JSON 라운드트립 — 모든 필드 보존', () {
      final card = BrandStampCard(
        brandId: 'brand_abc',
        brandName: '서울카페',
        stamps: 3,
        rewardThreshold: 5,
        completedCount: 2,
        lastStampAt: DateTime.fromMillisecondsSinceEpoch(1717000000000),
      );
      final restored = BrandStampCard.fromJson(card.toJson());
      expect(restored.brandId, 'brand_abc');
      expect(restored.brandName, '서울카페');
      expect(restored.stamps, 3);
      expect(restored.rewardThreshold, 5);
      expect(restored.completedCount, 2);
      expect(restored.lastStampAt?.millisecondsSinceEpoch, 1717000000000);
    });

    test('lastStampAt null 이면 toJson 에서 생략 + fromJson null 복원', () {
      final card = BrandStampCard(brandId: 'b', brandName: 'n');
      final json = card.toJson();
      expect(json.containsKey('lastStampAt'), false);
      expect(BrandStampCard.fromJson(json).lastStampAt, null);
    });

    test('corruption 방어 — 잘못된 타입/누락 필드에 기본값', () {
      final restored = BrandStampCard.fromJson({
        'brandId': 'b1',
        'stamps': 'corrupt',
        'rewardThreshold': 0, // 0 이하 → 기본 5 로 복구
        'completedCount': -3,
      });
      expect(restored.brandId, 'b1');
      expect(restored.brandName, '');
      expect(restored.stamps, 0);
      expect(restored.rewardThreshold, BrandStampCard.defaultThreshold);
      expect(restored.completedCount, 0);
    });

    test('isComplete — threshold 도달 시 true', () {
      final card = BrandStampCard(brandId: 'b', brandName: 'n', stamps: 4);
      expect(card.isComplete, false);
      card.stamps = 5;
      expect(card.isComplete, true);
    });

    // Build 491: 단골 티어 — 픽업 누적 3/5/10 경계.
    test('tierLevel — 픽업 누적 경계값', () {
      final card = BrandStampCard(brandId: 'b', brandName: 'n');
      expect(card.tierLevel, 0);
      expect(card.pickupsToNextTier, 3);
      card.pickupCount = 3;
      expect(card.tierLevel, 1); // 브론즈
      expect(card.pickupsToNextTier, 2);
      card.pickupCount = 5;
      expect(card.tierLevel, 2); // 실버
      expect(card.pickupsToNextTier, 5);
      card.pickupCount = 10;
      expect(card.tierLevel, 3); // 골드
      expect(card.pickupsToNextTier, 0);
    });

    test('pickupCount 직렬화 라운드트립 + legacy(키 없음) 0 복원', () {
      final card = BrandStampCard(
        brandId: 'b',
        brandName: 'n',
        pickupCount: 7,
      );
      final restored = BrandStampCard.fromJson(card.toJson());
      expect(restored.pickupCount, 7);
      expect(restored.tierLevel, 2);
      final legacy = BrandStampCard.fromJson({'brandId': 'b'});
      expect(legacy.pickupCount, 0);
      expect(legacy.tierLevel, 0);
    });
  });
}
