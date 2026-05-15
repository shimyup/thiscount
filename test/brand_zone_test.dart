// Build 283 Phase 1 MVP: BrandZone + BrandZoneService 단위 테스트.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thiscount/core/services/brand_zone_service.dart';
import 'package:thiscount/models/brand_zone.dart';
import 'package:thiscount/models/letter.dart' show LatLng;

BrandZone _zone({
  String id = 'z1',
  String brandId = 'b1',
  LatLng? center,
  double radiusM = 200,
  DateTime? startsAt,
  DateTime? expiresAt,
  int maxRedeems = 0,
  int redeemedCount = 0,
}) {
  final now = DateTime(2026, 5, 14, 12);
  return BrandZone(
    id: id,
    brandId: brandId,
    brandName: 'Starbucks 강남역점',
    center: center ?? const LatLng(37.4979, 127.0276),
    radiusM: radiusM,
    content: '20% OFF 음료 1잔',
    redemptionInfo: 'STARBUCKS20',
    startsAt: startsAt ?? now.subtract(const Duration(hours: 1)),
    expiresAt: expiresAt ?? now.add(const Duration(days: 7)),
    maxRedeems: maxRedeems,
    redeemedCount: redeemedCount,
    createdAt: now.subtract(const Duration(hours: 2)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BrandZone.isActive', () {
    final now = DateTime(2026, 5, 14, 12);

    test('startsAt 이전 → false', () {
      final z = _zone(startsAt: now.add(const Duration(hours: 1)));
      expect(z.isActive(now), isFalse);
    });

    test('expiresAt 이후 → false', () {
      final z = _zone(expiresAt: now.subtract(const Duration(minutes: 1)));
      expect(z.isActive(now), isFalse);
    });

    test('수량 무제한 (maxRedeems=0) → 활성', () {
      final z = _zone(maxRedeems: 0, redeemedCount: 99999);
      expect(z.isActive(now), isTrue);
    });

    test('수량 초과 → false', () {
      final z = _zone(maxRedeems: 100, redeemedCount: 100);
      expect(z.isActive(now), isFalse);
    });

    test('정상 활성 — 시간 + 수량 모두 통과', () {
      final z = _zone(maxRedeems: 100, redeemedCount: 50);
      expect(z.isActive(now), isTrue);
    });
  });

  group('BrandZone.containsPosition (haversine)', () {
    final center = const LatLng(37.4979, 127.0276); // 강남역
    final z = _zone(center: center, radiusM: 200);

    test('정확히 중심 → 0m, 안에 있음', () {
      expect(z.containsPosition(center), isTrue);
    });

    test('100m 떨어진 위치 → radius 200m 안', () {
      // 위도 +0.0009° ≈ 100m
      final user = LatLng(center.latitude + 0.0009, center.longitude);
      expect(z.containsPosition(user), isTrue);
    });

    test('500m 떨어진 위치 → radius 200m 밖', () {
      // 위도 +0.0045° ≈ 500m
      final user = LatLng(center.latitude + 0.0045, center.longitude);
      expect(z.containsPosition(user), isFalse);
    });

    test('200m 경계 보장 — 199m 안 / 201m 밖', () {
      final inside = LatLng(center.latitude + 0.00179, center.longitude); // ~199m
      final outside = LatLng(center.latitude + 0.00181, center.longitude); // ~201m
      expect(z.containsPosition(inside), isTrue);
      expect(z.containsPosition(outside), isFalse);
    });
  });

  group('BrandZone.toJson / fromJson round-trip', () {
    test('필수 필드 + redemptionInfo 보존', () {
      final z = _zone(redeemedCount: 42);
      final restored = BrandZone.fromJson(z.toJson());
      expect(restored.id, z.id);
      expect(restored.brandId, z.brandId);
      expect(restored.brandName, z.brandName);
      expect(restored.center.latitude, closeTo(z.center.latitude, 1e-9));
      expect(restored.center.longitude, closeTo(z.center.longitude, 1e-9));
      expect(restored.radiusM, z.radiusM);
      expect(restored.content, z.content);
      expect(restored.redemptionInfo, z.redemptionInfo);
      expect(restored.maxRedeems, z.maxRedeems);
      expect(restored.redeemedCount, 42);
    });

    test('redemptionInfo null 시 키 누락 → 복원 OK', () {
      final z = BrandZone(
        id: 'z',
        brandId: 'b',
        brandName: 'X',
        center: const LatLng(0, 0),
        radiusM: 100,
        content: 'c',
        startsAt: DateTime.utc(2026, 5, 14),
        expiresAt: DateTime.utc(2026, 5, 21),
        createdAt: DateTime.utc(2026, 5, 14),
      );
      final j = z.toJson();
      expect(j.containsKey('redemptionInfo'), isFalse);
      final restored = BrandZone.fromJson(j);
      expect(restored.redemptionInfo, isNull);
    });
  });

  group('BrandZoneService.randomOffset', () {
    final origin = const LatLng(37.4979, 127.0276);

    test('항상 maxMeters 이내 — 1000 회 샘플 검증', () {
      final rng = math.Random(42);
      for (var i = 0; i < 1000; i++) {
        final p = BrandZoneService.randomOffset(
          origin,
          maxMeters: 30,
          rng: rng,
        );
        final d = origin.distanceTo(p);
        expect(d, lessThanOrEqualTo(30.0 + 1e-6));
      }
    });

    test('0m 보다 큼 (origin 동일 X — 평균 ~15m 부근)', () {
      final rng = math.Random(123);
      final samples = List.generate(
          200,
          (_) => origin.distanceTo(BrandZoneService.randomOffset(
                origin,
                maxMeters: 30,
                rng: rng,
              )));
      final avg = samples.reduce((a, b) => a + b) / samples.length;
      // uniform 0..30 의 평균 = 15. 200 샘플이면 ±3 이내 수렴 기대.
      expect(avg, greaterThan(10));
      expect(avg, lessThan(20));
    });
  });

  group('BrandZoneService dedup + candidatesNear', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      BrandZoneService.instance.clearCacheForTest();
    });

    test('candidatesNear — 활성 + 반경 + 시간 필터링', () {
      final svc = BrandZoneService.instance;
      final origin = const LatLng(37.4979, 127.0276);
      final now = DateTime(2026, 5, 14, 12);

      svc.injectCacheForTest([
        _zone(id: 'in', center: origin, radiusM: 200), // 안에 있음
        _zone(
          id: 'far',
          center: LatLng(origin.latitude + 0.01, origin.longitude),
          radiusM: 200,
        ), // 1.1km 밖
        _zone(
          id: 'expired',
          center: origin,
          radiusM: 200,
          expiresAt: now.subtract(const Duration(hours: 1)),
        ),
        _zone(
          id: 'full',
          center: origin,
          radiusM: 200,
          maxRedeems: 10,
          redeemedCount: 10,
        ),
      ]);

      final picks = svc.candidatesNear(origin, now: now);
      expect(picks.map((z) => z.id).toList(), ['in']);
    });

    test('triggerForUser — 이미 본 zone 은 skip', () async {
      final svc = BrandZoneService.instance;
      final origin = const LatLng(37.4979, 127.0276);
      final now = DateTime(2026, 5, 14, 12);

      svc.injectCacheForTest([
        _zone(id: 'z-new', center: origin),
        _zone(id: 'z-seen', center: origin),
      ]);

      // 미리 z-seen 본 적 있다고 마킹
      SharedPreferences.setMockInitialValues({
        'brand_zones_seen_user1': ['z-seen'],
      });

      final triggered = <String>[];
      final picked = await svc.triggerForUser(
        userId: 'user1',
        userPos: origin,
        onZoneEnter: (z, dest) async => triggered.add(z.id),
        now: now,
        rng: math.Random(1),
      );

      expect(picked.length, 1);
      expect(picked.first.id, 'z-new');
      expect(triggered, ['z-new']);

      // 한번 더 호출 → 둘 다 seen 이므로 아무것도 안 트리거
      final picked2 = await svc.triggerForUser(
        userId: 'user1',
        userPos: origin,
        onZoneEnter: (z, dest) async => triggered.add(z.id),
        now: now,
        rng: math.Random(1),
      );
      expect(picked2, isEmpty);
      expect(triggered, ['z-new']);
    });

    test('triggerForUser — destination 이 userPos 의 ~30m 이내', () async {
      final svc = BrandZoneService.instance;
      final origin = const LatLng(37.4979, 127.0276);
      svc.injectCacheForTest([_zone(id: 'z1', center: origin, radiusM: 500)]);

      LatLng? captured;
      await svc.triggerForUser(
        userId: 'u',
        userPos: origin,
        onZoneEnter: (z, dest) async {
          captured = dest;
        },
        now: DateTime(2026, 5, 14, 12),
        rng: math.Random(777),
      );

      expect(captured, isNotNull);
      final d = origin.distanceTo(captured!);
      expect(d, lessThanOrEqualTo(30.0 + 1e-6));
      // origin 과 정확히 같은 점이 아닐 가능성 높음
      expect(d, greaterThan(0));
    });

    test('triggerForUser — 빈 userId → no-op', () async {
      final svc = BrandZoneService.instance;
      svc.injectCacheForTest([_zone(center: const LatLng(0, 0))]);
      final r = await svc.triggerForUser(
        userId: '',
        userPos: const LatLng(0, 0),
        onZoneEnter: (z, dest) async {},
      );
      expect(r, isEmpty);
    });
  });

  group('Letter.brandZoneId — 직렬화 보존', () {
    test('clone + toJson + fromJson round-trip', () {
      // Letter 생성에 필요한 모든 필드를 채워 round-trip 검증.
      // (직접 import 없이 letter_model_test.dart 의 패턴과 동일.)
      // 본 테스트는 brandZoneId 만 검증하므로 별도 테스트 파일 letter_model_test
      // 가 cover. 여기선 placeholder 로 두고 skip.
    }, skip: 'covered by letter_model_test.dart Letter round-trip + 새 필드 manual 검증');
  });
}
